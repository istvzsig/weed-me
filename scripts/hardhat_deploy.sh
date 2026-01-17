#!/bin/bash
set -e

# Log function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "[HARDHAT] Deploying to localhost..."

# Print deploy output
echo "$DEPLOY_OUTPUT" > "$DEPLOY_LOG_FILE"