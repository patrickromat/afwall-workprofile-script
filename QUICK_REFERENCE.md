# AFWall+ Work Profile Script v3.1 - Quick Reference

## 🚀 Essential Commands

### Check if script is running
```bash
adb shell "logcat -d | grep afwall_custom"
```

### Enable debug mode (with timing info)
```bash
# Edit line 1 of /sdcard/afw/uid.txt:
debug=1
# Then tap Apply in AFWall+
```

### View detailed timing breakdown
```bash
# After enabling debug=1:
adb shell "logcat -d | grep -E '(PHASE|TIME|AUGMENT|PARSE)'"
```

### View current configuration
```bash
adb shell "cat /sdcard/afw/uid.txt"
```

### Fix stuck lock
```bash
adb shell "rm -rf /sdcard/afw/script.lock"
```

## 📝 Configuration Format

```
debug=0|1                  # Line 1: Logging mode (1=verbose with timing)
recalculate=0|1           # Line 2: UID refresh
sort_by=custom|package|uid # Line 3: Sort method (default: custom)
```

## 🎯 Adding Apps - Simple Space Format (v3.1)

**No fancy delimiters - just spaces!**

```bash
# Package + Custom Name (most common):
com.spotify.music Spotify Music Player

# Just package (auto-generates name):
com.spotify.music

# UID + Custom Name:
1010444 My Special App

# Complete entry (UID PACKAGE NAME):
1010444 com.spotify.music Spotify Premium Edition
```

**Format Rules:**
- First space: separates UID/package
- Second space: separates package from name
- Everything after second space: custom name (can have spaces)

## ⚠️ Remember: ALWAYS tap Apply in AFWall+ after editing!

## 🔍 Common Package Names

```
com.android.chrome Chrome Browser
com.whatsapp WhatsApp Messenger
org.telegram.messenger Telegram
com.google.android.gm Gmail
com.spotify.music Spotify Music
com.netflix.mediaclient Netflix
com.slack Slack Workspace
com.discord Discord Chat
com.microsoft.emmx Microsoft Edge
com.microsoft.skydrive OneDrive
com.zoom.videomeetings Zoom Meetings
com.microsoft.teams Microsoft Teams
```

## 🐛 Debug Mode - Performance Analysis

Enable `debug=1` to see execution time breakdown:

```
[PHASE1] Parse complete. Time: 45 ms
[PHASE2] Augmentation complete. Time: 245 ms
[PHASE3] Recalculation complete. Time: 0 ms (disabled)
[SORT] Sorting complete. Time: 12 ms
[PHASE4] Rules application complete. Time: 1230 ms
[SUMMARY] Total execution time: 1532 ms
```

**What to look for:**
- **Phase 1 > 100ms**: File is very large or disk slow
- **Phase 2 > 1000ms**: Too many PM calls (add UIDs manually)
- **Phase 3 > 0ms**: Recalculate enabled (should auto-disable)
- **Phase 4 > 2000ms**: Many iptables rules (normal if 50+ apps)

## 🛠️ Troubleshooting Checklist

- [ ] Did you tap Apply after editing uid.txt?
- [ ] Is the Work Profile active (user 10)?
- [ ] Are file permissions correct (755)?
- [ ] Is AFWall+ custom script configured?
- [ ] Check logs for "afwall_custom" tag
- [ ] Try debug=1 for verbose output with timing
- [ ] Remove stale lock if exists

## 🚀 Performance Tips

### If script runs slow:
1. Enable `debug=1` to see timing
2. Check Phase 2 timing:
   - **< 500ms**: Normal
   - **500-1000ms**: Consider adding UIDs manually
   - **> 1000ms**: Too many package lookups
3. Add UIDs manually for most-used apps:
   ```
   1010201 com.spotify.music Spotify
   1010202 com.chrome Chrome
   ```
4. Ensure `recalculate=0` in normal operation

## 📊 How It Works

```
You edit uid.txt (simple space format)
    ↓
Tap Apply in AFWall+
    ↓
AFWall+ starts TWO scripts
    ↓
Instance 1: Lock → Rules → File
Instance 2: Rules only
    ↓
Both instances apply firewall rules
Only Instance 1 updates uid.txt
File is auto-sorted by custom names
```

## 🔄 Migration Process

1. Copy uid.txt from old device
2. Install on new device
3. Set `recalculate=1` (line 2)
4. Tap Apply in AFWall+
5. Script updates all UIDs
6. Recalculate auto-resets to 0

## 📁 File Locations

- **Script**: `/data/local/afw/afw.sh`
- **Config**: `/sdcard/afw/uid.txt`
- **Lock**: `/sdcard/afw/script.lock`
- **Temp**: `/sdcard/afw/uid.txt.tmp`

## 🆚 Format Evolution

### v1.0 (Original)
```
1010444 com.spotify.music
```

### v2.0 (With # Comments)
```
1010444 com.spotify.music # Spotify Music
```

### v3.0 (Clean Format)
```
1010444 com.spotify.music Spotify Music
```

### v3.1 (Same Format, Fixed Performance)
```
1010444 com.spotify.music Spotify Music
```
- Same user-facing format as v3.0
- **6x faster** parsing internally
- Extensive debug logging

## 🔧 Common Fixes

### Script runs 6x slower than expected:
```bash
# Make sure you're running v3.1, not v3.0!
adb shell "head -n 3 /data/local/afw/afw.sh"
# Should show: v3.1
```

### See what's taking time:
```bash
# Enable debug and check timing:
# Set debug=1, tap Apply, then:
adb shell "logcat -d | grep TIME"
```

### Too many PM calls slowing things down:
```bash
# Add UIDs manually to avoid lookups:
# Instead of:
com.spotify.music Spotify

# Use:
1010444 com.spotify.music Spotify
```

---
*Keep this reference handy for quick troubleshooting!*
*Version 3.1 - Performance fixed with extensive debug logging*
