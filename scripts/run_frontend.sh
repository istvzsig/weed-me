#!/bin/bash
set -euo pipefail

DIR=$1
LOG_FILE="$DIR/../logs/frontend_$(date +'%Y%m%d_%H%M%S').log"
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
npm --prefix "$DIR" run dev 2>&1 | tee "$LOG_FILE" &

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
