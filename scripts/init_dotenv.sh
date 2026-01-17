#!/bin/bash

if [[ ! -f $ENV_FILE ]]; then
    touch $ENV_FILE
fi

# Log function to write messages with timestamps
function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ENV_FILE"
}

# Remove old contract addresses from the environment file
sed -i.bak \
    -e '/^WEED_TOKEN_ADDRESS=/d' \
    -e '/^PLANT_NFT_ADDRESS=/d' \
    -e '/^FARM_GAME_ADDRESS=/d' \
    "$ENV_FILE"

# Extract addresses by name (safe & deterministic)
WEED_TOKEN_ADDRESS=$(grep 'WeedToken deployed at:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}')
PLANT_NFT_ADDRESS=$(grep 'PlantNFT deployed at:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}')
FARM_GAME_ADDRESS=$(grep 'FarmGame deployed at:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}')

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
} >"$ENV_FILE"
