#!/bin/bash
set -euo pipefail

export PROJECT_DIR=$(pwd)
export ENV_FILE="$PROJECT_DIR/.env"
export SCRIPTS_DIR="./scripts"
export LOGS_DIR="$PROJECT_DIR/logs"
export ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
export CACHE_DIR="$PROJECT_DIR/cache"
export FRONTEND_DIR="$PROJECT_DIR/frontend"
export ABI_DIR="$PROJECT_DIR/frontend/abi"
export DEPLOY_OUTPUT=$(npx --prefix "$PROJECT_DIR" hardhat run scripts/deploy.ts --network localhost 2>&1)

mkdir -p "$LOGS_DIR" "$ABI_DIR"

# Set a default log file (can be updated later)
LOG_FILE="$LOGS_DIR/main.log"  # This can be customized as needed

# Helper function to create a timestamped log file
function create_log_file() {
    local prefix=$1
    echo "$LOGS_DIR/${prefix}_$(date +'%Y%m%d_%H%M%S').log"
}

function log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

function update_dotenv_after_hardhat_deploy() {
    bash $SCRIPTS_DIR/init_dotenv.sh
}

function hardhat_run_node() {
    local log_file
    log_file=$(create_log_file "hardhat_node")
    echo "[CONTRACT] Starting Hardhat node... Logs -> $log_file"

    if lsof -i:8545 -t >/dev/null 2>&1; then
        echo "[CONTRACT] Hardhat node already running on port 8545, skipping start."
        return 0
    fi

    # start detached so it survives and logs to terminal + file
    setsid bash -lc "npx --prefix \"$PROJECT_DIR\" hardhat node 2>&1 | tee \"$log_file\"" >/dev/null 2>&1 &
    HHH_PID=$!
    echo "[CONTRACT] Hardhat node started (detached) PID $HHH_PID"

    echo "[CONTRACT] Waiting for Hardhat node to be ready..."
    until curl -s http://localhost:8545 >/dev/null; do sleep 1; done
    echo "[CONTRACT] Hardhat node is ready."
}

function hardhat_compile() {
    local log_file
    log_file=$(create_log_file "hardhat_compile")
    echo "[CONTRACT] Compiling smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_compile.sh" 2>&1 | tee "$log_file"
}

function hardhat_deploy() {
    local log_file
    log_file=$(create_log_file "hardhat_deploy")
    echo "[CONTRACT] Deploying smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_deploy.sh" 2>&1 | tee "$log_file"
}

function copy_abi_files() {
    bash $SCRIPTS_DIR/copy_abi_files.sh
}

function run_frontend() {
    bash $SCRIPTS_DIR/run_frontend.sh
}

function run_full_automation_setup() {
    echo "[FULL SETUP] Starting full automation..."
    hardhat_run_node
    hardhat_compile
    hardhat_deploy
    update_dotenv_after_hardhat_deploy
    copy_abi_files
    run_frontend
}

function main_menu() {
    echo "========================================"
    echo "Main Menu:"
    echo "========================================"
    echo "1) Hardhat compile"
    echo "2) Hardhat deploy"
    echo "3) Start / Restart frontend"
    echo "4) Run full automation setup"
    echo "5) Exit"
}

# =========================
# MAIN LOOP
# =========================
while true; do
    main_menu
    read -p "Select an option (1-5): " choice
    case $choice in
        1)
            hardhat_run_node
            hardhat_compile
            ;;
        2)
            hardhat_run_node
            hardhat_deploy
            ;;
        3)
            run_frontend
            ;;
        4)
            run_full_automation_setup
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "[ERROR] Invalid option, please try again."
            ;;
    esac
done
