#!/bin/bash
# Deploy Pi Car Server to Raspberry Pi

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Deploying Pi Car Server to Raspberry Pi${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Configuration
PI_HOST="pi@pi_local"
PI_DIR="/home/pi/picar"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${YELLOW}[1/5] Testing connection to Pi...${NC}"
if ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Connection successful'" &>/dev/null; then
    echo -e "${GREEN}✓ Connected to $PI_HOST${NC}"
else
    echo -e "${RED}✗ Cannot connect to $PI_HOST${NC}"
    echo "Please check:"
    echo "  - Pi is powered on"
    echo "  - Connected to same network"
    echo "  - Can ping: ping pi_local"
    exit 1
fi

echo ""
echo -e "${YELLOW}[2/5] Creating directory on Pi...${NC}"
ssh "$PI_HOST" "mkdir -p $PI_DIR/pi-server"
echo -e "${GREEN}✓ Directory created: $PI_DIR${NC}"

echo ""
echo -e "${YELLOW}[3/5] Copying server files...${NC}"
rsync -avz --progress \
    "$LOCAL_DIR/pi-server/" \
    "$PI_HOST:$PI_DIR/pi-server/" \
    --exclude "venv" \
    --exclude "__pycache__" \
    --exclude "*.pyc" \
    --exclude ".DS_Store"

echo -e "${GREEN}✓ Files copied successfully${NC}"

echo ""
echo -e "${YELLOW}[4/5] Installing dependencies on Pi...${NC}"
ssh "$PI_HOST" << 'ENDSSH'
cd /home/pi/picar/pi-server
echo "Installing Python packages..."
pip3 install -q Flask Flask-SocketIO python-socketio eventlet Pillow numpy 2>/dev/null || true
pip3 install -q RPi.GPIO picamera2 simplejpeg 2>/dev/null || true
echo "Dependencies installed"
ENDSSH

echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""
echo -e "${YELLOW}[5/5] Setting up tmux session...${NC}"

# Create tmux startup script on Pi
ssh "$PI_HOST" "cat > /home/pi/picar/start_server.sh" << 'ENDSCRIPT'
#!/bin/bash
# Start Pi Car Server in tmux

SESSION_NAME="car_backend"

# Check if session exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists."
    echo "To view: tmux attach -t $SESSION_NAME"
    echo "To kill: tmux kill-session -t $SESSION_NAME"
    exit 1
fi

# Create new tmux session
echo "Creating tmux session: $SESSION_NAME"
tmux new-session -d -s $SESSION_NAME -c /home/pi/picar/pi-server

# Send commands to the session
tmux send-keys -t $SESSION_NAME "cd /home/pi/picar/pi-server" C-m
tmux send-keys -t $SESSION_NAME "python3 server.py" C-m

echo ""
echo "✓ Server started in tmux session: $SESSION_NAME"
echo ""
echo "Commands:"
echo "  View server:   tmux attach -t $SESSION_NAME"
echo "  Detach:        Ctrl+B then D"
echo "  Stop server:   Ctrl+C (in tmux)"
echo "  Kill session:  tmux kill-session -t $SESSION_NAME"
echo ""
ENDSCRIPT

# Make script executable
ssh "$PI_HOST" "chmod +x /home/pi/picar/start_server.sh"

echo -e "${GREEN}✓ Tmux startup script created${NC}"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Server files deployed to: ${NC}$PI_DIR/pi-server"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Start the server:"
echo -e "   ${BLUE}ssh $PI_HOST '/home/pi/picar/start_server.sh'${NC}"
echo ""
echo "2. View the server logs:"
echo -e "   ${BLUE}ssh $PI_HOST 'tmux attach -t car_backend'${NC}"
echo "   (Press Ctrl+B then D to detach)"
echo ""
echo "3. Stop the server:"
echo -e "   ${BLUE}ssh $PI_HOST 'tmux kill-session -t car_backend'${NC}"
echo ""
echo "4. Test camera stream in browser:"
echo -e "   ${BLUE}http://pi_local:5000/video${NC}"
echo ""
echo -e "${YELLOW}Auto-start option:${NC}"
echo "To start server now:"
echo -e "   ${BLUE}./start_pi_server.sh${NC}"
echo ""
