# macOS System Events Access: Code Signing & Entitlements Guide

**Date**: February 9, 2026  
**Context**: Menu bar apps requiring System Events automation without repeated permission prompts

---

## Executive Summary

**YES**, code signing with proper entitlements can eliminate repeated System Events permission prompts in macOS menu bar apps. The solution requires:

1. **Entitlement**: `com.apple.security.automation.apple-events`
2. **Usage Description**: `NSAppleEventsUsageDescription` in Info.plist
3. **Hardened Runtime**: Code signing with `--options=runtime`
4. **User Consent**: One-time TCC (Transparency, Consent, and Control) approval

Once properly configured and signed, the app will:
- Prompt for permission **once** on first launch
- Store the user's decision in the TCC database (`~/Library/Application Support/com.apple.TCC/TCC.db`)
- Never prompt again unless the app is modified or the TCC database is reset

---

## The Problem

macOS apps that send Apple Events (AppleScript commands) to control other applications face repeated permission prompts if not properly configured. This is especially problematic for:

- **Menu bar apps** that need to control System Events
- **Automation tools** that interact with other applications
- **Hardened runtime apps** (required for notarization and App Store distribution)

Without proper entitlements, macOS will:
- Block Apple Events in hardened runtime apps
- Show permission prompts on every launch or operation
- Prevent automation from working reliably

---

## The Solution: Three-Part Configuration

### 1. Entitlements File

Add the Apple Events entitlement to your `.entitlements` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for sending Apple Events -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Other entitlements as needed -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
</dict>
</plist>
```

**Purpose**: Declares to macOS that your app needs permission to send Apple Events to other applications.

### 2. Info.plist Usage Description

Add a user-facing explanation in your `Info.plist`:

```xml
<key>NSAppleEventsUsageDescription</key>
<string>DevEnvManager needs to control System Events to manage menu bar visibility and system automation.</string>
```

**Purpose**: This string appears in the permission prompt shown to users. Make it clear and specific about why your app needs this access.

**Best Practices**:
- Be specific about what you're controlling (e.g., "control System Events", "manage menu bar")
- Explain the benefit to the user (e.g., "to auto-hide the menu bar", "to manage development tools")
- Keep it concise (1-2 sentences)

### 3. Code Signing with Hardened Runtime

Sign your app with hardened runtime enabled:

```bash
# Remove extended attributes
xattr -cr "/path/to/YourApp.app"

# Sign with hardened runtime
codesign -f -s "Developer ID Application: Your Name (TEAM_ID)" \
  --options=runtime \
  --entitlements "YourApp.entitlements" \
  "/path/to/YourApp.app"

# Verify signature
codesign -vvv --deep --strict "/path/to/YourApp.app"
spctl --assess -vvv "/path/to/YourApp.app"
```

**Key Points**:
- `--options=runtime` enables hardened runtime (required for notarization)
- Without hardened runtime, entitlements are ignored
- The entitlements file must be specified during signing

---

## How TCC (Transparency, Consent, and Control) Works

### First Launch Flow

1. **App requests Apple Events access** (via AppleScript or NSAppleScript)
2. **macOS checks TCC database** for existing permission
3. **If no permission exists**, macOS shows a prompt:
   ```
   "DevEnvManager" wants to control "System Events".
   
   DevEnvManager needs to control System Events to manage 
   menu bar visibility and system automation.
   
   [Don't Allow]  [OK]
   ```
4. **User clicks OK** → Permission stored in TCC database
5. **Future launches** → No prompt, permission automatically granted

### TCC Database Location

- **User-level**: `~/Library/Application Support/com.apple.TCC/TCC.db`
- **System-level**: `/Library/Application Support/com.apple.TCC/TCC.db`

### When Prompts Reappear

Permission prompts will reappear if:

1. **App binary changes** (new build, different signature)
2. **Bundle identifier changes**
3. **TCC database is reset** (manually or via system update)
4. **User revokes permission** in System Settings → Privacy & Security → Automation

### Resetting TCC Permissions (for testing)

```bash
# Reset all TCC permissions for your app
tccutil reset AppleEvents com.yourcompany.yourapp

# Reset all TCC permissions (requires Full Disk Access)
tccutil reset All
```

---

## Implementation for Your Menu Bar Apps

### DevEnvManager (Swift/SwiftUI)

**Current State** (from `DevEnvManager/App/DevEnvManager.entitlements`):
```xml
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

**Recommended Changes**:

1. **Update `DevEnvManager/App/DevEnvManager.entitlements`**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Add this for System Events access -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Existing entitlements -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

2. **Update `DevEnvManager/App/Info.plist`**:
```xml
<!-- Add after NSPrincipalClass -->
<key>NSAppleEventsUsageDescription</key>
<string>DevEnvManager controls System Events to manage menu bar visibility and automate development environment tasks.</string>
```

3. **Update `DevEnvManager/project.yml`**:
```yaml
targets:
  DevEnvManager:
    # ... existing config ...
    info:
      properties:
        # ... existing properties ...
        NSAppleEventsUsageDescription: "DevEnvManager controls System Events to manage menu bar visibility and automate development environment tasks."
```

### DevEnvManager-Tauri (Rust + React)

**Current State**: No entitlements configured in `tauri.conf.json`

**Recommended Changes**:

1. **Create `DevEnvManager-Tauri/src-tauri/entitlements.plist`**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

2. **Update `DevEnvManager-Tauri/src-tauri/tauri.conf.json`**:
```json
{
  "bundle": {
    "macOS": {
      "minimumSystemVersion": "14.0",
      "entitlements": "entitlements.plist"
    }
  },
  "app": {
    "macOSPrivateApi": true,
    "security": {
      "csp": "default-src 'self'; style-src 'self' 'unsafe-inline'"
    }
  }
}
```

3. **Update `DevEnvManager-Tauri/src-tauri/Info.plist`** (or add to tauri.conf.json):
```json
{
  "bundle": {
    "macOS": {
      "minimumSystemVersion": "14.0",
      "entitlements": "entitlements.plist",
      "info": {
        "NSAppleEventsUsageDescription": "DevEnvManager controls System Events to manage menu bar visibility and automate development environment tasks."
      }
    }
  }
}
```

**Note**: Tauri 2 automatically handles code signing during the build process if you have a valid Developer ID certificate.

---

## Real-World Examples

### Example 1: NotchBar (Menu Bar App)

**Source**: [navtoj/NotchBar](https://github.com/navtoj/NotchBar/blob/main/src/Project.swift)

```swift
// Project.swift (XcodeGen)
infoPlist: [
    "NSAppleEventsUsageDescription": "Auto-Hide Menu Bar"
],
entitlements: [
    "com.apple.security.automation.apple-events": true
]
```

**Result**: One-time permission prompt, then persistent access.

### Example 2: VastWords (Launch at Login App)

**Source**: [ygsgdbd/VastWords](https://github.com/ygsgdbd/VastWords/blob/main/Project.swift)

```swift
infoPlist: [
    "NSAppleEventsUsageDescription": "需要此权限以管理开机启动设置。",
    "com.apple.security.automation.apple-events": true
]
```

**Use Case**: Managing launch at login requires System Events access.

### Example 3: SwiftAutoGUI (Automation Library)

**Source**: [NakaokaRei/SwiftAutoGUI](https://github.com/NakaokaRei/SwiftAutoGUI/blob/master/Sources/SwiftAutoGUI/AppleScript.swift)

Documentation explicitly states:

```swift
/// ### 2. Enable Automation Permission
/// In your app's `.entitlements` file:
/// ```xml
/// <key>com.apple.security.automation.apple-events</key>
/// <true/>
/// ```
///
/// ### 3. Add Usage Description
/// In your app's `Info.plist`:
/// ```xml
/// <key>NSAppleEventsUsageDescription</key>
/// <string>This app needs permission to control other applications.</string>
/// ```
```

---

## Testing Your Implementation

### 1. Build and Sign

```bash
# For Swift app
cd DevEnvManager
xcodegen generate
xcodebuild -scheme DevEnvManager -configuration Release build

# For Tauri app
cd DevEnvManager-Tauri
bun tauri build
```

### 2. Verify Entitlements

```bash
# Check entitlements are embedded
codesign -d --entitlements - "/path/to/YourApp.app"

# Should show:
# <key>com.apple.security.automation.apple-events</key>
# <true/>
```

### 3. Test Permission Flow

```bash
# Reset TCC for clean test
tccutil reset AppleEvents com.devenvmanager.app

# Launch app
open "/path/to/DevEnvManager.app"

# Expected: Permission prompt appears once
# Click "OK"
# Relaunch app → No prompt
```

### 4. Verify TCC Database

```bash
# Check TCC database (requires Full Disk Access)
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceAppleEvents';"

# Should show:
# kTCCServiceAppleEvents|com.devenvmanager.app|2
# (2 = allowed, 0 = denied, 1 = unknown)
```

---

## Common Pitfalls

### ❌ Entitlements Not Embedded

**Problem**: Entitlements file exists but not applied during code signing.

**Solution**: 
- For Xcode: Ensure `CODE_SIGN_ENTITLEMENTS` is set in build settings
- For manual signing: Use `--entitlements` flag with `codesign`
- For Tauri: Specify `entitlements` in `tauri.conf.json`

### ❌ Missing Usage Description

**Problem**: Entitlement present but no `NSAppleEventsUsageDescription` in Info.plist.

**Result**: Permission prompt shows generic message or app crashes.

**Solution**: Always add usage description to Info.plist.

### ❌ Unsigned or Ad-Hoc Signed

**Problem**: App is unsigned or signed with ad-hoc signature (`-`).

**Result**: TCC permissions not persistent across launches.

**Solution**: Use a valid Developer ID certificate or enable hardened runtime.

### ❌ Bundle ID Mismatch

**Problem**: TCC permission granted for one bundle ID, but app uses different ID.

**Result**: Permission prompt reappears.

**Solution**: Keep bundle ID consistent across builds.

---

## Security Considerations

### Principle of Least Privilege

Only request `com.apple.security.automation.apple-events` if your app genuinely needs to:
- Send AppleScript commands to other apps
- Control System Events
- Automate UI interactions

### Targeted Scripting (macOS 10.14+)

For more granular control, use `com.apple.security.scripting-targets`:

```xml
<key>com.apple.security.scripting-targets</key>
<dict>
    <key>com.apple.systemevents</key>
    <array>
        <string>com.apple.systemevents.keystroke</string>
    </array>
</dict>
```

This limits your app to specific Apple Events rather than blanket access.

### App Sandbox Compatibility

If your app is sandboxed (required for Mac App Store):

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.automation.apple-events</key>
<true/>
```

**Note**: App Review may require justification for automation entitlements.

---

## Distribution Considerations

### Developer ID Distribution

For apps distributed outside the Mac App Store:

1. **Sign with Developer ID certificate**
2. **Enable hardened runtime** (`--options=runtime`)
3. **Notarize with Apple** (required for macOS 10.15+)
4. **Staple notarization ticket** to app bundle

```bash
# Notarize
xcrun notarytool submit DevEnvManager.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple
xcrun stapler staple DevEnvManager.app
```

### Mac App Store Distribution

For Mac App Store apps:

1. **Use Mac App Store provisioning profile**
2. **Include entitlements in Xcode project**
3. **Provide justification in App Review notes**:
   ```
   NSAppleEventsUsageDescription: Required to control System Events 
   for menu bar visibility management, a core feature of this 
   development environment tool.
   ```

---

## Recommendations Summary

### For DevEnvManager (Swift)

| File | Action |
|------|--------|
| `App/DevEnvManager.entitlements` | Add `com.apple.security.automation.apple-events` |
| `App/Info.plist` | Add `NSAppleEventsUsageDescription` |
| `project.yml` | Add usage description to info properties |

### For DevEnvManager-Tauri (Rust + React)

| File | Action |
|------|--------|
| `src-tauri/entitlements.plist` | Create with `com.apple.security.automation.apple-events` |
| `src-tauri/tauri.conf.json` | Reference entitlements file, add usage description |

### For DevEnvManager-Iced (Rust + iced)

| File | Action |
|------|--------|
| `entitlements.plist` | Create with `com.apple.security.automation.apple-events` |
| `Info.plist` | Add `NSAppleEventsUsageDescription` |
| Build script | Sign with `codesign --entitlements` |

### For SwiftBar Plugin

**Note**: SwiftBar plugins run as scripts, not standalone apps. They inherit SwiftBar.app's permissions.

**Solution**: Ensure SwiftBar.app itself has Automation permission for System Events in System Settings → Privacy & Security → Automation.

---

## References

### Official Documentation

- [Apple Events Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events) - Apple Developer
- [NSAppleEventsUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription) - Apple Developer
- [TN3127: Inside Code Signing: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements) - Apple Technical Note

### Community Resources

- [Avoiding AppleScript Security and Privacy Requests](https://scriptingosx.com/2020/09/avoiding-applescript-security-and-privacy-requests/) - Scripting OS X (2020)
- [Sending AppleScript events from hardened MacOS or Electron app](https://ishaangandhi.medium.com/sending-applescript-events-from-electron-app-18dc1b7d7a51) - Ishaan Gandhi (2020)
- [macOS App Entitlements Guide: Part 3](https://medium.com/@info_4533/macos-app-entitlements-guide-499a87e28209) - Ralf Koch (January 2026)

### Real-World Examples

- [NotchBar](https://github.com/navtoj/NotchBar/blob/main/src/Project.swift) - Menu bar app with System Events access
- [VastWords](https://github.com/ygsgdbd/VastWords/blob/main/Project.swift) - Launch at login with automation
- [SwiftAutoGUI](https://github.com/NakaokaRei/SwiftAutoGUI/blob/master/Sources/SwiftAutoGUI/AppleScript.swift) - Automation library documentation

---

## Conclusion

**Code signing with proper entitlements DOES eliminate repeated System Events permission prompts.**

The key requirements are:

1. ✅ **Entitlement**: `com.apple.security.automation.apple-events`
2. ✅ **Usage Description**: `NSAppleEventsUsageDescription` in Info.plist
3. ✅ **Hardened Runtime**: Code signing with `--options=runtime`
4. ✅ **User Consent**: One-time TCC approval

Once configured, your menu bar app will:
- Prompt for permission **once** on first launch
- Store permission in TCC database
- Never prompt again (unless app is modified or TCC is reset)

This is the standard approach used by all professional macOS automation tools and menu bar apps.

---

**Generated**: February 9, 2026  
**For**: gemini-ai-macos-development-environment project  
**Menu Bar Apps**: DevEnvManager (Swift), DevEnvManager-Tauri (Rust + React), DevEnvManager-Iced (Rust + iced)
