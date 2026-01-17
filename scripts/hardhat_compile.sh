#!/bin/bash
set -e

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
export COMPILE_LOG_FILE="$PROJECT_DIR/logs/compile_$TIMESTAMP.log"

# Log function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$COMPILE_LOG_FILE"
}

log "[HARDHAT] Starting hardhat compilation script..."

# Delete artifacts and cache
if [[ -d $ARTIFACTS_DIR ]]; then
    log "[SYSTEM] Deleting existing artifacts directory."
    rm -rf "$ARTIFACTS_DIR"
fi

if [[ -d $CACHE_DIR ]]; then
    log "[SYSTEM] Deleting existing cache directory."
    rm -rf "$CACHE_DIR"
fi

# Compile contracts
log "[HARDHAT] Compiling smart contracts..."
if npx hardhat compile 2>&1 ; then
    echo "[HARDHAT] Compilation successful."
else
    log "[ERROR] Compilation failed."
    exit 1
fi

log "[SYSTEM] Compilation script finished. Log saved at $COMPILE_LOG_FILE"
exit 0
