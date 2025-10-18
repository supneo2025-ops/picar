# Xcode Project Setup Guide

This guide will help you create the Xcode project and integrate all the Swift files.

## Step 1: Create New Xcode Project

1. Open Xcode
2. Select **File > New > Project**
3. Choose **iOS > App**
4. Configure the project:
   - Product Name: `PiCarController`
   - Team: Your development team
   - Organization Identifier: `com.yourname` (or your preference)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Include Tests: Optional
5. Save location: Choose the `ios-app/` directory
6. Click **Create**

## Step 2: Add Source Files to Project

After creating the project, you need to add all the Swift files to your Xcode project:

### Method 1: Drag and Drop (Recommended)

1. In Finder, navigate to `picar/ios-app/PiCarController/PiCarController/`
2. You'll see these folders with files:
   - `Models/WebSocketClient.swift`
   - `Views/JoystickView.swift`
   - `Views/VideoStreamView.swift`
   - `Views/MainView.swift`
   - `ViewModels/CarControlViewModel.swift`
   - `PiCarControllerApp.swift`
   - `ContentView.swift`
   - `Info.plist`

3. In Xcode, select the `PiCarController` folder in the Project Navigator
4. Drag the `Models`, `Views`, and `ViewModels` folders from Finder into Xcode
5. In the dialog that appears:
   - ✓ **Copy items if needed**
   - ✓ **Create groups**
   - ✓ Add to target: PiCarController
6. Click **Finish**

7. Replace the default `PiCarControllerApp.swift` and `ContentView.swift` with the provided versions
8. Replace the default `Info.plist` with the provided version

### Method 2: Manual File Creation

If drag-and-drop doesn't work, create each file manually:

1. Right-click on `PiCarController` folder in Xcode
2. Select **New File**
3. Choose **Swift File**
4. Name it appropriately (e.g., `WebSocketClient`)
5. Copy the content from the provided file
6. Paste into the newly created file
7. Repeat for all files

## Step 3: Configure Info.plist

The provided `Info.plist` already includes necessary configuration, but verify:

1. Select `Info.plist` in Project Navigator
2. Verify these keys exist:
   - **App Transport Security Settings**
     - Allow Arbitrary Loads: YES
     - Allow Local Networking: YES

These settings allow the app to connect to your Raspberry Pi over HTTP/WebSocket on the local network.

## Step 4: Update Server IP Address

1. Open `Models/WebSocketClient.swift`
2. Find the line:
   ```swift
   static let PI_SERVER_IP = "192.168.100.148"
   ```
3. Update to your Raspberry Pi's actual IP address if different

## Step 5: Project Settings

1. Select the project in Project Navigator
2. Select the `PiCarController` target
3. Under **Signing & Capabilities**:
   - Select your development team
   - Verify bundle identifier is unique
4. Under **Deployment Info**:
   - iPhone Orientation: Portrait
   - Deployment Target: iOS 15.0 or later

## Step 6: Build and Run

1. Select your target device (iPhone or simulator)
2. Click the **Run** button (▶) or press `Cmd+R`
3. The app should build successfully

## Troubleshooting

### Build Errors

**Error: "Cannot find type 'MainView' in scope"**
- Solution: Make sure all Swift files are added to the project target
- Check: Select each file, verify in File Inspector that `PiCarController` target is checked

**Error: "Missing Info.plist"**
- Solution: Make sure Info.plist is in the project and added to target
- Or create it: Right-click project > New File > Property List

**Error: Module 'Combine' not found**
- Solution: This is a system framework. Should auto-import. Try cleaning build folder (Cmd+Shift+K)

### Runtime Errors

**App crashes on launch**
- Check console for error messages
- Verify all @Published properties are initialized
- Make sure EnvironmentObject is properly injected

**Cannot connect to server**
- Verify Pi server is running
- Check IP address in WebSocketClient.swift
- Verify iPhone and Pi are on same network
- Check firewall settings on Pi

**Video doesn't load**
- Test video URL in Safari: `http://192.168.100.148:5000/video`
- Verify Info.plist allows local networking
- Check camera is working on Pi

## Project Structure

Your final project structure should look like:

```
PiCarController/
├── PiCarController.xcodeproj
└── PiCarController/
    ├── PiCarControllerApp.swift      # App entry point
    ├── ContentView.swift              # Root view
    ├── Info.plist                     # App configuration
    ├── Models/
    │   └── WebSocketClient.swift      # WebSocket connection
    ├── Views/
    │   ├── MainView.swift             # Main control interface
    │   ├── JoystickView.swift         # Joystick controller
    │   └── VideoStreamView.swift      # MJPEG video player
    ├── ViewModels/
    │   └── CarControlViewModel.swift  # Control logic
    └── Assets.xcassets/               # App assets
```

## Next Steps

1. ✓ Build the project
2. ✓ Run on simulator to test UI
3. ✓ Deploy to physical iPhone for testing
4. ✓ Connect to Pi server and test control

## Additional Configuration (Optional)

### App Icon

1. Create 1024x1024 app icon
2. Drag into `Assets.xcassets/AppIcon`

### Dark Mode

The app already supports dark mode with custom colors.

### iPad Support

To optimize for iPad:
1. Add iPad orientation support in project settings
2. Adjust layout constraints in views for larger screens

### Landscape Mode

To support landscape:
1. Project Settings > Deployment Info
2. Check both Portrait and Landscape orientations
3. Test and adjust UI layouts accordingly
