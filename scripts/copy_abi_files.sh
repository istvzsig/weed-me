#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# LOGS_DIR="${LOGS_DIR:-"$PROJECT_DIR/logs"}"
ENV_FILE="${ENV_FILE:-"$PROJECT_DIR/.env"}"
DEPLOY_LOG_FILE="${DEPLOY_LOG_FILE:-"$LOGS_DIR/deploy.log"}"

mkdir -p "$LOGS_DIR"

# Ensure .env exists (macOS touch requires a filename)
touch "$ENV_FILE"

if [[ ! -f "$DEPLOY_LOG_FILE" ]]; then
  echo "[ERROR] Deploy log file not found: $DEPLOY_LOG_FILE" >&2
  exit 1
fi

# Example: extract deployed contract address (adjust regex to your deploy output)
# This is just a safe placeholder; change the pattern to match your deploy.ts output.
CONTRACT_ADDRESS="$(grep -Eo '0x[a-fA-F0-9]{40}' "$DEPLOY_LOG_FILE" | head -n 1 || true)"

if [[ -z "$CONTRACT_ADDRESS" ]]; then
  echo "[ERROR] Could not find a contract address in: $DEPLOY_LOG_FILE" >&2
  echo "       Update dotenv_setup.sh to match your deploy output format." >&2
  exit 1
fi

# Upsert helper: KEY=VALUE in .env
upsert_env() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    # macOS sed needs -i '' (empty backup extension)
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

upsert_env "CONTRACT_ADDRESS" "$CONTRACT_ADDRESS"

echo "[SYSTEM] Wrote CONTRACT_ADDRESS to $ENV_FILE"
