# Quick Start Guide

Get your Pi Car up and running in 10 minutes!

## Prerequisites

- Raspberry Pi with camera and motors connected
- iOS device (iPhone/iPad)
- Both devices on same WiFi network

## Step 1: Setup Raspberry Pi Server (5 minutes)

### 1.1 Copy Files to Pi

```bash
# On your Mac, copy the project to Pi
scp -r picar/ pi@192.168.100.148:~/

# Or clone from your repository if you've pushed it
```

### 1.2 Install Dependencies

```bash
# SSH into your Pi
ssh pi@192.168.100.148

# Navigate to project
cd ~/picar/pi-server

# Install Python dependencies
pip3 install -r requirements.txt
```

### 1.3 Configure GPIO Pins

```bash
# Edit config.py to match your wiring
nano config.py

# Update these lines if your pins are different:
# MOTOR_A_PIN1 = 17
# MOTOR_A_PIN2 = 27
# MOTOR_B_PIN1 = 23
# MOTOR_B_PIN2 = 24
```

### 1.4 Start the Server

```bash
# Make server executable
chmod +x server.py

# Run the server
python3 server.py
```

You should see:
```
[INFO] Starting Pi Car Server...
[INFO] Camera initialized successfully
[INFO] GPIO initialized successfully
[INFO] Server running on 0.0.0.0:5000
```

Keep this terminal open!

## Step 2: Setup iOS App (5 minutes)

### 2.1 Open in Xcode

1. Open Xcode
2. File > Open
3. Navigate to `picar/ios-app/PiCarController/`
4. Open `PiCarController.xcodeproj`

### 2.2 Update Server IP

1. Open `Models/WebSocketClient.swift`
2. Change this line to your Pi's IP:
   ```swift
   static let PI_SERVER_IP = "192.168.100.148"  // Change if needed
   ```

### 2.3 Configure Signing

1. Select project in Navigator
2. Select `PiCarController` target
3. Signing & Capabilities tab
4. Select your Team
5. Let Xcode create provisioning profile

### 2.4 Build and Run

1. Connect your iPhone via USB
2. Select your iPhone as target device
3. Click Run ▶ (or Cmd+R)
4. App will install and launch

## Step 3: Test Everything

### 3.1 Check Connection

- App should show "Connected" (green indicator)
- If red, check:
  - Is Pi server running?
  - Are both devices on same WiFi?
  - Is IP address correct?

### 3.2 Test Video Stream

- You should see live video from Pi camera
- If not:
  - Check Pi camera is connected: `libcamera-hello --list-cameras`
  - Test in browser: `http://192.168.100.148:5000/video`

### 3.3 Test Controls

1. Drag joystick up → Car should move forward
2. Drag joystick down → Car should move backward
3. Drag left/right → Car should turn
4. Release joystick → Car should stop

## Common Issues

### Pi Server Won't Start

**Error: "Camera not found"**
```bash
# Enable camera
sudo raspi-config
# Interface Options > Camera > Enable
sudo reboot
```

**Error: "Port 5000 already in use"**
```bash
# Kill existing process
sudo lsof -ti:5000 | xargs kill -9
```

**Error: "Permission denied for GPIO"**
```bash
# Add user to gpio group
sudo usermod -a -G gpio $USER
sudo reboot
```

### iOS App Won't Connect

**"Cannot connect to server"**
- Ping Pi from terminal: `ping 192.168.100.148`
- Check Pi server logs for connection attempts
- Try accessing in Safari: `http://192.168.100.148:5000/`

**Build error in Xcode**
- See detailed instructions in `ios-app/XCODE_SETUP.md`

### Motors Not Responding

**Motors don't move at all**
- Check GPIO pin numbers in `pi-server/config.py`
- Test motors directly with test script:
  ```bash
  python3 car_controller.py
  ```
- Verify motor power supply is connected

**Motors move in wrong direction**
- Set inversion flags in config.py:
  ```python
  MOTOR_A_INVERTED = True
  MOTOR_B_INVERTED = True
  ```

## Performance Tips

### Reduce Video Latency

Edit `pi-server/config.py`:
```python
CAMERA_RESOLUTION = (320, 240)  # Lower resolution
CAMERA_FRAMERATE = 15           # Lower framerate
JPEG_QUALITY = 60               # Lower quality
```

### Improve Control Responsiveness

Edit `ios-app/.../CarControlViewModel.swift`:
```swift
private let commandInterval: TimeInterval = 0.03  // Faster updates
```

Edit `pi-server/config.py`:
```python
JOYSTICK_DEAD_ZONE = 0.1  # Smaller dead zone
```

## What's Next?

1. ✓ Read full documentation: `README.md`
2. ✓ Follow development checklist: `CHECKLIST.md`
3. ✓ Fine-tune motor control and camera settings
4. ✓ Set up systemd service for auto-start
5. ✓ Configure Tailscale for remote access

## Getting Help

1. Check troubleshooting in `README.md`
2. Review server logs on Pi
3. Check Xcode console for iOS errors
4. Test components individually using test scripts

## Testing Without Hardware

### Test Pi Server (No GPIO/Camera)

The server runs in simulation mode if hardware isn't available:
```bash
python3 server.py
# Warnings will show but server will start
```

### Test iOS App (No Pi)

- App will show "Disconnected"
- UI and joystick still work
- Test on simulator or device

---

**Have fun controlling your Pi Car!** 🚗

For detailed documentation, see `README.md`
