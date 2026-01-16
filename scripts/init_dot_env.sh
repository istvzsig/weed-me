#!/bin/bash
set -e

PROJECT_DIR=$(pwd)
ENV_FILE="$PROJECT_DIR/frontend/.env.local"

echo "[INIT] Initializing frontend .env.local file..."

# Create .env.local if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    echo "[INIT] Created empty .env.local"
else
    # If it exists, empty it
    > "$ENV_FILE"
    echo "[INIT] Cleared existing .env.local"
fi

# Add placeholder variables
cat <<EOL >> "$ENV_FILE"
# Frontend environment variables (initially empty)
WEED_TOKEN_ADDRESS=
PLANT_NFT_ADDRESS=
FARM_GAME_ADDRESS=
EOL

echo "[INIT] .env.local initialized with placeholder variables."
