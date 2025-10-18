#!/bin/bash
# Restart Pi Car server

echo "Restarting Pi Car server..."
echo ""

# Stop if running
./stop_pi_server.sh

echo ""
sleep 1

# Start again
./start_pi_server.sh
