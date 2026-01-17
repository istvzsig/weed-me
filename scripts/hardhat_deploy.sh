#!/bin/bash
set -e

export DEPLOY_OUTPUT=$(npx --prefix "$PROJECT_DIR" hardhat run scripts/deploy.ts --network localhost 2>&1)

# Log function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "[HARDHAT] Deploying to localhost..."

# Print deploy output
echo "$DEPLOY_OUTPUT" > "$DEPLOY_LOG_FILE"