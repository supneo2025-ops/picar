#!/bin/bash
# Stop Pi Car server tmux session

PI_HOST="pi@pi_local"
SESSION_NAME="car_backend"

echo "Stopping Pi Car server (tmux session: $SESSION_NAME)..."

ssh "$PI_HOST" "tmux kill-session -t $SESSION_NAME 2>/dev/null"

if [ $? -eq 0 ]; then
    echo "✓ Server stopped successfully"
else
    echo "Note: Session may not have been running"
fi
