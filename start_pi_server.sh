#!/bin/bash
# Quick script to start Pi Car server in tmux

PI_HOST="pi@pi_local"

echo "Starting Pi Car server in tmux session 'car_backend'..."
echo ""

ssh "$PI_HOST" '/home/pi/picar/start_server.sh'

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Server started successfully!"
    echo ""
    echo "View logs: ssh $PI_HOST 'tmux attach -t car_backend'"
    echo "Or run: ./view_pi_logs.sh"
    echo ""
    echo "Test camera: http://pi_local:5000/video"
fi
