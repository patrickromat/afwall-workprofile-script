# Changelog

## Version 1.1 (Latest)

### 🎯 New Feature
- **Automatic Sorting by Custom Name**: Apps are now automatically sorted alphabetically by their custom names
  - Case-insensitive sorting
  - Happens automatically every time the script runs
  - No configuration needed
  - Makes it easy to find apps in your list

### 🔧 Technical Changes
- Added Phase 3.5: Sort by Custom Name
- Sorting uses `awk` and `sort -f` for case-insensitive alphabetical ordering
- Performance impact: ~2-5ms for typical configs

### 📝 Example
Before:
```
com.zzz.app Zebra
com.aaa.app Apple
com.mmm.app Mango
```

After (automatic):
```
com.aaa.app Apple
com.mmm.app Mango
com.zzz.app Zebra
```

### ✅ Compatibility
- 100% compatible with v1.0 config files
- No changes to config format
- Existing configs will be sorted on next run

---

## Version 1.0

### Initial Release
- Basic Work Profile support (user 10)
- Dynamic UID/package name resolution
- Debug mode for verbose output
- Recalculate mode for device migrations
- File locking mechanism
- IPv4 and IPv6 iptables support
- Configuration file management
- Silent operation in production mode

---

## Upgrade Instructions

### From v1.0 to v1.1

1. **Update script**:
   ```bash
   adb push afw.sh /sdcard/afw/afw.sh.tmp
   adb shell "su -c 'cp /sdcard/afw/afw.sh.tmp /data/local/afw/afw.sh'"
   adb shell "su -c 'chmod 755 /data/local/afw/afw.sh'"
   adb shell "rm /sdcard/afw/afw.sh.tmp"
   ```

2. **No config changes needed**: Your uid.txt works as-is

3. **Apply**: Tap Apply in AFWall+ to run with new sorting

4. **Verify**: Your apps will now be sorted alphabetically by name

---

*Simple, reliable, sorted.*
