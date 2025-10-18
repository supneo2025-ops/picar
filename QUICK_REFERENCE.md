# Pi Car - Quick Reference Card

## 🚀 Current Status

- ✅ **Server**: Deployed and running on Pi
- ✅ **Location**: `pi@pi_local` (192.168.100.148)
- ✅ **Tmux Session**: `car_backend`
- ⚠️ **Camera**: Needs cable reseating
- ℹ️ **Motors**: Not attached (simulation mode)

## 📱 iOS App - Next Steps

1. **In Xcode**: Add network security settings
   - Target → Info tab → Add "App Transport Security Settings"
   - Add "Allow Arbitrary Loads" = YES
   - Add "Allow Local Networking" = YES
   - See: `BUILD_ERROR_FIXED.txt`

2. **IP Already Correct**: `192.168.100.148` in `WebSocketClient.swift`

3. **Build**: Cmd+Shift+K (clean) → Cmd+R (run)

## 🎮 Server Management

```bash
# View logs
./view_pi_logs.sh

# Restart server
./restart_pi_server.sh

# Stop server
./stop_pi_server.sh

# Redeploy after changes
./deploy_to_pi.sh && ./restart_pi_server.sh
```

## 🔧 Fix Camera

```bash
# Test camera
ssh pi@pi_local 'libcamera-hello --list-cameras'

# If timeout: Power off, reseat cable, power on
ssh pi@pi_local 'sudo shutdown -h now'
# ...reseat cable...
./restart_pi_server.sh
```

## 🌐 Test Endpoints

- Status: http://192.168.100.148:5000/
- Health: http://192.168.100.148:5000/health
- Video: http://192.168.100.148:5000/video

## 📚 Documentation

- `DEPLOYMENT_SUCCESS.txt` - Current status
- `PI_DEPLOYMENT_GUIDE.md` - Complete Pi guide
- `BUILD_ERROR_FIXED.txt` - iOS Xcode fix
- `MACOS_TESTING.md` - Local testing

## 🆘 Troubleshooting

**iOS can't connect**: Check network settings in Xcode
**Camera not working**: Reseat ribbon cable
**Server not responding**: `./restart_pi_server.sh`
**Need to update code**: `./deploy_to_pi.sh`

---

**Ready to test!** Build iOS app and connect to `192.168.100.148`
