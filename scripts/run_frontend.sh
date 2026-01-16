#!/bin/bash
set -e

DIR=$1
LOG_FILE="$DIR/../logs/frontend_$(date +'%Y%m%d_%H%M%S').log"
PORT=3000

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

echo "[FRONTEND] Starting frontend... Logs -> $LOG_FILE"
npm --prefix "$DIR" run dev 2>&1 | tee "$LOG_FILE" &
FRONTEND_PID=$!
echo "[FRONTEND] Frontend started with PID $FRONTEND_PID"
