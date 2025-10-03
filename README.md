# AFWall+ Work Profile Automation Script v1.1

A simple, reliable script that extends AFWall+ with Work Profile support and automatic sorting by custom app names.

## ⚡ Quick Start Guide

### Prerequisites
- **Rooted Android device** (Magisk/KernelSU/SuperSU)
- **AFWall+ installed** with root granted
- **Work Profile exists** (via Island, Shelter, or native Dual Apps)
- **ADB on computer** for initial setup

### Installation (5 minutes)

1. **Connect device** with ADB debugging enabled

2. **Create directories and push files:**
```bash
# Create config directory (user accessible)
adb shell "mkdir -p /sdcard/afw/"

# Create script directory with root
adb shell "su -c 'mkdir -p /data/local/afw/'"

# Push script to temp location first
adb push afw.sh /sdcard/afw/afw.sh.tmp

# Move to final location with root permissions
adb shell "su -c 'cp /sdcard/afw/afw.sh.tmp /data/local/afw/afw.sh'"
adb shell "su -c 'chmod 755 /data/local/afw/afw.sh'"
adb shell "rm /sdcard/afw/afw.sh.tmp"

# Push config file
adb push uid.txt /sdcard/afw/uid.txt
```

3. **Configure AFWall+:**
   - Open AFWall+ → Menu (⋮) → **Set custom script**
   - Enter exactly: `nohup /data/local/afw/afw.sh > /dev/null 2>&1 &`
   - Tap **OK** to save

4. **Initial run:**
   - Tap **Apply** in AFWall+ (this triggers the script)
   - Check Android logs for "afwall_custom_script" tag to verify

## 📱 Daily Usage

### 🔴 IMPORTANT: Apply After Every Change!

**You MUST tap "Apply" in AFWall+ after editing uid.txt!** The script only runs when AFWall+ triggers it. Changes to uid.txt alone do nothing until you:
1. Edit `/sdcard/afw/uid.txt`
2. Save the file
3. **Open AFWall+ and tap Apply**

### 💡 Pro Tip: Create a Homescreen Shortcut!

For easy one-tap editing, create a shortcut to uid.txt:
- **See [HOWTO.md](HOWTO.md#creating-homescreen-shortcuts)** for detailed instructions
- Works with X-plore, MiXplorer, Solid Explorer, Total Commander
- Edit uid.txt with one tap!

### Adding Apps - Simple Format

#### Method 1: Package Name + Custom Name (Recommended)
```
com.spotify.music Spotify Music Player
```
The script auto-detects the UID and sorts by "Spotify Music Player"

#### Method 2: UID + Custom Name
```
1010444 My Special App
```
The script auto-detects the package name

#### Method 3: Complete Entry
```
1010444 com.spotify.music Spotify Premium
```
Format: `UID PACKAGE CUSTOM_NAME`
Everything after the package name is the custom name

### 🔍 How to Find UIDs and Package Names

**See [HOWTO.md](HOWTO.md#finding-uids-and-package-names)** for complete instructions:
- **App Manager** method (visual, easy)
- **ADB commands** (batch operations)
- **On-device terminal** (quick checks)

## 🎯 What's New in Version 1.1

### Automatic Sorting by Custom Name
- Apps are **automatically sorted alphabetically** by your custom names
- Case-insensitive sorting (A=a, B=b, etc.)
- Happens every time the script runs
- No configuration needed - it just works!

### xtables Lock Fix ✅
- **Automatic detection** of `-w` flag support
- **Waits for lock** (up to 5 seconds) when supported
- **Prevents errors** like "Another app is currently holding the xtables lock"
- **Works on old and new Android** versions
- **See [HOWTO.md](HOWTO.md#troubleshooting-xtables-lock-issues)** for details

### Example
**Before sorting:**
```
com.zzz.app Zebra App
com.aaa.app Apple App  
com.mmm.app Mango App
```

**After sorting (automatic):**
```
com.aaa.app Apple App
com.mmm.app Mango App
com.zzz.app Zebra App
```

## 🔧 Configuration File Structure

### /sdcard/afw/uid.txt Format
```
debug=0                          # Line 1: Production mode
recalculate=0                    # Line 2: Normal operation

# Your apps (will be auto-sorted)
com.spotify.music Spotify Music
com.android.chrome Chrome Browser
com.whatsapp WhatsApp Messenger
```

### Configuration Options

| Line | Setting | Values | Description |
|------|---------|--------|-------------|
| 1 | `debug` | `0` or `1` | Enable verbose logging |
| 2 | `recalculate` | `0` or `1` | Force UID refresh (for migrations) |

## 📚 Complete Documentation

- **[HOWTO.md](HOWTO.md)** - Detailed how-to guide covering:
  - Creating homescreen shortcuts for easy editing
  - Finding UIDs and package names
  - Troubleshooting xtables lock issues
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

## 🚀 Advanced Usage

### Device Migration

When moving to a new device, UIDs change but package names don't:

1. **Backup** old device: 
   ```bash
   adb pull /sdcard/afw/uid.txt uid_backup.txt
   ```

2. **Setup** new device: Install script

3. **Restore** file:
   ```bash
   adb push uid_backup.txt /sdcard/afw/uid.txt
   ```

4. **Enable recalculation**: Set line 2 to `recalculate=1`

5. **Apply**: Tap Apply in AFWall+ to refresh all UIDs

6. **Automatic reset**: Script sets `recalculate=0` after completion

### Troubleshooting

**Nothing happens after editing uid.txt:**
- Did you tap Apply in AFWall+? (Required!)
- Check logs: `adb shell "logcat -d | grep afwall_custom"`

**xtables lock errors:**
- v1.1 fixes this automatically with `-w` flag
- See [HOWTO.md](HOWTO.md#troubleshooting-xtables-lock-issues) for details

**Apps not blocked/allowed:**
```bash
# Enable debug mode:
# Change line 1 to: debug=1
# Then tap Apply and check output
```

**Verify Work Profile:**
```bash
adb shell "pm list users"
# Should show: UserInfo{10:Work Profile:30}
```

## 📊 Technical Details

### How It Works
1. **Parse** uid.txt into memory
2. **Augment** missing UIDs/packages via `pm` command
3. **Recalculate** UIDs if migration mode enabled
4. **Sort** entries alphabetically by custom name
5. **Apply** iptables rules (with `-w` flag support)
6. **Write** sorted, complete data back to file

### Safety Features
- **File locking** prevents concurrent writes
- **Atomic operations** prevent partial writes
- **UID validation** prevents invalid iptables commands
- **xtables lock handling** prevents lock conflicts
- **Silent operation** in production mode

### Performance
- **Parse**: ~40ms
- **Augment**: ~200ms (depends on pm lookups)
- **Sort**: ~2-5ms
- **Apply rules**: ~500ms
- **Total**: ~750ms (typical config with 20 apps)

## ⚠️ Security Considerations

- **Script location**: Keep in `/data/local/afw/` (root-protected)
- **Configuration**: Stored in `/sdcard/afw/` for easy editing
- **Permissions**: Script requires root for iptables access
- **Validation**: All UIDs verified before use

## 📝 Example Configurations

### Minimal Setup
```
debug=0
recalculate=0
com.android.chrome Chrome
com.spotify.music Spotify
```

### Complete Setup with Custom Names
```
debug=0
recalculate=0

# Apps (will be sorted automatically)
com.android.chrome Chrome Browser
com.whatsapp WhatsApp Messenger
com.spotify.music Spotify Music
com.slack Slack for Work
com.zoom.videomeetings Zoom
```

### Debug Mode
```
debug=1
recalculate=0
com.android.chrome Chrome
com.spotify.music Spotify
```

## 🆚 Version History

### Version 1.1 (Current)
- **NEW**: Automatic sorting by custom name
- **NEW**: xtables lock fix with `-w` flag support
- Alphabetical, case-insensitive sorting
- Automatic compatibility detection
- No configuration needed

### Version 1.0
- Basic Work Profile support (user 10)
- Dynamic UID/package name resolution
- Debug and recalculate modes
- File locking mechanism
- IPv4 and IPv6 support

## 🤝 Support

- **Logs**: Check `logcat` for tag "afwall_custom_script"
- **Debug**: Enable `debug=1` for detailed output
- **Script location**: `/data/local/afw/afw.sh`
- **Config location**: `/sdcard/afw/uid.txt`
- **How-to guide**: See [HOWTO.md](HOWTO.md) for detailed instructions

## 📄 License

This project is released under the MIT License. Use, modify, and distribute freely.

---
*Version 1.1 - Automatic sorting by custom name + xtables lock fix*
