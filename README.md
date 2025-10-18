# Raspberry Pi Car Controller

A complete iOS application and Raspberry Pi server system for real-time remote control of a Pi-based car with live video streaming.

## Features

- Real-time video streaming from Pi Camera to iOS (MJPEG over HTTP)
- Bidirectional WebSocket communication for low-latency control
- Intuitive joystick interface for car control
- Custom GPIO motor control
- Connection status monitoring
- Configurable for local network or Tailscale VPN

## Architecture

```
┌─────────────────┐         WebSocket          ┌──────────────────┐
│   iOS Device    │◄──────── Commands ─────────►│  Raspberry Pi    │
│                 │                              │                  │
│  - Joystick UI  │         HTTP/MJPEG          │  - Flask Server  │
│  - Video Player │◄────── Video Stream ────────│  - Pi Camera     │
│  - WebSocket    │                              │  - GPIO Control  │
└─────────────────┘                              └──────────────────┘
```

## Project Structure

```
picar/
├── README.md                    # This file
├── CHECKLIST.md                 # Development checklist
├── pi-server/                   # Raspberry Pi server code
│   ├── requirements.txt         # Python dependencies
│   ├── server.py                # Main server (WebSocket + HTTP)
│   ├── car_controller.py        # GPIO motor control
│   ├── camera_stream.py         # MJPEG camera streaming
│   └── config.py                # Configuration settings
└── ios-app/                     # iOS application
    └── PiCarController/
        ├── PiCarController.xcodeproj
        └── PiCarController/
            ├── Models/          # WebSocket client, data models
            ├── Views/           # SwiftUI views (Joystick, Video, Main)
            └── ViewModels/      # Business logic
```

## Prerequisites

### Raspberry Pi
- Raspberry Pi 3/4/5 or Zero 2W
- Raspberry Pi Camera Module (v1, v2, or HQ)
- Motor driver (L298N, DRV8833, or similar)
- DC motors connected to GPIO pins
- Raspbian OS (Bullseye or newer)
- Python 3.9+

### iOS Device
- iPhone or iPad running iOS 15.0+
- Xcode 14.0+ (for development)
- Swift 5.7+

### Network
- Both devices on same local network (WiFi)
- Pi should have static IP or reserved DHCP address
- Default Pi IP: `192.168.100.148`

## Hardware Connections

### GPIO Pin Configuration (Modify in config.py as needed)

```
GPIO Pins (BCM numbering):
├── Motor A (Left)
│   ├── IN1: GPIO 17
│   └── IN2: GPIO 27
├── Motor B (Right)
│   ├── IN3: GPIO 23
│   └── IN4: GPIO 24
└── PWM (optional speed control)
    ├── ENA: GPIO 12
    └── ENB: GPIO 13
```

## Installation

### Raspberry Pi Setup

1. Update system and enable camera:
```bash
sudo apt update && sudo apt upgrade -y
sudo raspi-config
# Enable: Interface Options > Camera
# Enable: Interface Options > SSH (recommended)
```

2. Install Python dependencies:
```bash
cd ~/picar/pi-server
pip3 install -r requirements.txt
```

3. Configure GPIO pins:
```bash
# Edit config.py to match your motor driver wiring
nano config.py
```

4. Test camera:
```bash
libcamera-hello --list-cameras
```

### iOS App Setup

1. Open Xcode project:
```bash
cd ~/picar/ios-app/PiCarController
open PiCarController.xcodeproj
```

2. Update Pi IP address in code:
   - Open `PiCarController/Models/WebSocketClient.swift`
   - Change `PI_SERVER_IP` to your Raspberry Pi's IP address
   - Currently set to: `192.168.100.148`

3. Build and run:
   - Select your iOS device or simulator
   - Click Run (Cmd+R)

## Usage

### Starting the Pi Server

```bash
cd ~/picar/pi-server
python3 server.py
```

You should see:
```
[INFO] Starting Pi Car Server...
[INFO] Camera initialized successfully
[INFO] GPIO initialized successfully
[INFO] Server running on 0.0.0.0:5000
[INFO] Video stream: http://192.168.100.148:5000/video
[INFO] WebSocket endpoint: ws://192.168.100.148:5000/socket.io/
```

### Using the iOS App

1. Launch the app on your iOS device
2. App automatically connects to Pi server
3. Check connection status indicator (green = connected)
4. Use joystick to control car:
   - **Up**: Move forward
   - **Down**: Move backward
   - **Left**: Turn left
   - **Right**: Turn right
   - **Center**: Stop
5. Video stream displays automatically when connected

### Auto-start on Pi Boot (Optional)

Create systemd service:

```bash
sudo nano /etc/systemd/system/picar.service
```

Add:
```ini
[Unit]
Description=Pi Car Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/picar/pi-server
ExecStart=/usr/bin/python3 /home/pi/picar/pi-server/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable picar.service
sudo systemctl start picar.service
```

## API Documentation

### WebSocket Protocol

**Client to Server (Control Commands):**

```json
{
  "type": "control",
  "x": 0.5,
  "y": 0.8
}
```

- `x`: Horizontal axis (-1.0 to 1.0, left to right)
- `y`: Vertical axis (-1.0 to 1.0, backward to forward)

**Server to Client (Status Updates):**

```json
{
  "type": "status",
  "connected": true,
  "timestamp": 1234567890
}
```

### HTTP Endpoints

- `GET /` - Server status page
- `GET /video` - MJPEG video stream
- `GET /health` - Health check endpoint

## Configuration

### Server Configuration (pi-server/config.py)

- GPIO pin assignments
- Motor control parameters
- Camera resolution and framerate
- Server host and port
- WebSocket settings

### iOS Configuration

- Server IP address in `WebSocketClient.swift`
- Joystick sensitivity in `JoystickView.swift`
- Video player settings in `VideoStreamView.swift`

## Troubleshooting

### Pi Server Issues

**Camera not working:**
```bash
# Check camera is detected
libcamera-hello --list-cameras

# Check user permissions
sudo usermod -a -G video $USER
```

**GPIO permissions:**
```bash
sudo usermod -a -G gpio $USER
```

**Port already in use:**
```bash
# Find process using port 5000
sudo lsof -i :5000
# Kill if necessary
sudo kill -9 <PID>
```

### iOS App Issues

**Cannot connect to server:**
- Verify Pi server is running
- Check IP address matches in WebSocketClient.swift
- Ensure devices are on same network
- Try pinging Pi from iOS device (use network utility app)

**Video not displaying:**
- Check video URL is correct
- Verify MJPEG stream works in browser: `http://192.168.100.148:5000/video`
- Check network bandwidth

**Joystick not responding:**
- Check WebSocket connection status
- View Xcode console for error messages
- Verify server receives commands (check Pi logs)

## Future Enhancements

- [ ] Tailscale VPN integration for remote access
- [ ] Speed control slider
- [ ] Obstacle detection sensors
- [ ] Battery level monitoring
- [ ] Recording and playback of driving sessions
- [ ] Multiple car support
- [ ] Dark mode
- [ ] iPad landscape optimization

## Development

See [CHECKLIST.md](CHECKLIST.md) for detailed development and testing tasks.

## License

MIT License - Feel free to modify and use for your projects.

## Contributing

This is a personal project, but suggestions and improvements are welcome via issues and pull requests.

## Credits

- Built for Raspberry Pi hardware
- Uses Flask-SocketIO for WebSocket communication
- iOS app built with SwiftUI
- Camera streaming using picamera2/libcamera

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review CHECKLIST.md for setup steps
3. Check server logs on Pi
4. Check Xcode console for iOS errors
