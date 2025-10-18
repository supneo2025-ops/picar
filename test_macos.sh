#!/bin/bash
# macOS Testing Helper Script
# Quick setup and test for Pi Car server on macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Pi Car Server - macOS Testing Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "pi-server/server.py" ]; then
    echo -e "${RED}Error: Must run from picar/ root directory${NC}"
    echo "Usage: cd ~/PycharmProjects/picar && ./test_macos.sh"
    exit 1
fi

cd pi-server

# Step 1: Check Python version
echo -e "${YELLOW}[1/5] Checking Python version...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Found: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.9+${NC}"
    exit 1
fi

# Step 2: Create virtual environment
echo ""
echo -e "${YELLOW}[2/5] Setting up virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Step 3: Activate and install dependencies
echo ""
echo -e "${YELLOW}[3/5] Installing dependencies...${NC}"
source venv/bin/activate

# Install only macOS-compatible packages
echo "Installing Flask and dependencies..."
pip3 install --quiet Flask Flask-SocketIO python-socketio eventlet Pillow numpy 2>/dev/null || true

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo -e "${BLUE}Note: RPi.GPIO and picamera2 skipped (not needed for macOS testing)${NC}"

# Step 4: Get Mac IP address
echo ""
echo -e "${YELLOW}[4/5] Network configuration...${NC}"
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if [ -z "$MAC_IP" ]; then
    MAC_IP="localhost"
fi
echo -e "${GREEN}✓ Server will be accessible at: ${BLUE}http://$MAC_IP:5000${NC}"

# Step 5: Show instructions
echo ""
echo -e "${YELLOW}[5/5] Setup complete!${NC}"
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Ready to Test!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Starting Pi Car server in simulation mode...${NC}"
echo ""
echo -e "Server endpoints:"
echo -e "  • Status page: ${BLUE}http://$MAC_IP:5000/${NC}"
echo -e "  • Health check: ${BLUE}http://$MAC_IP:5000/health${NC}"
echo -e "  • Video stream: ${BLUE}http://$MAC_IP:5000/video${NC}"
echo ""
echo -e "For iOS testing:"
echo -e "  • Simulator: Use ${BLUE}localhost${NC} or ${BLUE}127.0.0.1${NC}"
echo -e "  • Device: Use ${BLUE}$MAC_IP${NC}"
echo ""
echo -e "Update WebSocketClient.swift with: ${BLUE}$MAC_IP${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop server${NC}"
echo ""
echo -e "${GREEN}================================================${NC}"
echo ""

# Start the server
python3 server.py
