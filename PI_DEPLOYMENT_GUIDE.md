# Raspberry Pi Deployment Guide

Quick guide for deploying and managing Pi Car server on your Raspberry Pi.

## Prerequisites

- Raspberry Pi accessible at: `pi_local`
- SSH access: `ssh pi@pi_local`
- Camera module connected (motors optional)

## Quick Deployment (One Command)

```bash
cd ~/PycharmProjects/picar
./deploy_to_pi.sh
```

This will:
1. ✅ Test connection to Pi
2. ✅ Create directory structure
3. ✅ Copy all server files via rsync
4. ✅ Install Python dependencies
5. ✅ Create tmux startup script

Takes ~2 minutes depending on network speed.

## Server Management Scripts

All scripts are in the project root directory:

### Deploy Server
```bash
./deploy_to_pi.sh
```
Copies files and installs dependencies. Run this after code changes.

### Start Server
```bash
./start_pi_server.sh
```
Starts server in tmux session named `car_backend`.

### View Server Logs
```bash
./view_pi_logs.sh
```
Attaches to tmux session to see live logs.
- Press **Ctrl+B then D** to detach (leave server running)
- Press **Ctrl+C** to stop server

### Stop Server
```bash
./stop_pi_server.sh
```
Stops the tmux session and server.

### Restart Server
```bash
./restart_pi_server.sh
```
Stops and starts the server (useful after config changes).

## Manual Commands

If you prefer manual control:

### SSH to Pi
```bash
ssh pi@pi_local
```

### Start Server Manually
```bash
ssh pi@pi_local '/home/pi/picar/start_server.sh'
```

### View Logs
```bash
ssh pi@pi_local 'tmux attach -t car_backend'
```

### Stop Server
```bash
ssh pi@pi_local 'tmux kill-session -t car_backend'
```

### Check if Server is Running
```bash
ssh pi@pi_local 'tmux ls'
```
Should show `car_backend` if running.

## Testing

### Test Camera Stream

In your browser:
```
http://pi_local:5000/video
```

You should see live camera feed.

### Test Server Status

```
http://pi_local:5000/
```

Shows server status page with camera and motor status.

### Test Health Endpoint

```bash
curl http://pi_local:5000/health
```

Returns JSON:
```json
{
  "status": "ok",
  "camera": true,
  "controller": false
}
```

Note: `controller: false` is expected since motors aren't attached.

### Test from iOS App

1. Update `WebSocketClient.swift`:
   ```swift
   static let PI_SERVER_IP = "pi_local"
   // or use actual IP: ifconfig on Pi shows IP address
   ```

2. Build and run iOS app

3. Should see:
   - ✅ "Connected" status (green)
   - ✅ Live camera video
   - ✅ Joystick functional (sends commands but motors won't move)

## Expected Behavior (Camera Only)

### What Works ✅
- ✅ Server starts successfully
- ✅ Camera initializes and streams video
- ✅ WebSocket connections accepted
- ✅ Control commands received and logged
- ✅ HTTP endpoints respond

### What's Expected ⚠️
- ⚠️ "GPIO not available - controller in simulation mode" (motors not attached)
- ⚠️ Motor commands logged but no physical movement

### Server Logs
```
[INFO] Starting Pi Car Server...
[INFO] ✓ Camera initialized successfully
[INFO] ✗ GPIO not available - controller in simulation mode
[INFO] Server running on 0.0.0.0:5000
[INFO] Video stream: http://pi_local:5000/video
```

This is correct! Camera works, motors in simulation mode.

## Common Issues

### Camera Not Working

**Check camera is enabled:**
```bash
ssh pi@pi_local 'libcamera-hello --list-cameras'
```

**Enable if needed:**
```bash
ssh pi@pi_local 'sudo raspi-config'
# Interface Options > Camera > Enable
```

**Check permissions:**
```bash
ssh pi@pi_local 'groups'
# Should include 'video'
```

**Add to video group:**
```bash
ssh pi@pi_local 'sudo usermod -a -G video pi'
# Then reboot Pi
```

### Cannot Connect to Pi

**Test connection:**
```bash
ping pi_local
```

**Try IP address instead:**
```bash
# Find Pi's IP
ssh pi@pi_local 'hostname -I'

# Update scripts to use IP instead of pi_local
```

**Check SSH:**
```bash
ssh -v pi@pi_local
```

### Server Won't Start

**Check Python version:**
```bash
ssh pi@pi_local 'python3 --version'
```
Should be Python 3.9+

**Check dependencies:**
```bash
ssh pi@pi_local 'cd /home/pi/picar/pi-server && pip3 list'
```

**Check for errors:**
```bash
ssh pi@pi_local 'cd /home/pi/picar/pi-server && python3 server.py'
```

### Port 5000 Already in Use

**Find process:**
```bash
ssh pi@pi_local 'sudo lsof -i :5000'
```

**Kill process:**
```bash
ssh pi@pi_local 'sudo lsof -ti:5000 | xargs kill -9'
```

## File Locations on Pi

```
/home/pi/picar/
├── pi-server/
│   ├── server.py              # Main server
│   ├── config.py              # Configuration
│   ├── car_controller.py      # Motor control
│   ├── camera_stream.py       # Camera streaming
│   ├── requirements.txt       # Dependencies
│   └── venv/                  # Virtual env (if created)
└── start_server.sh            # Tmux startup script
```

## Tmux Quick Reference

### Attach to Session
```bash
tmux attach -t car_backend
```

### Detach (Leave Running)
**Inside tmux:** Press `Ctrl+B` then `D`

### List Sessions
```bash
tmux ls
```

### Kill Session
```bash
tmux kill-session -t car_backend
```

### Scroll in Tmux
1. Press `Ctrl+B` then `[`
2. Use arrow keys or Page Up/Down
3. Press `q` to exit scroll mode

## Updating Code

After making changes to server code:

```bash
# 1. Deploy changes
./deploy_to_pi.sh

# 2. Restart server
./restart_pi_server.sh

# 3. Check logs
./view_pi_logs.sh
```

## Auto-Start on Pi Boot (Optional)

To start server automatically when Pi boots:

```bash
# SSH to Pi
ssh pi@pi_local

# Create systemd service
sudo nano /etc/systemd/system/picar.service
```

Paste:
```ini
[Unit]
Description=Pi Car Server
After=network.target

[Service]
Type=forking
User=pi
WorkingDirectory=/home/pi/picar
ExecStart=/usr/bin/tmux new-session -d -s car_backend 'cd /home/pi/picar/pi-server && python3 server.py'
ExecStop=/usr/bin/tmux kill-session -t car_backend
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable picar.service
sudo systemctl start picar.service
```

Check status:
```bash
sudo systemctl status picar.service
```

## Performance Monitoring

### Check CPU/Memory Usage
```bash
ssh pi@pi_local 'top -bn1 | head -20'
```

### Check Pi Temperature
```bash
ssh pi@pi_local 'vcgencmd measure_temp'
```

### Monitor Server Resources
```bash
ssh pi@pi_local 'ps aux | grep python3'
```

## Development Workflow

1. **Edit code locally** (on Mac)
2. **Deploy to Pi**: `./deploy_to_pi.sh`
3. **Restart server**: `./restart_pi_server.sh`
4. **Test in browser or iOS app**
5. **View logs if needed**: `./view_pi_logs.sh`

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Camera not working | `sudo raspi-config` → Enable camera |
| Can't connect to pi_local | Use IP address instead |
| Port 5000 in use | `./stop_pi_server.sh` first |
| Code changes not taking effect | `./deploy_to_pi.sh` then `./restart_pi_server.sh` |
| Server crashes | Check logs: `./view_pi_logs.sh` |

---

**Ready to deploy!** Run: `./deploy_to_pi.sh`
