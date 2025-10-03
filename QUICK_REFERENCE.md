# AFWall+ Work Profile Script v3.0 - Quick Reference

## 🚀 Essential Commands

### Check if script is running
```bash
adb shell "logcat -d | grep afwall_custom"
```

### Enable debug mode
```bash
# Edit line 1 of /sdcard/afw/uid.txt:
debug=1
# Then tap Apply in AFWall+
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
debug=0|1                  # Line 1: Logging mode
recalculate=0|1           # Line 2: UID refresh
sort_by=custom|package|uid # Line 3: Sort method (default: custom)
```

## 🎯 Adding Apps - v3.0 Simple Format

**No more # symbols needed!**

```bash
# Package + Custom Name (most common):
com.spotify.music Spotify Music Player

# Just package (auto-generates name):
com.spotify.music

# UID + Custom Name:
1010444 My Special App

# Complete entry:
1010444 com.spotify.music Spotify Premium
```

## ⚠️ Remember: ALWAYS tap Apply in AFWall+ after editing!

## 🔍 Common Package Names with Custom Names

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

## 🛠️ Troubleshooting Checklist

- [ ] Did you tap Apply after editing uid.txt?
- [ ] Is the Work Profile active (user 10)?
- [ ] Are file permissions correct (755)?
- [ ] Is AFWall+ custom script configured?
- [ ] Check logs for "afwall_custom" tag
- [ ] Try debug=1 for verbose output
- [ ] Remove stale lock if exists

## 📊 How It Works

```
You edit uid.txt (simple format)
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

### v2.0 (With Comments)
```
1010444 com.spotify.music # Spotify Music
```

### v3.0 (Clean & Simple)
```
1010444 com.spotify.music Spotify Music
```

---
*Keep this reference handy for quick troubleshooting!*