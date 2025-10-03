# Changelog

## Version 2.0 (Current)

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

### From v1.0 to v2.0

1. **Backup current config**:
   ```bash
   adb pull /sdcard/afw/uid.txt uid_backup.txt
   ```

2. **Update script**:
   ```bash
   adb push afw.sh /data/local/afw.sh
   adb shell "chmod 755 /data/local/afw.sh"
   ```

3. **Update config file**:
   - Add `sort_by=name` as line 3
   - Shift all app entries down one line

4. **Apply changes**:
   - Open AFWall+ and tap Apply

5. **Verify**:
   ```bash
   adb shell "logcat -d | grep afwall_custom"
   ```