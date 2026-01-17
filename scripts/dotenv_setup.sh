#!/bin/bash

if [[ ! -f $ENV_FILE ]]; then
    touch $ENV_FILE
fi

rm -rf $ENV_FILE

# Log function to write messages with timestamps
function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ENV_FILE"
}
if [[ ! -f "$DEPLOY_LOG_FILE" ]]; then
    echo "[ERROR] Deploy log file not found: $DEPLOY_LOG_FILE"
    exit 1
fi

# Extract addresses by name (safe & deterministic)
WEED_TOKEN_ADDRESS=$(grep 'WeedToken:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)
SEED_NFT_ADDRESS=$(grep 'SeedNFT:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)
PLANT_NFT_ADDRESS=$(grep 'PlantNFT:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)
FARM_GAME_ADDRESS=$(grep 'FarmGame:' "$DEPLOY_LOG_FILE" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)

# Validate extraction
if [[ -z "$WEED_TOKEN_ADDRESS" || -z "$SEED_NFT_ADDRESS" || -z "$PLANT_NFT_ADDRESS"  || -z "$FARM_GAME_ADDRESS" ]]; then
    echo "[ERROR] Failed to extract one or more contract addresses"
    exit 1
fi

# ---- Write fresh .env (single write) ----
cat <<EOF > "$ENV_FILE"
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
WEED_TOKEN_ADDRESS=$WEED_TOKEN_ADDRESS
SEED_NFT_ADDRESS=$SEED_NFT_ADDRESS
PLANT_NFT_ADDRESS=$PLANT_NFT_ADDRESS
FARM_GAME_ADDRESS=$FARM_GAME_ADDRESS
EOF

echo "[OK] Fresh .env written"