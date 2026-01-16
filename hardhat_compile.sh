#!/bin/bash

# Get the current project directory
PROJECT_DIR=$(pwd)
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
CACHE_DIR="$PROJECT_DIR/cache"

# Log function for standardized output
log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Delete artifacts and cache directories
if [[ -d $ARTIFACTS_DIR ]]; then
    log "Deleting existing artifacts directory."
    rm -rf "$ARTIFACTS_DIR"
    log "Artifacts directory deleted."
fi

if [[ -d $CACHE_DIR ]]; then
    log "Deleting existing cache directory."
    rm -rf "$CACHE_DIR"
    log "Cache directory deleted."
fi

# Compile the contracts
log "Starting compilation of smart contracts."
if npx hardhat compile; then
    log "Compilation successful."
else
    log "Error: Compilation failed."
    exit 1
fi

# Copy the ABI files to the frontend directory
log "Copying ABI files to frontend directory."
if cp -r "$ARTIFACTS_DIR/contracts/"* "$PROJECT_DIR/frontend/abi/"; then
    log "ABI files copied successfully."
else
    log "Error: Failed to copy ABI files."
    exit 1
fi

# Exit script successfully
log "Script executed successfully."
exit 0
