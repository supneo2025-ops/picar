# Xcode Project Setup - Complete! ✅

Your PiCar Xcode project is now correctly configured and ready to build.

## ✅ What's Been Set Up

### Project Structure
```
PiCar/
├── PiCar.xcodeproj          # Xcode project file
└── PiCar/                   # Source code
    ├── PiCarApp.swift       # ✅ Updated - App entry point
    ├── ContentView.swift    # ✅ Updated - Root view with ViewModel
    ├── Info.plist           # ✅ Added - Network permissions
    ├── Models/
    │   └── WebSocketClient.swift      # ✅ WebSocket connection
    ├── Views/
    │   ├── JoystickView.swift         # ✅ Joystick controller
    │   ├── VideoStreamView.swift      # ✅ Video player
    │   └── MainView.swift             # ✅ Main UI
    └── ViewModels/
        └── CarControlViewModel.swift  # ✅ Control logic
```

### Files Updated
- ✅ `PiCarApp.swift` - Updated with proper comments
- ✅ `ContentView.swift` - Now uses CarControlViewModel and MainView
- ✅ `Info.plist` - Added with network security settings

### Files Already Correct
- ✅ All Models, Views, and ViewModels copied correctly
- ✅ WebSocketClient with Pi server configuration
- ✅ Custom Joystick implementation
- ✅ MJPEG video streaming view
- ✅ Main control interface

## 🚀 Next Steps

### Step 1: Open Project in Xcode
```bash
cd ~/PycharmProjects/picar/ios-app/PiCar
open PiCar.xcodeproj
```

### Step 2: Configure Signing
1. Select **PiCar** project in Navigator
2. Select **PiCar** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** from dropdown
5. Xcode will automatically create a provisioning profile

### Step 3: Update Server IP Address

**Important:** Before building, update the Raspberry Pi server IP address.

**File to edit:** `Models/WebSocketClient.swift` (line 15)

```swift
// Current value:
static let PI_SERVER_IP = "192.168.100.148"

// Update to your Pi's actual IP address
// Or use your Mac's IP for local testing (see below)
```

#### For Testing on macOS

If running the Python server on your Mac (see MACOS_TESTING.md):

**For iOS Simulator:**
```swift
static let PI_SERVER_IP = "localhost"
// or
static let PI_SERVER_IP = "127.0.0.1"
```

**For iOS Physical Device:**
```bash
# Find your Mac's IP address:
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
```

Then update:
```swift
static let PI_SERVER_IP = "192.168.1.100"  // Your Mac's actual IP
```

### Step 4: Build and Run

**For Simulator:**
1. Select target: **iPhone 15 Pro** (or any simulator)
2. Click **Run** ▶️ or press `Cmd+R`

**For Physical Device:**
1. Connect iPhone/iPad via USB
2. Select your device in target dropdown
3. Click **Run** ▶️ or press `Cmd+R`
4. First time: You may need to trust the developer certificate on device
   - Settings > General > VPN & Device Management > Trust

### Step 5: Verify Build

The project should build successfully. Watch for:

✅ **Build Succeeded** message
✅ App launches on simulator/device
✅ No compile errors in Issue Navigator

If you see errors, see Troubleshooting section below.

## 🧪 Testing

### Test 1: UI Test (No Server Required)
1. Run app on simulator
2. Verify UI displays:
   - ✅ Pi Car Controller header
   - ✅ Connection status (will show "Disconnected" - that's OK)
   - ✅ Video placeholder (black screen)
   - ✅ Joystick at bottom
   - ✅ Position indicators

3. Test joystick:
   - ✅ Drag in all directions
   - ✅ Watch position values update
   - ✅ Release - should spring back to center

### Test 2: Server Connection Test
1. Start Pi server (or macOS test server):
   ```bash
   cd ~/PycharmProjects/picar
   ./test_macos.sh
   ```

2. Update IP in WebSocketClient.swift (see Step 3)

3. Rebuild and run app

4. Verify:
   - ✅ Status shows "Connected" (green dot)
   - ✅ No error messages
   - ✅ Server terminal shows "Client connected"

5. Test control:
   - ✅ Move joystick
   - ✅ Server terminal logs commands:
     ```
     [DEBUG] Joystick: (0.50, 0.80) -> Left: 1@76%, Right: 1@97%
     ```

### Test 3: Video Stream (Requires Real Pi Camera)
1. Connect to real Raspberry Pi with camera
2. Verify video appears in app
3. Check for smooth playback

## 🔧 Troubleshooting

### Build Errors

**Error: "Cannot find type 'MainView'"**
- **Fix:** Make sure all files in Xcode Project Navigator have target membership
- Check: Select file > File Inspector > Target Membership > ✓ PiCar

**Error: "No such module 'Combine'"**
- **Fix:** Clean build folder
  - Product > Clean Build Folder (Cmd+Shift+K)
  - Then rebuild (Cmd+B)

**Error: "Multiple commands produce Info.plist"**
- **Fix:** Remove auto-generated Info.plist
  - Select PiCar target > Build Settings
  - Search "Info.plist File"
  - Delete the value (keep our custom Info.plist)

**Error: Signing issues**
- **Fix:** Configure development team
  - Select project > Signing & Capabilities
  - Choose your Apple ID team
  - Or use "Automatically manage signing"

### Runtime Errors

**App crashes on launch**
- Check Xcode console for error message
- Common issue: Missing EnvironmentObject
- **Fix:** Verify ContentView creates CarControlViewModel

**"Cannot connect to server"**
- Verify server is running
- Check IP address in WebSocketClient.swift
- Ping server: `ping 192.168.100.148`
- Test in browser: `http://192.168.100.148:5000`

**Video doesn't load**
- Normal if using macOS test server (no camera)
- Should show "Camera Unavailable" placeholder
- For real camera, verify:
  - Pi camera is working
  - Server shows camera initialized
  - Test stream in browser

### Xcode Issues

**Project Navigator shows wrong structure**
- Try: Close Xcode and reopen project
- File > Close Project
- Open PiCar.xcodeproj again

**Autocomplete not working**
- Clean build folder (Cmd+Shift+K)
- Delete Derived Data:
  - Xcode > Preferences > Locations
  - Click arrow next to Derived Data path
  - Delete PiCar folder
- Restart Xcode

## 📱 Deployment to Device

### Requirements
- Apple ID (free or paid developer account)
- iPhone/iPad with iOS 15.0+
- USB cable

### Steps
1. Connect device via USB
2. Trust computer on device (first time)
3. In Xcode:
   - Select your device in target dropdown
   - Signing & Capabilities > Select Team
   - Click Run

4. On device (first time):
   - Settings > General > VPN & Device Management
   - Trust developer app

### Common Device Issues

**"Untrusted Developer"**
- Settings > General > Device Management
- Tap on developer name
- Trust

**"Unable to install"**
- Free Apple ID: Limited to 3 apps
- Delete an old app and retry
- Or use paid developer account

**Device not showing in Xcode**
- Unlock device
- Trust this computer (dialog on device)
- Reconnect USB cable
- Restart Xcode if needed

## ✅ Project Checklist

Before running on real hardware:

- [ ] All files present in Xcode Project Navigator
- [ ] No build errors or warnings
- [ ] App builds and runs on simulator
- [ ] Joystick UI works
- [ ] WebSocketClient IP address updated
- [ ] Server connection tested (with test server)
- [ ] Info.plist allows local networking
- [ ] Signing configured for device deployment

## 📚 Additional Resources

- **MACOS_TESTING.md** - Test without Raspberry Pi
- **QUICKSTART.md** - Full deployment guide
- **README.md** - Complete documentation
- **CHECKLIST.md** - Comprehensive testing

## 🎯 Ready to Test!

Your project is now ready. Start with:

1. **Quick UI test:** Run on simulator (no server needed)
2. **Network test:** Use macOS test server (`./test_macos.sh`)
3. **Full test:** Deploy to Raspberry Pi (see QUICKSTART.md)

---

**Status:** ✅ Setup Complete - Ready to Build!

For local testing, run: `./test_macos.sh` in the project root directory.
