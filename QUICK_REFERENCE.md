# AFWall+ Work Profile Script v1.1 - Quick Reference

## 🚀 Essential Commands

### Check if script is running
```bash
adb shell "logcat -d | grep afwall_custom_script"
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
adb shell "rmdir /sdcard/afw/script.lock"
```

## 📝 Configuration Format

```
debug=0|1          # Line 1: Logging mode
recalculate=0|1    # Line 2: UID refresh
```

## 🎯 Adding Apps

**Simple format:**
```bash
# Package + Custom Name:
com.spotify.music Spotify Music

# UID + Custom Name:
1010444 My App

# Complete entry:
1010444 com.spotify.music Spotify Premium
```

**Everything after package/UID = custom name**

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
com.zoom.videomeetings Zoom
```

## ✨ v1.1 Feature: Automatic Sorting

**Apps are automatically sorted alphabetically by custom name!**

Before:
```
com.zzz.app Zebra
com.aaa.app Apple
```

After (automatic):
```
com.aaa.app Apple
com.zzz.app Zebra
```

## 🛠️ Troubleshooting Checklist

- [ ] Did you tap Apply after editing uid.txt?
- [ ] Is the Work Profile active (user 10)?
- [ ] Are file permissions correct (755)?
- [ ] Is AFWall+ custom script configured?
- [ ] Check logs for "afwall_custom_script" tag
- [ ] Try debug=1 for verbose output

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

## 🆚 Version Comparison

### v1.0
- No sorting
- Manual organization

### v1.1 (Current)
- **Automatic sorting by custom name**
- Alphabetical, case-insensitive
- No config changes needed

---
*Keep this reference handy for quick troubleshooting!*
