# macOS Testing Guide

Guide for testing the Pi Car application on macOS without Raspberry Pi hardware.

## Overview

You can test most components on your Mac:
- ✅ Pi Server (simulation mode)
- ✅ iOS App (Simulator or device)
- ✅ WebSocket communication
- ❌ GPIO control (simulated only)
- ❌ Pi Camera (simulated only)

## Part 1: Testing Pi Server on macOS

### Step 1: Setup Python Environment

```bash
cd ~/PycharmProjects/picar/pi-server

# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate

# Install dependencies (some will fail gracefully on macOS)
pip3 install Flask Flask-SocketIO python-socketio eventlet Pillow numpy
```

**Note:** `RPi.GPIO` and `picamera2` won't install on macOS, but that's okay - the server runs in simulation mode.

### Step 2: Run Server in Simulation Mode

```bash
cd ~/PycharmProjects/picar/pi-server
python3 server.py
```

You should see:
```
WARNING: RPi.GPIO not available. Running in simulation mode.
WARNING: picamera2 not available. Camera streaming disabled.
[INFO] Starting Pi Car Server...
[INFO] ✗ Camera initialization failed - streaming disabled
[INFO] ✗ GPIO not available - controller in simulation mode
[INFO] Server running on 0.0.0.0:5000
```

The server is now running! Even without hardware, it will:
- ✅ Accept WebSocket connections
- ✅ Process control commands
- ✅ Log motor commands (simulated)
- ✅ Serve video placeholder
- ✅ Respond to HTTP requests

### Step 3: Test Server Endpoints

Open your browser and test these URLs:

**Status Page:**
```
http://localhost:5000/
```
You'll see the server status page with warnings about simulation mode.

**Health Check:**
```
http://localhost:5000/health
```
Returns JSON:
```json
{
  "status": "ok",
  "camera": false,
  "controller": false
}
```

**Video Stream:**
```
http://localhost:5000/video
```
Shows placeholder image (camera not available).

### Step 4: Test WebSocket with Browser Console

Open browser console (F12) and paste:

```javascript
// Connect to WebSocket
const socket = io('http://localhost:5000');

socket.on('connect', () => {
    console.log('Connected!');
});

socket.on('status', (data) => {
    console.log('Status:', data);
});

// Send control command
socket.emit('control', {
    type: 'control',
    x: 0.5,
    y: 0.8
});
```

Check the Python server terminal - you should see logged motor commands.

## Part 2: Testing iOS App on macOS

### Step 1: Setup Xcode Project

Follow the detailed instructions in `ios-app/XCODE_SETUP.md`:

```bash
cd ~/PycharmProjects/picar/ios-app
open PiCarController  # Will open Xcode
```

If project doesn't exist yet:
1. Open Xcode
2. Create new iOS App project
3. Name: `PiCarController`
4. Interface: SwiftUI
5. Save to: `picar/ios-app/`
6. Add all Swift files from `PiCarController/` folders

### Step 2: Update Server Address

Since you're testing locally, update the server IP:

**File:** `ios-app/PiCarController/PiCarController/Models/WebSocketClient.swift`

```swift
// Change from:
static let PI_SERVER_IP = "192.168.100.148"

// To:
static let PI_SERVER_IP = "localhost"
// Or your Mac's local IP if testing on device
```

### Step 3: Run on iOS Simulator

1. Make sure Pi server is running on your Mac
2. In Xcode, select **iPhone 14 Pro** (or any simulator)
3. Click Run ▶ or press `Cmd+R`
4. App will launch in simulator

**What works in simulator:**
- ✅ UI and layout
- ✅ Joystick interaction
- ✅ WebSocket connection to localhost
- ✅ Control command sending
- ✅ Connection status
- ❌ Video stream (placeholder shown)

### Step 4: Run on Physical iOS Device

For better testing, use a real iPhone/iPad:

1. Connect device via USB
2. Select your device in Xcode
3. Configure signing:
   - Select project > Signing & Capabilities
   - Choose your Team
4. Click Run ▶

**If testing on same Mac:**
- Server IP: `localhost` works if running on simulator
- Server IP: Your Mac's IP (check with `ifconfig`) for physical device

**To find your Mac's IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

## Part 3: Complete Local Test Workflow

### Terminal 1: Run Pi Server

```bash
cd ~/PycharmProjects/picar/pi-server
python3 server.py
```

Keep this running and watch the logs.

### Terminal 2: Monitor Logs (Optional)

```bash
# In another terminal, watch for control commands
cd ~/PycharmProjects/picar/pi-server
tail -f server.log  # If you add file logging
```

### Xcode: Run iOS App

1. Open Xcode project
2. Build and run (Cmd+R)
3. Watch both Xcode console and server terminal

### Test Flow

1. **Connection Test:**
   - Launch iOS app
   - Check for "Connected" status (green)
   - Server terminal should show: "Client connected"

2. **Control Test:**
   - Move joystick in iOS app
   - Watch position indicators update
   - Server terminal should log control commands:
     ```
     [DEBUG] Joystick: (0.50, 0.80) -> Left: 1@76%, Right: 1@97%
     ```

3. **Reconnection Test:**
   - Stop Python server (Ctrl+C)
   - iOS app should show "Disconnected" (red)
   - Restart server
   - App should auto-reconnect within 2 seconds

4. **Video Test:**
   - Should show "Camera Unavailable" placeholder
   - This is expected without real Pi camera

## Part 4: Advanced Testing

### Test Individual Components

**Test Car Controller:**
```bash
cd ~/PycharmProjects/picar/pi-server
python3 car_controller.py
```

Output shows simulation mode tests.

**Test Camera Stream:**
```bash
cd ~/PycharmProjects/picar/pi-server
python3 camera_stream.py
```

Shows camera unavailable (expected on macOS).

### Test with Mock Camera

To test video streaming, create a mock camera feed:

**Create:** `pi-server/mock_camera.py`
```python
from flask import Flask, Response
import cv2
import numpy as np
import time

app = Flask(__name__)

def generate_frames():
    """Generate test pattern frames"""
    while True:
        # Create test pattern
        img = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)

        # Add text
        cv2.putText(img, f'Test Frame {int(time.time())}',
                   (50, 50), cv2.FONT_HERSHEY_SIMPLEX,
                   1, (255, 255, 255), 2)

        # Encode as JPEG
        _, jpeg = cv2.imencode('.jpg', img)
        frame = jpeg.tobytes()

        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

        time.sleep(0.033)  # ~30fps

@app.route('/video')
def video():
    return Response(generate_frames(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
```

Then run it:
```bash
pip3 install opencv-python
python3 mock_camera.py
```

Update iOS app to use port 5001 for video testing.

## Part 5: Debugging Tips

### Python Server Not Starting

**Error: "Address already in use"**
```bash
# Kill process on port 5000
lsof -ti:5000 | xargs kill -9
```

**Error: "Module not found"**
```bash
# Make sure you're in virtual environment
source venv/bin/activate
pip3 list  # Check installed packages
```

### iOS App Won't Connect

**Simulator can't reach localhost:**
- Use `127.0.0.1` instead of `localhost`
- Check server is running: `curl http://localhost:5000/health`

**Physical device can't connect:**
- Use Mac's actual IP address, not localhost
- Check firewall: System Preferences > Security > Firewall
- Disable firewall temporarily for testing

**WebSocket connection fails:**
- Check server logs for connection attempts
- Try accessing in Safari first: `http://YOUR_MAC_IP:5000`
- Check Info.plist allows local networking

### Xcode Build Errors

**"Cannot find type 'MainView'"**
- Ensure all Swift files are added to project target
- Clean build folder: Cmd+Shift+K
- Rebuild: Cmd+B

**"Missing required module 'Combine'"**
- This is a system framework
- Clean and rebuild should fix it

## Part 6: Testing Checklist

Before deploying to Raspberry Pi, verify on macOS:

- [ ] Server starts without errors (simulation mode OK)
- [ ] Server responds to HTTP requests
- [ ] WebSocket connections accepted
- [ ] iOS app builds successfully
- [ ] iOS app UI displays correctly
- [ ] Joystick responds to touch/drag
- [ ] Joystick position updates in real-time
- [ ] WebSocket client connects to server
- [ ] Control commands sent when joystick moves
- [ ] Server logs show received commands
- [ ] Connection status updates correctly
- [ ] Auto-reconnection works after disconnect
- [ ] App handles server offline gracefully

## Part 7: Network Configuration

### Testing on Same Machine (Simulator)

**WebSocketClient.swift:**
```swift
static let PI_SERVER_IP = "localhost"
static let PI_SERVER_PORT = 5000
```

### Testing with iOS Device on Same Network

1. Find your Mac's IP:
```bash
ifconfig en0 | grep "inet " | awk '{print $2}'
# Example: 192.168.1.100
```

2. Update WebSocketClient.swift:
```swift
static let PI_SERVER_IP = "192.168.1.100"  // Your Mac's IP
```

3. Ensure devices on same WiFi network

4. Allow connections in macOS Firewall:
```bash
# Check firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Allow Python
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/python3
```

## Part 8: What You Can't Test on macOS

**Hardware-specific features:**
- ❌ Actual GPIO motor control
- ❌ Real Pi Camera streaming
- ❌ Motor calibration
- ❌ Sensor integration
- ❌ Performance under load

**For full testing, you need:**
- Raspberry Pi with camera
- Motor driver and motors
- Power supply
- Follow main README.md for Pi setup

## Quick Reference Commands

```bash
# Start Pi server (macOS)
cd ~/PycharmProjects/picar/pi-server
python3 server.py

# Find Mac IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Test server health
curl http://localhost:5000/health

# Kill process on port 5000
lsof -ti:5000 | xargs kill -9

# Build iOS app
cd ~/PycharmProjects/picar/ios-app/PiCarController
open PiCarController.xcodeproj
# Then Cmd+R in Xcode
```

## Summary

macOS testing allows you to:
- ✅ Develop and test UI/UX
- ✅ Test network communication
- ✅ Debug WebSocket protocol
- ✅ Verify app logic
- ✅ Test reconnection behavior
- ✅ Iterate quickly without hardware

Once everything works on macOS, deployment to Raspberry Pi should be straightforward!

---

**Next Step:** After successful macOS testing, follow `QUICKSTART.md` for Raspberry Pi deployment.
