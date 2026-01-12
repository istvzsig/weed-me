#!/bin/bash

PROJECT_DIR=$(pwd)

function run_command() {
    osascript -e "tell application \"Terminal\" to tell front window to do script \"$1\""
}

# Start Hardhat node
run_command "cd $PROJECT_DIR; npx hardhat node"

# Use a simple delay to ensure Hardhat node is up
sleep 5

# Run the deployment command in the current Terminal window
run_command "cd $PROJECT_DIR; npx hardhat run scripts/deploy.ts --network localhost"

# Start the frontend development server
run_command "cd $PROJECT_DIR; DEBUG=* npm --prefix ./frontend run dev"
