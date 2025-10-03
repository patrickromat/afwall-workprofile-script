# Advanced AFWall+ Work Profile Automation Script v3.1

A robust, self-managing script that extends AFWall+ with first-class Work Profile support, intelligent parallel execution handling, and automatic app sorting by custom names.

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
- **File manager** on device (X-plore recommended - to create file edit shortcut)
- **App Manager** installed in work profile to quickly lookup application UID

### Installation (5 minutes)

#### Automatic Installation (Recommended)
```bash
# Use the included installer script:
chmod +x install.sh
./install.sh

# Or on Windows:
install.bat
```

#### Manual Installation
1. **Connect device** with ADB debugging enabled

2. **Create directories and push files:**
```bash
# Create config directory (user accessible)
adb shell "mkdir -p /sdcard/afw/"

# Create script directory with root
adb shell "su -c 'mkdir -p /data/local/afw/'"

# Push script to temp location first (avoids permission error)
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
   - Tap **Apply** in AFWall+ (this triggers both script instances)
   - Check Android logs for "afwall_custom" tag to verify execution

## 📱 Daily Usage

### 🔴 IMPORTANT: Apply After Every Change!

**You MUST tap "Apply" in AFWall+ after editing uid.txt!** The script only runs when AFWall+ triggers it. Changes to uid.txt alone do nothing until you:
1. Edit `/sdcard/afw/uid.txt`
2. Save the file
3. **Open AFWall+ and tap Apply**

### Adding Apps - Simple Space-Delimited Format

The v3.1 format uses simple spaces - no fancy delimiters!

#### Method 1: Package Name + Custom Name (Recommended)
```
com.spotify.music Spotify Music Player
```
The script auto-detects the UID and sorts by "Spotify Music Player"

#### Method 2: Just Package Name
```
com.spotify.music
```
The script auto-generates "Spotify" as the name

#### Method 3: UID + Custom Name
```
1010444 My Special App
```
- The script auto-detects the package name
- You can lookup app UID in App Manager application or any other 
- **TIP** Work Profile package UIDs start with 1010 - easy to check if you got correct one

#### Method 4: Complete Entry
```
1010444 com.spotify.music Spotify Premium
```
Format: `UID PACKAGE CUSTOM_NAME`
- First space separates UID from package
- Second space separates package from custom name
- Everything after the second space is the custom name

### Using X-plore File Manager

**One-tap editing setup:**
1. Navigate to `/sdcard/afw/`
2. Long-press `uid.txt`
3. Select **Create Shortcut** for homescreen access
4. Edit anytime: Long-press → **Edit Text**

## 🎯 New in Version 3.1

### Space-Based Delimiters (Performance Fix)
- **Removed internal fancy delimiter** (§ symbol)
- **Simple space parsing** for better performance
- **6x faster parsing** - fixed performance regression
- **Extensive debug logging** to track execution time

### Debug Improvements
- **Millisecond-precision timing** for all phases
- **Per-operation logging** shows exact bottlenecks
- **PM command timing** tracks package manager calls
- **Phase-by-phase breakdown** in debug mode

### What Changed from v3.0
- Replaced `§` delimiter with triple-space internally
- Fixed slow parsing that caused 6x performance degradation
- Added extensive timing logs for debugging
- Simplified field extraction using awk

## 🔧 Configuration File Structure

### /sdcard/afw/uid.txt Format
```
debug=0                          # Production mode
recalculate=0                    # Normal operation
sort_by=custom                   # Sort by custom names

# Your apps - simple space format!
com.android.chrome Chrome Browser
com.whatsapp WhatsApp Messenger
com.spotify.music Spotify Music Player
1010150 Auto-Detected App Name
```

### Configuration Options

| Line | Setting | Values | Description |
|------|---------|--------|-------------|
| 1 | `debug` | `0` or `1` | Enable verbose logging with timing |
| 2 | `recalculate` | `0` or `1` | Force UID refresh (for migrations) |
| 3 | `sort_by` | `custom`, `package`, `uid` | Automatic sorting method |

### Entry Format Rules
```
PACKAGE_NAME CUSTOM_NAME           # Auto-detects UID
UID CUSTOM_NAME                    # Auto-detects package
UID PACKAGE_NAME CUSTOM_NAME       # Full entry
```

**Important:**
- First space: separates UID from package (or package from name if no UID)
- Second space: separates package from custom name
- Everything after second space: custom name (can contain spaces!)

## 🔄 Understanding Script Execution

### When Scripts Run
1. **User taps Apply** in AFWall+
2. **AFWall+ launches TWO script instances** simultaneously
3. **First instance** gets lock, both apply rules
4. **Only lock holder** updates uid.txt
5. **Both instances** complete successfully

### Debug Mode Insight
Enable `debug=1` to see detailed timing information:
```
[PHASE1] Starting file parse...
[PARSE] Line 4: com.spotify.music Spotify Music
[PARSE] Extracted - UID:[] PKG:[com.spotify.music] NAME:[Spotify Music]
[PHASE1] Parse complete. Time: 45 ms
[PHASE2] Starting data augmentation...
[AUGMENT] Looking up UID for package: com.spotify.music
[AUGMENT] PM call took 234 ms
[AUGMENT] Found UID: 1010444
[PHASE2] Augmentation complete. Time: 245 ms
...
[SUMMARY]
- Total execution time: 523 ms
```

This helps identify performance bottlenecks!

## 🚀 Advanced Usage

### Performance Troubleshooting

If script runs slow, enable debug mode to see timing:

1. Edit `/sdcard/afw/uid.txt` line 1: `debug=1`
2. Run script via AFWall+ Apply
3. Check output: `adb shell "logcat -d | grep -A 100 INSTANCE"`
4. Look for slow phases:
   - **Phase 2** slow? Too many missing UIDs (add them manually)
   - **Phase 3** slow? Recalculate mode enabled (should auto-disable)
   - **Sort** slow? Too many entries (sorting is O(n log n))

### Device Migration

When moving to a new device, UIDs change but package names don't:

1. **Backup** old device: 
   ```bash
   adb pull /sdcard/afw/uid.txt uid_backup.txt
   ```

2. **Setup** new device: Run `install.sh` or `install.bat`

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

**Script runs too slow:**
- Enable debug=1 to see timing breakdown
- Check Phase 2 timing - if >2 seconds, add UIDs manually
- Ensure recalculate=0 in normal use

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
5. **Sorting** - Order entries by chosen method (default: custom names)
6. **Rule Application** - Insert iptables rules (both instances)
7. **File Update** - Write sorted, complete data (lock holder only)

### Safety Features
- **Atomic operations** prevent partial writes
- **PID tracking** validates lock ownership
- **Timeout handling** cleans stale locks
- **UID validation** prevents invalid iptables commands
- **Simple space delimiter** for reliable parsing

### Performance Optimizations
- Rules applied before file I/O
- Parallel execution for redundancy
- In-memory processing
- Efficient awk-based parsing
- Minimal pm command calls

## ⚠️ Security Considerations

- **Script location**: Keep in `/data/local/afw/` (root-protected directory)
- **Configuration**: Stored in `/sdcard/afw/` for easy editing
- **Permissions**: Script requires root for iptables access
- **Validation**: All UIDs verified before use
- **Logging**: Production mode minimizes log output

## 📝 Example Configurations

### Minimal Setup
```
debug=0
recalculate=0
sort_by=custom
com.android.chrome Chrome
com.spotify.music Spotify
```

### Complete Setup with Custom Names
```
debug=0
recalculate=0
sort_by=custom

# Browsers
1010201 com.android.chrome Chrome Browser
1010202 com.microsoft.emmx Microsoft Edge Browser

# Communication  
com.whatsapp WhatsApp Messenger
org.telegram.messenger Telegram Chat

# Work Apps
com.slack Slack for Work
com.zoom.videomeetings Zoom Video Meetings
```

### Debug Mode (Performance Analysis)
```
debug=1
recalculate=0
sort_by=custom
# Your apps with custom names
com.android.chrome Chrome Browser
com.spotify.music Spotify Premium
```

### Migration Mode
```
debug=0
recalculate=1
sort_by=custom
# Your apps with custom names
com.android.chrome Chrome Browser
com.spotify.music Spotify Premium
```

## 🆚 Version Comparison

### What's Changed from v3.0 to v3.1
- **Fixed 6x performance regression** caused by fancy delimiter
- **Replaced § with simple spaces** (3 spaces internally)
- **Added extensive timing logs** for debugging
- **Improved awk-based parsing** for efficiency
- **Better debug output** with millisecond precision

### Format Remains the Same
```
# v3.0 and v3.1 both use:
com.spotify.music Spotify Music
```

## 🤝 Support

- **Logs**: Check `logcat` for tag "afwall_custom"
- **Debug**: Enable `debug=1` for detailed timing output
- **Script location**: `/data/local/afw/afw.sh`
- **Config location**: `/sdcard/afw/uid.txt`
- **Performance**: Use debug mode to identify bottlenecks

## 📄 License

This project is released under the MIT License. Use, modify, and distribute freely.

## 🙏 Acknowledgments

- AFWall+ developers for the excellent firewall
- Android community for Work Profile management tools
- Contributors and testers

---
*Version 3.1 - Performance fixed, extensive debug logging, simple space delimiters*
