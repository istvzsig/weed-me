#!/bin/bash

# DEBUGGER={1$}
PROJECT_DIR=$(pwd)
LOG_FILE="logs.txt"

# Clear the log file at the start
echo "" > "$LOG_FILE"

function delete_artifacts_and_cache() {
    echo "[CONTRACT] Deleting artifacts and cache..."
    rm -rf "$PROJECT_DIR/artifacts" "$PROJECT_DIR/cache"
}

function hardhat_start() {
    echo "[CONTRACT] Starting Hardhat node..."
    DEBUG=* npx --prefix "$PROJECT_DIR" hardhat node >> "$LOG_FILE" 2>&1 &
    HHH_PID=$!  # Store the PID of the Hardhat node
    sleep 5  # Initial delay to allow some startup time
}

function hardhat_compiled_check() {
    echo "[CONTRACT] Checking if Hardhat node is running..."
    for i in {1..10}; do
        if nc -z localhost 8545; then
            echo "[CONTRACT] Hardhat node is running!"
            return 0
        fi
        echo "[CONTRACT] Waiting for Hardhat node to start..."
        sleep 1
    done
    echo "[ERROR] Hardhat node did not start in time."
    kill -9 $HHH_PID  # Kill Hardhat node if it fails to start
    exit 1
}

function hardhat_compile() {
    echo "[CONTRACT] Compiling Hardhat project..."
    DEBUG=* npx --prefix "$PROJECT_DIR" hardhat compile >> "$LOG_FILE" 2>&1
}

function hardhat_deploy_localhost() {
    echo "[CONTRACT] Deploying to localhost..."
    DEBUG=* npx --prefix "$PROJECT_DIR" hardhat run scripts/deploy.ts --network localhost >> "$LOG_FILE" 2>&1
}

function start_frontend() {
    echo "[FRONTEND] Starting frontend..."
    (cd "$PROJECT_DIR/frontend" && npm run dev)  # Run in the foreground to see output
}

function show_menu() {
    echo "Main Menu:"
    echo "1) Redeploy"
    echo "2) Start Frontend"
    echo "3) Start Hardhat Node"
    echo "4) Full Development Setup"
    echo "5) Exit"
}

while true; do
    show_menu
    read -p "Select an option (1-5): " choice

    case $choice in
        1)
            delete_artifacts_and_cache
            hardhat_start
            hardhat_compiled_check
            hardhat_compile
            hardhat_deploy_localhost
            ;;
        2)
            start_frontend
            ;;
        3)
            hardhat_start
            ;;
        4)
            echo "[CONTRACT] Running Full Development Setup..."
            delete_artifacts_and_cache
            hardhat_start
            hardhat_compiled_check
            hardhat_compile
            hardhat_deploy_localhost
            start_frontend  # Starts the frontend in the foreground
            ;;
        5)
            echo "[INFO] Exiting..."
            break
            ;;
        *)
            echo "[ERROR] Invalid option, please try again."
            ;;
    esac

    # Optionally, tail the log file here if needed
    tail -f "$LOG_FILE"
done
