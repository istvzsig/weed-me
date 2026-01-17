#!/bin/bash
set -e

echo HARDHAT "Deploying to localhost..."
export DEPLOY_OUTPUT=$(npx --prefix "$PROJECT_DIR" hardhat run scripts/deploy.ts --network localhost 2>&1 | tee -a "$DEPLOY_LOG_FILE")

