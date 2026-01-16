#!/bin/bash
set -euo pipefail  # Improved error handling

# =========================
# PROJECT SETUP
# =========================
export PROJECT_DIR=$(pwd)
export SCRIPTS_DIR="$PROJECT_DIR/scripts"
export LOGS_DIR="$PROJECT_DIR/logs"
export ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
export CACHE_DIR="$PROJECT_DIR/cache"
export ABI_DIR="$PROJECT_DIR/frontend/abi"

# Create necessary directories
mkdir -p "$LOGS_DIR" "$ABI_DIR"

# Set a default log file (can be updated later)
LOG_FILE="$LOGS_DIR/main.log"  # This can be customized as needed

# Helper function to create a timestamped log file
create_log_file() {
    local prefix=$1
    echo "$LOGS_DIR/${prefix}_$(date +'%Y%m%d_%H%M%S').log"
}

# Log function
log() {
    echo "[LOG] $(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# =========================
# HARDHAT NODE
# =========================
function hardhat_run_node() {
    local log_file
    log_file=$(create_log_file "hardhat_node")
    echo "[CONTRACT] Starting Hardhat node... Logs -> $log_file"

    if lsof -i:8545 -t >/dev/null 2>&1; then
        echo "[CONTRACT] Hardhat node already running on port 8545, skipping start."
    else
        nohup npx --prefix "$PROJECT_DIR" hardhat node >"$log_file" 2>&1 &
        HHH_PID=$!
        echo "[CONTRACT] Hardhat node started with PID $HHH_PID"

        echo "[CONTRACT] Waiting for Hardhat node to be ready..."
        until curl -s http://localhost:8545 >/dev/null; do
            sleep 1
        done
        echo "[CONTRACT] Hardhat node is ready."
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
# COPY ABI FILES
# =========================
function copy_abi_files() {
    log "Preparing to copy ABI files to frontend directory..."
    mkdir -p "$ABI_DIR"
    
    # Check if the contracts directory exists and is not empty
    if [ -d "$ARTIFACTS_DIR/contracts/" ] && [ "$(ls -A $ARTIFACTS_DIR/contracts/)" ]; then
        log "Copying ABI files from $ARTIFACTS_DIR/contracts/ to $ABI_DIR/"
        
        # Correctly copy .json files directly from the contracts directory or its subdirectories
        cp "$ARTIFACTS_DIR/contracts/"*.sol/*.json "$ABI_DIR/" && log "ABI files copied successfully."
    else
        log "Warning: No ABI files found to copy from $ARTIFACTS_DIR/contracts/"
    fi
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
    LOG_FILE="$dir/../logs/frontend_$(date +'%Y%m%d_%H%M%S').log"
    PORT=3000

    # Create necessary directories
    mkdir -p "$(dirname "$LOG_FILE")"

    # Kill any existing frontend processes
    PIDS=$(lsof -i:$PORT -t || true)
    if [[ -n "$PIDS" ]]; then
        echo "[FRONTEND] Frontend already running on port $PORT. Killing PIDs: $PIDS"
        for pid in $PIDS; do
            kill -9 "$pid"
            echo "[FRONTEND] Killed PID $pid"
        done
    fi

    echo "[FRONTEND] Starting frontend... Logs will be displayed in the terminal."

    # Start the frontend and log output to both terminal and log file
    npm --prefix "$dir" run dev 2>&1 | tee "$LOG_FILE" &

    FRONTEND_PID=$!
    echo "[FRONTEND] Frontend started with PID $FRONTEND_PID"

    # Wait for the frontend to be available
    echo "[FRONTEND] Monitoring frontend on port $PORT..."
    until lsof -i:$PORT -t >/dev/null; do
        sleep 1
    done

    echo "[FRONTEND] Frontend is now running."

    # Keep the script running to prevent returning to the main menu
    while true; do
        sleep 1
        # Check if the frontend is still running
        if ! ps -p $FRONTEND_PID > /dev/null; then
            echo "[FRONTEND] Frontend process has exited."
            break
        fi
    done
}

function run_full_automation_setup() {
    echo "[FULL SETUP] Starting full automation..."
    hardhat_run_node
    hardhat_compile
    hardhat_deploy
    copy_abi_files
    run_frontend # Call run_frontend to keep it active
}

# =========================
# MENU
# =========================
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
