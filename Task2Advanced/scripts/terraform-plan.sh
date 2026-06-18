#!/usr/bin/env bash
set -euo pipefail

# Runs terraform plan for the selected environment.
# Expects init to be completed and secrets to be provided via TF_VAR_* or var-files.

TF_ENV_DIR="${1:-.}"
shift || true

PLAN_FILE="${PLAN_FILE:-plan.tfplan}"
VAR_FILE_ARGS=()

if [[ -f "${TF_ENV_DIR}/terraform.tfvars" ]]; then
  VAR_FILE_ARGS+=(-var-file="${TF_ENV_DIR}/terraform.tfvars")
fi

terraform -chdir="${TF_ENV_DIR}" plan \
  "${VAR_FILE_ARGS[@]}" \
  -out="${PLAN_FILE}" \
  "$@"
