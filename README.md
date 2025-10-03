# Advanced AFWall+ Work Profile Automation Script v2.0

A robust, self-managing script that extends AFWall+ with first-class Work Profile support, intelligent parallel execution handling, and automatic app sorting.

## 🚨 Critical Understanding: How AFWall+ Executes Scripts

**AFWall+ launches TWO instances of your custom script in parallel!** This is by design and our script handles it intelligently:

- **Instance 1:** Acquires lock → Applies rules → Updates uid.txt file
- **Instance 2:** Sees lock → Applies rules only → Exits cleanly

Both instances apply firewall rules for redundancy, but only one updates the configuration file. This prevents corruption while ensuring rules are applied quickly.

## ⚡ Quick Start Guide

### Prerequisites
- **Rooted Android device** (Magisk/KernelSU/SuperSU)
- **AFWall+ installed** with root granted
- **Work Profile exists** (via Island, Shelter, or native Dual Apps)
- **ADB on computer** for initial setup
- **Root file manager** on device (X-plore recommended)

### Installation (5 minutes)

1. **Connect device** with ADB debugging enabled

2. **Create directories and push files:**
```bash
# Create config directory
adb shell "mkdir -p /sdcard/afw/"

# Push the script
adb push afw.sh /data/local/afw.sh
adb shell "chmod 755 /data/local/afw.sh"

# Push initial config
adb push uid.txt /sdcard/afw/uid.txt
```

3. **Configure AFWall+:**
   - Open AFWall+ → Menu (⋮) → **Set custom script**
   - Enter exactly: `nohup /data/local/afw.sh > /dev/null 2>&1 &`
   - Tap **OK** to save

4. **Initial run:**
   - Tap **Apply** in AFWall+ (this triggers both script instances)
   - Check Android logs for "afwall_custom" tag to verify execution

## 📱 Daily Usage

### 🔴 IMPORTANT: Apply After Every Change!

**You MUST tap "Apply" in AFWall+ after editing uid.txt!** The script only runs when AFWall+ triggers it. Changes to uid.txt alone do nothing until you:
1. Edit `/sdcard/afw/uid.txt`
2. Save the file
3. **Open AFWall+ and tap Apply**

### Adding Apps - Three Methods

#### Method 1: By Package Name (Recommended)
```bash
# Edit /sdcard/afw/uid.txt and add:
com.spotify.music # Spotify

# Then tap Apply in AFWall+
```
The script auto-detects the UID and sorts by your comment.

#### Method 2: By UID
```bash
# Find UID in App Manager (Work Profile), then add:
1010444 # App name

# Then tap Apply in AFWall+
```
The script auto-detects the package name.

#### Method 3: Complete Entry
```bash
# Add both if known:
1010444 com.spotify.music # Spotify Music Player

# Then tap Apply in AFWall+
```

### Using X-plore File Manager

**One-tap editing setup:**
1. Navigate to `/sdcard/afw/`
2. Long-press `uid.txt`
3. Select **Create Shortcut** for homescreen access
4. Edit anytime: Long-press → **Edit Text**

## 🎯 New Features in v2.0

### Automatic Sorting
Your apps are automatically sorted by the method you choose:
- **By name** (default): Alphabetical by comment/app name
- **By package**: Alphabetical by package name  
- **By uid**: Numerical by UID value

Change sorting in uid.txt line 3:
```
sort_by=name    # or 'uid' or 'package'
```

### Enhanced Lock Management
- **Smart parallel handling**: Both AFWall+ instances work together
- **Stale lock cleanup**: Auto-removes dead locks after 5 minutes
- **PID validation**: Verifies lock owner is still running
- **Race condition prevention**: Atomic operations throughout

### Improved Robustness
- **UID validation**: Only valid numeric UIDs are used
- **Safe delimiter**: Uses `§` to avoid conflicts
- **Error handling**: Graceful failures with logging
- **Auto-comments**: Generates names from package if missing

## 🔧 Configuration File Structure

### /sdcard/afw/uid.txt
```bash
debug=0                          # 0=production, 1=verbose debug
recalculate=0                    # 0=normal, 1=refresh all UIDs
sort_by=name                     # name/package/uid
# ============================================
# Your apps below (auto-sorted on save)
# ============================================
com.android.chrome               # Chrome Browser
1010211 com.whatsapp            # WhatsApp
com.spotify.music                # Spotify
1010150                          # Auto-detected app
```

### Configuration Options

| Line | Setting | Values | Description |
|------|---------|--------|-------------|
| 1 | `debug` | `0` or `1` | Enable verbose logging |
| 2 | `recalculate` | `0` or `1` | Force UID refresh (for migrations) |
| 3 | `sort_by` | `name`, `package`, `uid` | Automatic sorting method |

## 🔄 Understanding Script Execution

### When Scripts Run
1. **User taps Apply** in AFWall+
2. **AFWall+ launches TWO script instances** simultaneously
3. **First instance** gets lock, both apply rules
4. **Only lock holder** updates uid.txt
5. **Both instances** complete successfully

### Why Two Instances?
AFWall+ uses parallel execution for redundancy. Our script handles this elegantly:
- No conflicts or corruption
- Faster rule application
- Automatic coordination via locking

### Debug Mode Insight
Enable `debug=1` to see both instances working:
```
[INSTANCE] PID: 12345
[LOCK] Lock acquired. This instance (12345) will write to file.
...
[INSTANCE] PID: 12346  
[LOCK-INFO] Another instance (12345) holds the lock. This instance will only apply rules.
```

## 🚀 Advanced Usage

### Device Migration

When moving to a new device, UIDs change but package names don't:

1. **Backup** old device: Copy `/sdcard/afw/uid.txt`
2. **Setup** new device: Complete installation
3. **Restore** file: Copy uid.txt to new device
4. **Enable recalculation**: Set line 2 to `recalculate=1`
5. **Apply**: Tap Apply in AFWall+ to refresh all UIDs
6. **Automatic reset**: Script sets `recalculate=0` after completion

### Troubleshooting

**Nothing happens after editing uid.txt:**
- Did you tap Apply in AFWall+? (Required!)
- Check logs: `adb shell "logcat -d | grep afwall_custom"`

**Duplicate firewall rules:**
- Normal behavior - AFWall+ manages rule deduplication
- Both script instances apply rules by design

**Lock errors in logs:**
```bash
# Remove stale lock if needed:
adb shell "rm -rf /sdcard/afw/script.lock"
```

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

## 📊 Technical Architecture

### Execution Phases
1. **Lock Acquisition** - Atomic mkdir operation
2. **Configuration Parse** - Read uid.txt into memory
3. **Data Augmentation** - Query missing UIDs/packages via `pm`
4. **Recalculation** - Refresh UIDs if migration mode enabled
5. **Sorting** - Order entries by chosen method
6. **Rule Application** - Insert iptables rules (both instances)
7. **File Update** - Write sorted, complete data (lock holder only)

### Safety Features
- **Atomic operations** prevent partial writes
- **PID tracking** validates lock ownership
- **Timeout handling** cleans stale locks
- **UID validation** prevents invalid iptables commands
- **Safe delimiter** (`§`) avoids parsing conflicts

### Performance Optimizations
- Rules applied before file I/O
- Parallel execution for redundancy
- In-memory processing
- Single-pass sorting
- Minimal pm command calls

## ⚠️ Security Considerations

- **Script location**: Keep in `/data/local/` (root-protected)
- **Configuration**: Stored in `/sdcard/afw/` for easy editing
- **Permissions**: Script requires root for iptables access
- **Validation**: All UIDs verified before use
- **Logging**: Production mode minimizes log output

## 📝 Example Configurations

### Minimal Setup
```
debug=0
recalculate=0
sort_by=name
com.android.chrome
com.spotify.music
```

### Complete Setup with Comments
```
debug=0
recalculate=0
sort_by=name
# Browsers
1010201 com.android.chrome # Chrome Browser
1010202 com.microsoft.emmx # Microsoft Edge
# Communication  
1010211 com.whatsapp # WhatsApp Messenger
1010212 org.telegram.messenger # Telegram
# Work Apps
com.slack # Slack (UID auto-detected)
com.zoom.videomeetings # Zoom Meetings
```

### Debug Mode for Troubleshooting
```
debug=1
recalculate=0
sort_by=uid
# Your apps here
```

## 🤝 Support

- **Logs**: Check `logcat` for tag "afwall_custom"
- **Debug**: Enable `debug=1` for detailed output
- **Script location**: `/data/local/afw.sh`
- **Config location**: `/sdcard/afw/uid.txt`

## 📄 License

This project is released into the public domain. Use, modify, and distribute freely.

## 🙏 Acknowledgments

- AFWall+ developers for the excellent firewall
- Android community for Work Profile management tools
- Contributors and testers

---
*Version 2.0 - Enhanced parallel execution, sorting, and robustness*