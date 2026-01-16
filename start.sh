#!/bin/bash
set -e

# Set the project directory
PROJECT_DIR=$(pwd)
SCRIPTS_DIR="$PROJECT_DIR/scripts"
mkdir -p "$PROJECT_DIR/logs"

# Helper to create timestamped log file
function create_log_file() {
    local prefix=$1
    echo "$PROJECT_DIR/logs/${prefix}_$(date +'%Y%m%d_%H%M%S').log"
}

# =========================
# HARDHAT NODE
# =========================
function hardhat_run_node() {
    if lsof -i:8545 -t >/dev/null 2>&1; then
        echo "[CONTRACT] Hardhat node already running on port 8545, skipping start."
    else
        local log_file
        log_file=$(create_log_file "hardhat_node")
        echo "[CONTRACT] Starting Hardhat node... Logs -> $log_file"
        DEBUG=* npx --prefix "$PROJECT_DIR" hardhat node 2>&1 | tee "$log_file" &
        HHH_PID=$!
        echo "[CONTRACT] Hardhat node started with PID $HHH_PID"
    fi
}

# =========================
# HARDHAT COMPILE
# =========================
function hardhat_compile() {
    local log_file
    log_file=$(create_log_file "hardhat_compile")
    echo "[CONTRACT] Compiling smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_compile.sh" 2>&1 | tee "$log_file"
}

# =========================
# HARDHAT DEPLOY
# =========================
function hardhat_deploy() {
    local log_file
    log_file=$(create_log_file "hardhat_deploy")
    echo "[CONTRACT] Deploying smart contracts... Logs -> $log_file"
    bash "$SCRIPTS_DIR/hardhat_deploy.sh" 2>&1 | tee "$log_file"
}

# =========================
# FRONTEND
# =========================
function run_frontend() {
    local dir="$PROJECT_DIR/frontend"
    local log_file
    log_file=$(create_log_file "frontend")
    echo "[FRONTEND] Starting frontend... Logs -> $log_file"
    
    # Kill existing frontend if running
    local pid
    pid=$(lsof -i:3000 -t || true)
    if [[ -n "$pid" ]]; then
        echo "[FRONTEND] Frontend already running (PID: $pid), killing..."
        kill -9 "$pid"
    fi

    # Start frontend script
    bash "$SCRIPTS_DIR/run_frontend.sh" "$dir"
    FRONTEND_PID=$!
    echo "[FRONTEND] Frontend started with PID $FRONTEND_PID"
}

# =========================
# MENU
# =========================
function show_menu() {
    echo "========================================"
    echo "Main Menu:"
    echo "========================================"
    echo "1) Hardhat compile"
    echo "2) Hardhat deploy"
    echo "3) Start / Restart frontend"
    echo "4) Run full automation setup"
    echo "5) Exit"
}

while true; do
    show_menu
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
            hardhat_run_node
            hardhat_compile
            hardhat_deploy
            run_frontend
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
