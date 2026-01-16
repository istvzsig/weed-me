#!/bin/bash
set -e

# Set the project directory
PROJECT_DIR=$(pwd)
ENV_FILE="$PROJECT_DIR/.env"

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

# Run deployment
DEPLOY_OUTPUT=$(npx --prefix "$PROJECT_DIR" hardhat run scripts/deploy.ts --network localhost 2>&1)

# Print deploy output
echo "$DEPLOY_OUTPUT" | tee -a "$LOG_FILE"

# Ensure .env exists
touch "$ENV_FILE"

# Remove old contract addresses only
sed -i.bak \
    -e '/^WEED_TOKEN_ADDRESS=/d' \
    -e '/^PLANT_NFT_ADDRESS=/d' \
    -e '/^FARM_GAME_ADDRESS=/d' \
    "$ENV_FILE"
rm -f "$ENV_FILE.bak"

# Extract addresses by name (safe & deterministic)
WEED_TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep 'WeedToken deployed at:' | grep -oE '0x[a-fA-F0-9]{40}')
PLANT_NFT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep 'PlantNFT deployed at:' | grep -oE '0x[a-fA-F0-9]{40}')
FARM_GAME_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep 'FarmGame deployed at:' | grep -oE '0x[a-fA-F0-9]{40}')

# Validate extraction
if [[ -z "$WEED_TOKEN_ADDRESS" || -z "$PLANT_NFT_ADDRESS" || -z "$FARM_GAME_ADDRESS" ]]; then
    log "[ERROR] Failed to extract one or more contract addresses"
    exit 1
fi

# Ensure .env ends with a newline
tail -c 1 "$ENV_FILE" | read -r _ || echo >> "$ENV_FILE"

# Append new addresses
{
    echo "WEED_TOKEN_ADDRESS=$WEED_TOKEN_ADDRESS"
    echo "PLANT_NFT_ADDRESS=$PLANT_NFT_ADDRESS"
    echo "FARM_GAME_ADDRESS=$FARM_GAME_ADDRESS"
} >> "$ENV_FILE"

log "Deployment completed successfully. Log saved at $LOG_FILE"
exit 0
