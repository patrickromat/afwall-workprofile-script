# V3.0 Release Notes - Key Improvements

## 🔧 Installation Fix

### Problem Solved
- **Permission Denied Error**: Direct push to `/data/local/` fails without root
- **Solution**: Two-step process using temporary location

### New Installation Method
1. Push files to `/sdcard/afw/` first (user-accessible)
2. Use `su` to copy to `/data/local/afw/` with root permissions
3. Includes automatic installer scripts for both Linux/Mac and Windows

## 📁 Better Organization

### Script Location Change
- **Old**: `/data/local/afw.sh`
- **New**: `/data/local/afw/afw.sh`
- Creates dedicated directory for better organization
- Allows future expansion (logs, backups, etc.)

## 🎯 Simplified Custom Names

### Format Evolution
```bash
# v1.0 - Basic
1010444 com.spotify.music

# v2.0 - With comment syntax
1010444 com.spotify.music # Spotify Music

# v3.0 - Clean and simple
1010444 com.spotify.music Spotify Music
```

### Benefits
- No hash symbols needed
- More intuitive format
- Everything after package/UID is the custom name
- Cleaner file appearance

## 🚀 Installation Scripts

### Included Files
- **install.sh** - Linux/Mac installer
- **install.bat** - Windows installer

### Features
- Automatic root permission handling
- Step-by-step verification
- Error handling and recovery
- Work Profile detection
- Clear success/failure indicators

## 📋 Complete File List

1. **afw.sh** - Main script (updated paths)
2. **uid.txt** - Example configuration (cleaner format)
3. **README.md** - Comprehensive documentation
4. **CHANGELOG.md** - Version history
5. **QUICK_REFERENCE.md** - One-page guide
6. **LICENSE** - MIT License
7. **install.sh** - Linux/Mac installer
8. **install.bat** - Windows installer

## 🔄 Upgrade Path

### From v2.0 to v3.0
1. Run installer script (handles permission issues)
2. Update AFWall+ custom script path if needed
3. Remove `#` from custom names in uid.txt
4. Change `sort_by=name` to `sort_by=custom`

### From v1.0 to v3.0
1. Run installer script
2. Add `sort_by=custom` as line 3
3. Add custom names to your apps
4. Update AFWall+ custom script command

## ⚠️ Important Notes

- **Always use installer scripts** to avoid permission errors
- **Script now in subdirectory**: `/data/local/afw/afw.sh`
- **Two-step installation** required due to root permissions
- **Custom names** are now plain strings without `#`

## 🎯 Key Commands

### Install
```bash
# Linux/Mac
./install.sh

# Windows
install.bat
```

### AFWall+ Custom Script Setting
```
nohup /data/local/afw/afw.sh > /dev/null 2>&1 &
```

### Check Installation
```bash
adb shell "su -c 'ls -la /data/local/afw/afw.sh'"
```

### Debug Mode
```bash
# Edit line 1 of uid.txt
debug=1
```

---
*Version 3.0 - Solving real-world installation issues with practical improvements*