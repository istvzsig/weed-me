#!/bin/bash
set -e

# Create a timestamped log file
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$PROJECT_DIR/logs/deploy_$TIMESTAMP.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting deployment script..."

# Cleanup Hardhat artifacts
for dir in artifacts cache; do
    if [[ -d "$PROJECT_DIR/$dir" ]]; then
        log "Removing $dir"
        rm -rf "$PROJECT_DIR/$dir"
    fi
done

log "Deploying to localhost..."

# Print deploy output
echo "$DEPLOY_OUTPUT" | tee -a "$LOG_FILE"