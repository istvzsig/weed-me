#!/bin/bash
set -euo pipefail

# Always resolve project root from THIS file
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Respect parent LOGS_DIR if exported, otherwise default
LOGS_DIR="${LOGS_DIR:-"$PROJECT_DIR/logs"}"

# Absolute safety check
if [[ -z "$LOGS_DIR" ]]; then
  echo "[ERROR] LOGS_DIR is empty" >&2
  exit 1
fi

mkdir -p "$LOGS_DIR"

LOG_FILE="$LOGS_DIR/compile_$(date +'%Y%m%d_%H%M%S').log"

echo "[HARDHAT] Compiling smart contracts... Logs -> $LOG_FILE"
npx --prefix "$PROJECT_DIR" hardhat compile 2>&1 | tee "$LOG_FILE"
