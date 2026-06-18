#!/usr/bin/env bash
set -euo pipefail

TF_ENV_DIR="${1:-.}"
PLAN_FILE="${2:-plan.tfplan}"

if [[ ! -f "${TF_ENV_DIR}/${PLAN_FILE}" ]]; then
  echo "Plan file not found: ${TF_ENV_DIR}/${PLAN_FILE}" >&2
  exit 1
fi

terraform -chdir="${TF_ENV_DIR}" apply -input=false "${PLAN_FILE}"
