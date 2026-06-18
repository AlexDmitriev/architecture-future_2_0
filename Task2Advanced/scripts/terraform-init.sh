#!/usr/bin/env bash
set -euo pipefail

: "${TF_BACKEND_BUCKET:?TF_BACKEND_BUCKET is required}"
: "${TF_BACKEND_KEY:?TF_BACKEND_KEY is required}"
: "${TF_BACKEND_REGION:?TF_BACKEND_REGION is required}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"

TF_ENV_DIR="${1:-.}"
BACKEND_CONFIG_FILE="$(mktemp)"

cleanup() {
  rm -f "${BACKEND_CONFIG_FILE}"
}
trap cleanup EXIT

cat > "${BACKEND_CONFIG_FILE}" <<EOF
bucket = "${TF_BACKEND_BUCKET}"
key    = "${TF_BACKEND_KEY}"
region = "${TF_BACKEND_REGION}"
EOF

if [[ -n "${TF_BACKEND_ENDPOINT:-}" ]]; then
  cat >> "${BACKEND_CONFIG_FILE}" <<EOF
endpoint                    = "${TF_BACKEND_ENDPOINT}"
skip_region_validation      = true
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
EOF

  if [[ "${TF_BACKEND_USE_PATH_STYLE:-false}" == "true" ]]; then
    echo 'use_path_style = true' >> "${BACKEND_CONFIG_FILE}"
  fi
fi

terraform -chdir="${TF_ENV_DIR}" init \
  -backend-config="${BACKEND_CONFIG_FILE}" \
  -reconfigure \
  "$@"
