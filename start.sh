#!/bin/bash
set -euo pipefail

export PROJECT_DIR=$(pwd)
export SCRIPTS_DIR="./scripts"
export LOGS_DIR="$PROJECT_DIR/logs"
export FRONTEND_DIR="$PROJECT_DIR/frontend"
export ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
export CACHE_DIR="$PROJECT_DIR/cache"
export ABI_DIR="$FRONTEND_DIR/abi"
export ENV_FILE="$PROJECT_DIR/.env"
export DEPLOY_LOG_FILE="$PROJECT_DIR/logs/deploy.log"

mkdir -p "$LOGS_DIR" "$ABI_DIR"

LOG_FILE="$LOGS_DIR/main.log"

function create_log_file() {
    local prefix=$1
    echo "$LOGS_DIR/${prefix}_$(date +'%Y%m%d_%H%M%S').log"
}

function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

function hardhat_run_node() {
    local log_file
    log_file=$(create_log_file "hardhat_node")
    log "[HARDHAT] Starting Hardhat node... Logs -> $log_file"

    if lsof -i:8545 -t >/dev/null 2>&1; then
        log "[HARDHAT] Hardhat node already running on port 8545, skipping start."
        return 0
    fi

    # Detached background with tee to log file
    npx --prefix "$PROJECT_DIR" hardhat node 2>&1 | tee "$log_file" &
    HHH_PID=$!
    log "[HARDHAT] Hardhat node started (detached) PID $HHH_PID"

    log "[HARDHAT] Waiting for Hardhat RPC..."
    until curl -s http://localhost:8545 >/dev/null; do sleep 1; done
    log "[HARDHAT] Hardhat node is ready."
}

function hardhat_compile() {
    local log_file
    log_file=$(create_log_file "hardhat_compile")
    log "[HARDHAT] Compiling smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_compile.sh" 2>&1 | tee "$log_file"
}

function hardhat_deploy() {
    local log_file
    log_file=$(create_log_file "hardhat_deploy")
    log "[HARDHAT] Deploying smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_deploy.sh" 2>&1 | tee "$log_file"
}

function copy_abi_files() {
    local log_file
    log_file=$(create_log_file "copy_abi")
    log "[HARDHAT] Copying ABI files... Logs -> $log_file"
    bash "$SCRIPTS_DIR/copy_abi_files.sh" 2>&1 | tee "$log_file"
}

function run_frontend() {
    local log_file
    log_file=$(create_log_file "frontend")
    log "[FRONTEND] Starting frontend... Logs -> $log_file"
    bash "$SCRIPTS_DIR/run_frontend.sh" 2>&1 | tee "$log_file" &
    FRONTEND_PID=$!
    log "[FRONTEND] Frontend started (detached) PID $FRONTEND_PID"

    # wait for port
    local PORT=3000
    log "[FRONTEND] Waiting for frontend on port $PORT..."
    until lsof -i:$PORT -t >/dev/null; do sleep 1; done
    log "[FRONTEND] Frontend is now running."
}

function dotenv_setup() {
    bash "$SCRIPTS_DIR/dotenv_setup.sh"
}

function run_full_automation_setup() {
    log "[SYSTEM] Starting full automation..."
    hardhat_run_node
    hardhat_compile
    hardhat_deploy
    copy_abi_files 
    dotenv_setup 
    run_frontend
}

function main_menu() {
    echo "========================================"
    echo "Main Menu:"
    echo "========================================"
    echo "1) Run full automation setup"
    echo "2) Hardhat node"
    echo "3) Hardhat compile"
    echo "4) Hardhat deploy"
    echo "5) Start / Restart frontend server"
    echo "6) Exit"
}

# main_menu
# while true; do
#     read -p "Select an option (1-6): " choice
#     case $choice in
#         1) run_full_automation_setup ;;
#         2) hardhat_run_node ;;
#         3) hardhat_compile ;;
#         4) hardhat_deploy ;;
#         5) run_frontend ;;
#         6) exit 0 ;;
#         *) log "[ERROR] Invalid option, please try again." ;;
#     esac
# done


run_full_automation_setup