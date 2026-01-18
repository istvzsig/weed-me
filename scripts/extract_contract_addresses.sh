#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/setup.sh"

cd "$PROJECT_DIR"

if [[ ! -f "$DEPLOY_LOG_FILE" ]]; then
  echo "[ERROR] Deploy log file not found: $DEPLOY_LOG_FILE" >&2
  exit 1
fi

function extract_address() {
    local out="$1"
    local prefix="$2"
    echo "$out" | grep -oE "${prefix}: 0x[a-fA-F0-9]{40}" | awk '{print $2}' || return 1
}

# Read the contents of the deploy log file
log_contents=$(cat "$DEPLOY_LOG_FILE")

# Extract addresses using the contents of the log file
addresses=(
  "$(extract_address "$log_contents" "WeedToken")"
  "$(extract_address "$log_contents" "SeedNFT")"
  "$(extract_address "$log_contents" "PlantNFT")"
  "$(extract_address "$log_contents" "FarmGame")"
)

# Verify that addresses were extracted correctly
for i in "${!addresses[@]}"; do
  if [[ -z "${addresses[$i]}" ]]; then
    case $i in
      0) log "ERROR" "WeedToken address not found." ;;
      1) log "ERROR" "SeedNFT address not found." ;;
      2) log "ERROR" "PlantNFT address not found." ;;
      3) log "ERROR" "FarmGame address not found." ;;
    esac
  fi
done

# Output the addresses so they can be captured by the calling script
for address in "${addresses[@]}"; do
  echo "$address"
done

