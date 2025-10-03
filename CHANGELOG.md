# Changelog

## Version 3.0 (Latest)

### 🎯 Major Changes
- **Simplified Custom Names**: Removed hash symbol requirement - custom names are now plain strings
- **Cleaner Format**: Everything after package/UID is treated as the custom name
- **Default Sort Changed**: Now defaults to `sort_by=custom` instead of `sort_by=name`
- **More Intuitive**: Natural format without comment syntax

### 📝 Format Changes
```
# Old v2.0 format:
com.spotify.music # Spotify Music

# New v3.0 format:
com.spotify.music Spotify Music
```

### 🔧 Technical Improvements
- Simplified parsing logic for custom names
- No comment removal needed for names
- Cleaner file output without hash symbols
- Maintains all v2.0 robustness features

## Version 2.0

### 🎯 Major Features
- **Parallel Execution Handling**: Properly manages AFWall+'s dual script instances
- **Automatic Sorting**: Sort apps by name, package, or UID
- **Enhanced Lock Management**: PID-based validation with stale lock cleanup
- **Improved Robustness**: UID validation, safe delimiter, better error handling

### 🔧 Technical Improvements
- Added `sort_by` configuration option (name/package/uid)
- Changed delimiter from `|` to `§` for safety
- Added UID validation before applying iptables rules
- Implemented PID tracking for lock ownership
- Added stale lock cleanup (5-minute timeout)
- Enhanced pm command error checking
- Auto-generates comments from package names
- Added timestamp to auto-generated file headers

### 📚 Documentation Updates
- Emphasized need to tap Apply after editing uid.txt
- Explained AFWall+'s parallel script execution
- Added troubleshooting for common issues
- Improved installation instructions
- Added security considerations section

### 🐛 Bug Fixes
- Fixed potential race condition with parallel instances
- Resolved parsing issues with special characters
- Fixed lock cleanup on abnormal termination
- Corrected UID extraction from pm output

## Version 1.0

### Initial Release
- Basic Work Profile support (user 10)
- Dynamic UID/package name resolution
- Debug and recalculate modes
- File locking mechanism
- IPv4 and IPv6 support
- Configuration file management

---

## Upgrade Instructions

### From v2.0 to v3.0

1. **Backup current config**:
   ```bash
   adb pull /sdcard/afw/uid.txt uid_backup.txt
   ```

2. **Update script**:
   ```bash
   # Method 1: Use installer
   ./install.sh  # or install.bat on Windows
   
   # Method 2: Manual with root
   adb push afw.sh /sdcard/afw/afw.sh.tmp
   adb shell "su -c 'cp /sdcard/afw/afw.sh.tmp /data/local/afw/afw.sh'"
   adb shell "su -c 'chmod 755 /data/local/afw/afw.sh'"
   adb shell "rm /sdcard/afw/afw.sh.tmp"
   ```

3. **Update config file format**:
   - Change `sort_by=name` to `sort_by=custom` (line 3)
   - Remove `#` symbols from custom names
   - Example: `com.spotify.music # Spotify` becomes `com.spotify.music Spotify`

4. **Apply changes**:
   - Open AFWall+ and tap Apply

5. **Verify**:
   ```bash
   adb shell "logcat -d | grep afwall_custom"
   ```

### From v1.0 to v3.0

1. **Backup current config**:
   ```bash
   adb pull /sdcard/afw/uid.txt uid_backup.txt
   ```

2. **Update script**:
   ```bash
   # Method 1: Use installer
   ./install.sh  # or install.bat on Windows
   
   # Method 2: Manual with root
   adb shell "su -c 'mkdir -p /data/local/afw/'"
   adb push afw.sh /sdcard/afw/afw.sh.tmp
   adb shell "su -c 'cp /sdcard/afw/afw.sh.tmp /data/local/afw/afw.sh'"
   adb shell "su -c 'chmod 755 /data/local/afw/afw.sh'"
   adb shell "rm /sdcard/afw/afw.sh.tmp"
   ```

3. **Update config file**:
   - Add `sort_by=custom` as line 3
   - Shift all app entries down one line
   - Update format to remove `#` symbols

4. **Apply changes**:
   - Open AFWall+ and tap Apply

5. **Verify**:
   ```bash
   adb shell "logcat -d | grep afwall_custom"
   ```