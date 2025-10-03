# AFWall+ Work Profile Script v1.1

## ✅ What This Is

A simple, reliable shell script that adds Work Profile support to AFWall+ with automatic sorting of apps by custom name.

## 📁 Files

- **afw.sh** - Main script (v1.1)
- **uid.txt** - Configuration file example
- **README.md** - Full documentation
- **QUICK_REFERENCE.md** - Quick commands
- **CHANGELOG.md** - Version history
- **RELEASE_NOTES.md** - v1.1 release details

## 🎯 Key Features

1. **Work Profile Support** - Manages apps in Android Work Profile (user 10)
2. **Auto UID Detection** - Automatically finds UIDs for packages
3. **Auto Package Detection** - Automatically finds packages for UIDs
4. **Automatic Sorting** - Apps sorted alphabetically by custom name (v1.1)
5. **Debug Mode** - Detailed logging when needed
6. **Migration Support** - Recalculate UIDs when moving devices

## 🚀 Quick Start

1. Install script to `/data/local/afw/afw.sh` (chmod 755)
2. Install config to `/sdcard/afw/uid.txt`
3. Configure AFWall+ custom script: `nohup /data/local/afw/afw.sh > /dev/null 2>&1 &`
4. Add apps to uid.txt
5. Tap Apply in AFWall+

## 📝 Config Format

```
debug=0
recalculate=0
com.spotify.music Spotify Music
com.android.chrome Chrome Browser
com.whatsapp WhatsApp
```

Apps will be automatically sorted alphabetically by their custom names!

## 🆚 Version 1.1 Changes

**NEW**: Automatic sorting by custom name
- Alphabetical, case-insensitive
- No configuration needed
- Makes app list easy to scan

## 📄 License

MIT License - Use freely

---

*Version 1.1 - Simple. Reliable. Sorted.*
