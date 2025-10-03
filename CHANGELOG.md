# Changelog

## Version 1.1 (Latest)

### 🎯 New Features

#### 1. Automatic Sorting by Custom Name
- Apps are now automatically sorted alphabetically by their custom names
- Case-insensitive sorting
- Happens automatically every time the script runs
- No configuration needed
- Makes it easy to find apps in your list

#### 2. xtables Lock Fix ✅
- **Automatic detection** of `-w` flag support
- **Waits up to 5 seconds** for iptables lock when supported
- **Prevents errors** like "Another app is currently holding the xtables lock"
- **Works on both old and new Android versions**
- **Configurable wait time** (default: 5 seconds)

### 🔧 Technical Changes
- Added Phase 3.5: Sort by Custom Name
- Sorting uses `awk` and `sort -f` for case-insensitive alphabetical ordering
- Added iptables `-w` flag compatibility detection
- Added `IPTABLES_WAIT` configuration variable (line 18)
- Modified Phase 4 to use `-w` flag when supported
- Performance impact: ~2-5ms for sorting

### 📝 Examples

**Sorting example:**
```
# Before:
com.zzz.app Zebra
com.aaa.app Apple
com.mmm.app Mango

# After (automatic):
com.aaa.app Apple
com.mmm.app Mango
com.zzz.app Zebra
```

**xtables lock handling:**
```bash
# Old behavior (could fail):
iptables -I "chain" -m owner --uid-owner "1010444" -j RETURN

# New behavior (waits for lock):
iptables -w 5 -I "chain" -m owner --uid-owner "1010444" -j RETURN
```

### 📚 Documentation
- Added **HOWTO.md** with detailed guides for:
  - Creating homescreen shortcuts (X-plore, MiXplorer, Solid Explorer, Total Commander)
  - Finding UIDs and package names (App Manager, ADB commands)
  - Troubleshooting xtables lock issues
- Updated README with references to HOWTO guide
- Added troubleshooting section for lock errors

### ✅ Compatibility
- 100% compatible with v1.0 config files
- No changes to config format required
- Existing configs will be sorted on next run
- Automatic fallback for devices without `-w` support

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

3. **Apply**: Tap Apply in AFWall+ to run with new features

4. **Verify**: 
   - Your apps will now be sorted alphabetically
   - xtables lock errors should be resolved
   - Check debug mode to see if `-w` is supported

---

## Technical Details

### Sorting Implementation
```bash
# Sort by custom name (field 3), case-insensitive
sorted_data=$(printf "%s" "$completed_data" | \
    awk -F"$DELIMITER" '{if (NF >= 3 && $0 != "") print $3 "|" $0}' | \
    LC_ALL=C sort -f | cut -d'|' -f2-)
```

### xtables Lock Implementation
```bash
# Detect support
if $IPTABLES -w 1 -L -n >/dev/null 2>&1; then
    IPTABLES_SUPPORTS_WAIT=true
fi

# Use with fallback
if [ "$IPTABLES_SUPPORTS_WAIT" = "true" ]; then
    $IPTABLES -w $IPTABLES_WAIT -I "$chain" ...
else
    $IPTABLES -I "$chain" ...  # Old method
fi
```

---

*Simple, reliable, sorted, and lock-safe.*
