#!/bin/bash
set -e

# Required env vars (fail fast if missing)
LOG_FILE="$PROJECT_DIR/logs/copy_abi_$TIMESTAMP.log"

function log() {
    local level=$1
    local message=$2
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] - $message" | tee -a "$LOG_FILE"
}

log SYSTEM "Preparing to copy ABI files to frontend directory..."
mkdir -p "$ABI_DIR"

CONTRACTS_DIR="$ARTIFACTS_DIR/contracts"

if [ -d "$CONTRACTS_DIR" ]; then
    ABI_FILES=$(find "$CONTRACTS_DIR" -type f -name "*.json")
    if [ -n "$ABI_FILES" ]; then
        log SYSTEM "Copying ABI files from $CONTRACTS_DIR to $ABI_DIR"

        find "$CONTRACTS_DIR" -type f -name "*.json" -exec cp {} "$ABI_DIR" \;

        log SYSTEM "ABI files copied successfully."
    else
        log ERROR "No ABI files found in $CONTRACTS_DIR"
        exit 1
    fi
else
    log ERROR "Contracts directory does not exist: $CONTRACTS_DIR"
    exit 1
fi
