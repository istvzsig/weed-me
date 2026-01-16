#!/bin/bash
set -e

# Set the project directory
PROJECT_DIR=$(pwd)
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
CACHE_DIR="$PROJECT_DIR/cache"

# Create a timestamped log file
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$PROJECT_DIR/logs/compile_$TIMESTAMP.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting compilation script..."

# Delete artifacts and cache
if [[ -d $ARTIFACTS_DIR ]]; then
    log "Deleting existing artifacts directory."
    rm -rf "$ARTIFACTS_DIR"
fi

if [[ -d $CACHE_DIR ]]; then
    log "Deleting existing cache directory."
    rm -rf "$CACHE_DIR"
fi

# Compile contracts
log "Compiling smart contracts..."
if npx hardhat compile 2>&1 | tee -a "$LOG_FILE"; then
    log "Compilation successful."
else
    log "Error: Compilation failed."
    exit 1
fi

log "Compilation script finished. Log saved at $LOG_FILE"
exit 0
