#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$PROJECT_DIR/logs"

SCRIPTS_DIR="$PROJECT_DIR/scripts"
FRONTEND_DIR="$PROJECT_DIR/frontend"
ABI_DIR="$FRONTEND_DIR/abi"
FRONTEND_PORT=3000
BACKEND_PORT=8545
DEPLOY_LOG_FILE="${DEPLOY_LOG_FILE:-"$LOGS_DIR/deploy.log"}"

mkdir -p "$LOGS_DIR" "$ABI_DIR"
LOG_FILE="$LOGS_DIR/main.log"

PIDS=()

STARTED_HARDHAT=0
STARTED_FRONTEND=0

export PROJECT_DIR LOGS_DIR ENV_FILE DEPLOY_LOG_FILE FRONTEND_DIR

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

create_log_file() {
  local prefix=$1
  mkdir -p "$LOGS_DIR"
  echo "$LOGS_DIR/${prefix}_$(date +'%Y%m%d_%H%M%S').log"
}

kill_port_if_started() {
  local port="$1"
  local started_flag="$2" # 1 if started by this script, else 0

  [[ "$started_flag" -eq 1 ]] || return 0

  if lsof -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
    log "[SYSTEM] Stopping listeners on port $port"
    lsof -iTCP:"$port" -sTCP:LISTEN -t | xargs -r kill -TERM || true
  fi
}

cleanup() {
  log "[SYSTEM] Caught interrupt. Cleaning up..."

  # Try to stop tracked PIDs
  for pid in "${PIDS[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      log "[SYSTEM] Stopping PID $pid"
      kill -TERM "$pid" >/dev/null 2>&1 || true
    fi
  done

  # As a safety net, stop ports ONLY if we started them
  kill_port_if_started "$BACKEND_PORT" "$STARTED_HARDHAT"
  kill_port_if_started "$FRONTEND_PORT" "$STARTED_FRONTEND"
}

# Only cleanup on Ctrl+C / termination, not on every error/exit
trap cleanup INT TERM

hardhat_run_node() {
  local log_file
  log_file="$(create_log_file "hardhat_node")"
  log "[HARDHAT] Starting Hardhat node... Logs -> $log_file"

  if lsof -iTCP:"$BACKEND_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    log "[HARDHAT] Already running on port $BACKEND_PORT, skipping start."
    STARTED_HARDHAT=0
    return 0
  fi

  STARTED_HARDHAT=1

  # Prefer setsid (clean process group) if available
  if command -v setsid >/dev/null 2>&1; then
    ( setsid npx --prefix "$PROJECT_DIR" hardhat node ) 2>&1 | tee "$log_file" &
  else
    # Fallback: still logs; may leave child behind in rare cases -> port kill handles it (since we started it)
    ( npx --prefix "$PROJECT_DIR" hardhat node ) 2>&1 | tee "$log_file" &
  fi

  local pid=$!
  PIDS+=("$pid")
  log "[HARDHAT] Hardhat node started PID $pid"

  log "[HARDHAT] Waiting for Hardhat RPC..."
  until curl -s "http://localhost:$BACKEND_PORT" >/dev/null 2>&1; do sleep 1; done
  log "[HARDHAT] Hardhat node is ready."
}
run_frontend() {
  local log_file
  log_file="$(create_log_file "frontend")"
  log "[FRONTEND] Starting / restarting frontend... Logs -> $log_file"

  # Find any process listening on the frontend port
  local existing_pids
  existing_pids="$(lsof -iTCP:"$FRONTEND_PORT" -sTCP:LISTEN -t || true)"

  if [[ -n "$existing_pids" ]]; then
    log "[FRONTEND] Frontend already running on port $FRONTEND_PORT — restarting"
    echo "$existing_pids" | xargs -r kill -TERM
    sleep 2
  fi

  STARTED_FRONTEND=1

  if command -v setsid >/dev/null 2>&1; then
    ( setsid bash "$SCRIPTS_DIR/run_frontend.sh" ) 2>&1 | tee "$log_file" &
  else
    ( bash "$SCRIPTS_DIR/run_frontend.sh" ) 2>&1 | tee "$log_file" &
  fi

  local pid=$!
  PIDS+=("$pid")
  log "[FRONTEND] Frontend started PID $pid"

  log "[FRONTEND] Waiting for frontend on port $FRONTEND_PORT..."
  until lsof -iTCP:"$FRONTEND_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; do
    sleep 1
  done

  log "[FRONTEND] Frontend is now running on port $FRONTEND_PORT"
}


run_full_automation_setup() {
  log "[SYSTEM] Starting full automation..."
  hardhat_run_node

  log "[HARDHAT] Starting hardhat compilation script..."
  bash "$SCRIPTS_DIR/hardhat_compile.sh" 2>&1 | tee "$(create_log_file "compile")"

  log "[HARDHAT] Starting hardhat deploy script..."
  bash "$SCRIPTS_DIR/hardhat_deploy.sh" 2>&1 | tee "$(create_log_file "deploy")"

  log "[HARDHAT] Copying ABI files..."
  bash "$SCRIPTS_DIR/copy_abi_files.sh" 2>&1 | tee "$(create_log_file "copy_abi")"

  log "[SYSTEM] Setting up dotenv..."
  bash "$SCRIPTS_DIR/dotenv_setup.sh" 2>&1 | tee "$(create_log_file "dotenv")"

  run_frontend
}

run_full_automation_setup

# Keep the script alive until background jobs end, so Ctrl+C works predictably
wait
