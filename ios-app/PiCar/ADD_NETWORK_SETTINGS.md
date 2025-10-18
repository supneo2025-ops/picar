# Add Network Security Settings - Step by Step

## Quick Visual Guide

### Step 1: Open Info Tab
![Info Tab Location]
- Click **PiCar** project (blue icon)
- Select **PiCar** target (under TARGETS)
- Click **Info** tab (top bar)

### Step 2: Add App Transport Security
Click the **+** button next to any existing row:
- **Key name**: Type `App Transport Security Settings`
- Xcode will auto-suggest "App Transport Security Settings" - select it
- **Type**: Should automatically be "Dictionary"

### Step 3: Add Two Child Settings
Click the disclosure triangle (▸) to expand "App Transport Security Settings"
Click the **+** next to it to add child items:

**Child 1:**
- Key: `Allow Arbitrary Loads`
- Type: Boolean
- Value: ✅ YES (check the box)

**Child 2:**
- Key: `Allow Local Networking`
- Type: Boolean
- Value: ✅ YES (check the box)

### Final Result Should Look Like:

```
Custom iOS Target Properties
┌─────────────────────────────────────────────┬───────────┐
│ Key                                         │ Type      │ Value
├─────────────────────────────────────────────┼───────────┤
│ ▼ App Transport Security Settings          │ Dictionary│ (2 items)
│   ▸ Allow Arbitrary Loads                   │ Boolean   │ YES
│   ▸ Allow Local Networking                  │ Boolean   │ YES
└─────────────────────────────────────────────┴───────────┘
```

## Detailed Instructions

### In Xcode:

1. **Select Project**
   - In Project Navigator (left sidebar)
   - Click on **PiCar** (blue project icon at top)

2. **Select Target**
   - In the main editor area, under "TARGETS"
   - Click on **PiCar** (not the PROJECT above it)

3. **Open Info Tab**
   - At the top: General | Signing & Capabilities | Resource Tags | **Info** | Build Settings...
   - Click **Info**

4. **Find "Custom iOS Target Properties" section**
   - You'll see existing properties like:
     - "Application Scene Manifest"
     - "Launch Screen"

5. **Add New Property**
   - Hover over any row
   - Click the **+** button that appears on the right
   - Start typing: `App Transport`
   - Xcode will auto-suggest: "App Transport Security Settings"
   - Select it (or continue typing the full name)
   - Type should automatically be "Dictionary"

6. **Expand the Dictionary**
   - Click the disclosure triangle (▸) next to "App Transport Security Settings"
   - It will rotate down (▾) showing it's expanded

7. **Add First Child Setting**
   - Click the **+** next to "App Transport Security Settings"
   - Type: `Allow Arbitrary Loads`
   - Or start typing "Allow" and select from autocomplete
   - Type: Boolean (automatic)
   - Value: Click checkbox to set to YES

8. **Add Second Child Setting**
   - Click the **+** again next to "App Transport Security Settings"
   - Type: `Allow Local Networking`
   - Type: Boolean (automatic)
   - Value: Click checkbox to set to YES

9. **Verify**
   - You should now see:
     ```
     ▾ App Transport Security Settings    Dictionary  (2 items)
       ▸ Allow Arbitrary Loads             Boolean     YES
       ▸ Allow Local Networking            Boolean     YES
     ```

10. **Save**
    - Cmd+S or File > Save
    - Settings are saved automatically

## Alternative Method: Edit Info.plist Source

If the visual editor is confusing, you can edit the raw plist:

1. Right-click on "Custom iOS Target Properties" header
2. Select "Show Raw Keys/Values"
3. Add these entries:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## What These Settings Mean

**App Transport Security Settings (NSAppTransportSecurity)**
- Controls network security for the app
- iOS blocks non-HTTPS by default

**Allow Arbitrary Loads (NSAllowsArbitraryLoads)**
- Allows connections to HTTP (non-HTTPS) servers
- Needed because Raspberry Pi server uses HTTP

**Allow Local Networking (NSAllowsLocalNetworking)**
- Specifically allows HTTP to local network addresses
- More secure than Allow Arbitrary Loads alone
- Perfect for connecting to Pi on local WiFi

## After Adding Settings

1. **Clean Build Folder**
   - Product > Clean Build Folder
   - Or: Cmd+Shift+K

2. **Build**
   - Product > Build
   - Or: Cmd+B
   - Should succeed! ✅

3. **Run**
   - Product > Run
   - Or: Cmd+R

## Troubleshooting

**"I don't see the Info tab"**
- Make sure you selected the TARGET (not PROJECT)
- Should be under "TARGETS" section, not "PROJECT"

**"Can't add new properties"**
- Make sure you're in the "Custom iOS Target Properties" section
- Should be at the top of the Info tab
- Not in "URL Types" or other sections below

**"Settings aren't saving"**
- Close and reopen Xcode
- Check the Info.plist file in project
- Should be auto-generated in DerivedData folder

**"Still getting network errors"**
- Verify settings were added correctly
- Clean build folder and rebuild
- Check capitalization is exact

## Verification

To verify settings are working:

1. Build and run app
2. Try to connect to server
3. Check console logs
4. Should NOT see errors like:
   - "App Transport Security has blocked a cleartext HTTP"
   - "NSURLErrorDomain Code=-1022"

If you see those errors, settings weren't added correctly.

---

**Time required:** 1-2 minutes
**Difficulty:** Easy
**After this:** Build should succeed and network connections should work!
