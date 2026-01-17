#!/bin/bash
set -e

# Required env vars (fail fast if missing)
LOG_FILE="$PROJECT_DIR/logs/copy_abi_$TIMESTAMP.log"

# Log function
log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Preparing to copy ABI files to frontend directory..."
mkdir -p "$ABI_DIR"

CONTRACTS_DIR="$ARTIFACTS_DIR/contracts"

if [ -d "$CONTRACTS_DIR" ]; then
    ABI_FILES=$(find "$CONTRACTS_DIR" -type f -name "*.json")

    if [ -n "$ABI_FILES" ]; then
        log "Copying ABI files from $CONTRACTS_DIR to $ABI_DIR"

        find "$CONTRACTS_DIR" -type f -name "*.json" -exec cp {} "$ABI_DIR" \;

        log "ABI files copied successfully."
    else
        log "Warning: No ABI files found in $CONTRACTS_DIR"
    fi
else
    log "Warning: Contracts directory does not exist: $CONTRACTS_DIR"
fi
