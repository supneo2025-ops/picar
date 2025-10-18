#!/bin/bash
# Attach to Pi Car server tmux session to view logs

PI_HOST="pi@pi_local"
SESSION_NAME="car_backend"

echo "Connecting to tmux session '$SESSION_NAME' on Pi..."
echo ""
echo "Press Ctrl+B then D to detach (leave server running)"
echo "Press Ctrl+C to stop the server"
echo ""
sleep 2

ssh -t "$PI_HOST" "tmux attach -t $SESSION_NAME"
