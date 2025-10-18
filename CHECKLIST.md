# Pi Car Development Checklist

A step-by-step guide for building and testing the Raspberry Pi Car Controller system.

## Phase 1: Raspberry Pi Server Setup

### Hardware Preparation
- [ ] Raspberry Pi assembled with power supply
- [ ] Pi Camera module connected and secured
- [ ] Motor driver wired to GPIO pins
- [ ] Motors connected to motor driver
- [ ] Power supply for motors (separate from Pi if needed)
- [ ] Car chassis assembled and wheels attached
- [ ] Test motors manually (verify direction and power)

### System Configuration
- [ ] Raspberry Pi OS installed (Bullseye or newer)
- [ ] System updated: `sudo apt update && sudo apt upgrade -y`
- [ ] Camera enabled in raspi-config
- [ ] SSH enabled for remote access (recommended)
- [ ] Static IP configured or DHCP reservation set
- [ ] Verify camera works: `libcamera-hello --list-cameras`
- [ ] User added to gpio group: `sudo usermod -a -G gpio $USER`
- [ ] User added to video group: `sudo usermod -a -G video $USER`
- [ ] Reboot after group changes

### Python Environment
- [ ] Python 3.9+ installed (check: `python3 --version`)
- [ ] pip updated: `python3 -m pip install --upgrade pip`
- [ ] Virtual environment created (optional but recommended)
- [ ] Project cloned/copied to Pi: `/home/pi/picar/`

### Server Dependencies
- [ ] requirements.txt installed: `pip3 install -r requirements.txt`
- [ ] Flask installed and importable
- [ ] Flask-SocketIO installed
- [ ] picamera2 or libcamera available
- [ ] RPi.GPIO or gpiozero installed
- [ ] All imports successful (test with `python3 -c "import flask, flask_socketio, picamera2"`)

## Phase 2: Pi Server Implementation

### Configuration (config.py)
- [ ] GPIO pin numbers match your wiring
- [ ] Motor control logic matches your driver (normal/inverted)
- [ ] Camera resolution set (recommended: 640x480 for testing)
- [ ] Frame rate configured (10-30 fps recommended)
- [ ] Server host set to 0.0.0.0
- [ ] Server port set to 5000 (or your preference)
- [ ] Verify all settings before testing

### Motor Controller (car_controller.py)
- [ ] GPIO pins initialized correctly
- [ ] Motor forward function works
- [ ] Motor backward function works
- [ ] Motor stop function works
- [ ] Turn left function works
- [ ] Turn right function works
- [ ] Speed control implemented (if using PWM)
- [ ] Safe cleanup on shutdown
- [ ] Test each function individually with simple script

### Camera Streaming (camera_stream.py)
- [ ] Camera object created successfully
- [ ] MJPEG encoding working
- [ ] Frame generation function yields images
- [ ] Memory management efficient (no leaks)
- [ ] Test stream in browser: `http://PI_IP:5000/video`
- [ ] Verify acceptable latency (<500ms)
- [ ] Check CPU usage (should be <50%)

### Main Server (server.py)
- [ ] Flask app initializes
- [ ] SocketIO configured with CORS
- [ ] Root endpoint returns status
- [ ] /video endpoint streams MJPEG
- [ ] /health endpoint responds
- [ ] WebSocket connection handler working
- [ ] WebSocket message handler parsing JSON
- [ ] Control commands triggering motor functions
- [ ] Error handling for malformed messages
- [ ] Graceful shutdown implemented
- [ ] Server runs without errors: `python3 server.py`

### Server Testing
- [ ] Server starts without errors
- [ ] Camera initializes successfully
- [ ] GPIO initializes successfully
- [ ] Access root page in browser
- [ ] View video stream in browser
- [ ] Test WebSocket with online tool (websocket.org)
- [ ] Send test control commands via WebSocket
- [ ] Verify motors respond to commands
- [ ] Check server logs for errors
- [ ] Test connection recovery after disconnect
- [ ] Verify resource cleanup on shutdown

## Phase 3: iOS Application Development

### Xcode Project Setup
- [ ] Xcode installed (14.0+)
- [ ] New iOS App project created
- [ ] Project name: PiCarController
- [ ] Interface: SwiftUI
- [ ] Language: Swift
- [ ] Minimum deployment: iOS 15.0
- [ ] Bundle identifier set
- [ ] Project builds successfully (Cmd+B)

### Project Structure
- [ ] Models folder created
- [ ] Views folder created
- [ ] ViewModels folder created
- [ ] Files organized in folders
- [ ] Assets catalog configured

### WebSocket Client (Models/WebSocketClient.swift)
- [ ] WebSocketClient class created
- [ ] URLSessionWebSocketTask setup
- [ ] PI_SERVER_IP constant set correctly
- [ ] WebSocket URL constructed properly
- [ ] Connect function implemented
- [ ] Disconnect function implemented
- [ ] Send message function implemented
- [ ] Receive message handler implemented
- [ ] Connection state published (@Published)
- [ ] Error handling implemented
- [ ] Automatic reconnection logic
- [ ] Test connection to Pi server

### Joystick View (Views/JoystickView.swift)
- [ ] Custom SwiftUI view created
- [ ] Circular background rendered
- [ ] Draggable thumb/handle rendered
- [ ] Drag gesture handler implemented
- [ ] X/Y position calculated (-1 to 1 range)
- [ ] Spring-back animation on release
- [ ] Boundary constraints (keep thumb in circle)
- [ ] Visual feedback (shadow, colors)
- [ ] Callback closure for position updates
- [ ] Test in SwiftUI preview
- [ ] Test on device with touch input
- [ ] Adjust sensitivity if needed

### Video Stream View (Views/VideoStreamView.swift)
- [ ] Video player view created
- [ ] MJPEG URL constructed from server IP
- [ ] AsyncImage or custom MJPEG decoder used
- [ ] Loading indicator shown while buffering
- [ ] Error state displayed if stream fails
- [ ] Aspect ratio maintained
- [ ] Auto-refresh on connection restore
- [ ] Test with Pi server running
- [ ] Verify smooth playback
- [ ] Check for memory leaks

### Main View (Views/MainView.swift)
- [ ] Main content view created
- [ ] Video stream displayed at top
- [ ] Connection status indicator shown
- [ ] Joystick positioned at bottom
- [ ] Layout responsive to different screen sizes
- [ ] Status text updates with connection state
- [ ] Color coding (green=connected, red=disconnected)
- [ ] Safe area insets respected

### ViewModel (ViewModels/CarControlViewModel.swift)
- [ ] CarControlViewModel class created
- [ ] WebSocketClient instance managed
- [ ] Connection state exposed
- [ ] Joystick position handler implemented
- [ ] Position mapped to motor commands
- [ ] Dead zone implemented (center threshold)
- [ ] Command throttling (don't spam server)
- [ ] JSON encoding for commands
- [ ] Error handling and logging
- [ ] Auto-connect on view appear
- [ ] Disconnect on view disappear

### App Integration (PiCarControllerApp.swift & ContentView.swift)
- [ ] App entry point configured
- [ ] MainView integrated
- [ ] ViewModel injected correctly
- [ ] Navigation setup (if multi-screen)
- [ ] Build succeeds without warnings
- [ ] App launches on simulator
- [ ] App launches on real device

## Phase 4: Integration Testing

### Network Connectivity
- [ ] Pi and iOS device on same network
- [ ] Pi IP address reachable from iOS device
- [ ] Ping Pi from iOS (using network utility app)
- [ ] Test video URL in iOS Safari browser
- [ ] WebSocket connection successful
- [ ] Connection status updates correctly
- [ ] Reconnection works after network interruption

### Control Testing
- [ ] Joystick sends commands to server
- [ ] Server receives and logs commands
- [ ] Motors respond to joystick input
- [ ] Forward movement works
- [ ] Backward movement works
- [ ] Left turn works
- [ ] Right turn works
- [ ] Stop works (joystick at center)
- [ ] Response time acceptable (<100ms lag)
- [ ] Smooth control (no jittery movement)

### Video Streaming
- [ ] Video appears in iOS app
- [ ] Latency acceptable (<500ms)
- [ ] Frame rate smooth
- [ ] No freezing or stuttering
- [ ] Video quality acceptable
- [ ] Stream continues during movement
- [ ] Stream recovers after brief disconnect

### Error Handling
- [ ] App handles server offline gracefully
- [ ] App shows error when server unreachable
- [ ] Auto-reconnect works when server restarts
- [ ] Camera failure handled on Pi side
- [ ] GPIO errors logged and handled
- [ ] WebSocket disconnect detected
- [ ] Network errors don't crash app

## Phase 5: Calibration and Tuning

### Motor Calibration
- [ ] Verify forward/backward directions correct
- [ ] Verify left/right turn directions correct
- [ ] Adjust motor power if too fast/slow
- [ ] Balance left/right motor speeds
- [ ] Set appropriate speed limits
- [ ] Test on different surfaces
- [ ] Fine-tune turning radius

### Joystick Tuning
- [ ] Adjust dead zone size (center threshold)
- [ ] Set maximum input sensitivity
- [ ] Test diagonal movements
- [ ] Ensure smooth response curve
- [ ] Verify spring-back animation speed
- [ ] Test with different grip styles

### Video Optimization
- [ ] Adjust resolution for best quality/performance
- [ ] Tune frame rate for smooth playback
- [ ] Optimize JPEG quality setting
- [ ] Test bandwidth usage
- [ ] Verify acceptable CPU usage on Pi

### Performance Testing
- [ ] Server CPU usage under load
- [ ] Server memory usage stable
- [ ] Pi temperature under control
- [ ] iOS app battery usage acceptable
- [ ] Network bandwidth usage reasonable
- [ ] Extended operation (30+ minutes) stable

## Phase 6: Documentation and Polish

### Code Documentation
- [ ] All functions have docstrings/comments
- [ ] Complex logic explained
- [ ] Configuration options documented
- [ ] API contract clear
- [ ] Error codes documented

### User Documentation
- [ ] README.md complete and accurate
- [ ] Installation steps verified
- [ ] Usage instructions clear
- [ ] Troubleshooting section helpful
- [ ] API documentation complete
- [ ] Hardware diagram/photo included (optional)

### Code Quality
- [ ] No hardcoded credentials
- [ ] Configuration externalized
- [ ] Error messages helpful
- [ ] Logging appropriate (not too verbose)
- [ ] No debug print statements left in
- [ ] Code formatted consistently
- [ ] No unused imports or variables

### Testing Checklist
- [ ] Fresh Pi installation tested
- [ ] Fresh iOS build tested
- [ ] Setup instructions followed by another person
- [ ] Common errors reproduced and fixed
- [ ] Edge cases tested

## Phase 7: Future Enhancements (Optional)

### Tailscale Integration
- [ ] Tailscale installed on Pi
- [ ] Tailscale installed on iOS
- [ ] Server accessible via Tailscale IP
- [ ] App supports Tailscale address
- [ ] Test remote access outside local network

### Additional Features
- [ ] Speed control slider
- [ ] Battery voltage monitoring
- [ ] Distance sensors
- [ ] Obstacle detection
- [ ] Headlights control
- [ ] Horn/buzzer
- [ ] Multiple control modes
- [ ] Saved routes/automation

### iOS App Improvements
- [ ] Dark mode support
- [ ] iPad optimization
- [ ] Landscape orientation
- [ ] Settings screen
- [ ] Connection history
- [ ] Performance metrics display
- [ ] Haptic feedback

### Pi Server Improvements
- [ ] Systemd service for auto-start
- [ ] Configuration file (YAML/JSON)
- [ ] Web-based admin panel
- [ ] Logging to file
- [ ] Multiple camera support
- [ ] Recording capability
- [ ] RESTful API in addition to WebSocket

## Completion Criteria

The project is considered complete when:
- [ ] All Phase 1-4 items checked
- [ ] Pi server runs reliably for 30+ minutes
- [ ] iOS app controls car smoothly
- [ ] Video streams with acceptable quality
- [ ] Documentation allows new user to set up system
- [ ] No critical bugs or crashes
- [ ] Code committed to repository
- [ ] Demo video recorded (optional)

## Notes

Use this checklist to track your progress. Check off items as you complete them. Don't skip steps - each builds on the previous ones.

If you encounter issues:
1. Check the item's requirements
2. Review the README.md troubleshooting section
3. Check logs on both Pi and iOS
4. Test components individually before integration
5. Google error messages
6. Ask for help if stuck

Good luck building your Pi Car Controller!
