# AFWall+ Work Profile Script - Complete How-To Guide

## 📱 Table of Contents

1. [Creating Homescreen Shortcuts](#creating-homescreen-shortcuts)
2. [Finding UIDs and Package Names](#finding-uids-and-package-names)
3. [Troubleshooting xtables Lock Issues](#troubleshooting-xtables-lock-issues)

---

## 1. Creating Homescreen Shortcuts

Easy one-tap access to edit your uid.txt file!

### Method A: X-plore File Manager (Recommended)

**Step 1: Navigate to the file**
- Open X-plore
- Navigate to `/sdcard/afw/`
- Find `uid.txt`

**Step 2: Create shortcut**
- **Long-press** on `uid.txt`
- Select **"Create Shortcut"** or **"Add to Home Screen"**
- Choose location on homescreen

**Step 3: Edit anytime**
- Tap the homescreen shortcut
- Edit the file
- Save changes
- **Remember: Tap Apply in AFWall+ after editing!**

![X-plore Screenshot Placeholder - Long press uid.txt → Create Shortcut]

---

### Method B: MiXplorer File Manager

**Step 1: Navigate to the file**
- Open MiXplorer
- Navigate to `/sdcard/afw/`
- Find `uid.txt`

**Step 2: Create shortcut**
- **Long-press** on `uid.txt`
- Tap **⋮** (More options)
- Select **"Add shortcut"**
- Name it (e.g., "AFWall Config")
- Shortcut appears on homescreen

**Step 3: Edit anytime**
- Tap the homescreen shortcut
- Edit with built-in text editor
- Save changes
- **Remember: Tap Apply in AFWall+ after editing!**

![MiXplorer Screenshot Placeholder - More options → Add shortcut]

---

### Method C: Solid Explorer

**Step 1: Navigate to the file**
- Open Solid Explorer
- Navigate to `/sdcard/afw/`
- Find `uid.txt`

**Step 2: Create shortcut**
- **Long-press** on `uid.txt`
- Tap **⋮** (three dots menu)
- Select **"Create shortcut"**
- Shortcut appears on homescreen

**Step 3: Edit anytime**
- Tap the homescreen shortcut
- Edit with text editor
- Save changes
- **Remember: Tap Apply in AFWall+ after editing!**

![Solid Explorer Screenshot Placeholder - Menu → Create shortcut]

---

### Method D: Total Commander

**Step 1: Navigate to the file**
- Open Total Commander
- Navigate to `/sdcard/afw/`
- Find `uid.txt`

**Step 2: Create shortcut**
- **Long-press** on `uid.txt`
- Tap **File operations** button
- Select **"Send to" → "Desktop shortcut"**
- Shortcut appears on homescreen

**Step 3: Edit anytime**
- Tap the homescreen shortcut
- Edit with text editor
- Save changes
- **Remember: Tap Apply in AFWall+ after editing!**

---

## 2. Finding UIDs and Package Names

Two reliable methods to find app information for your Work Profile apps.

### Method A: App Manager (Recommended) 🎯

**App Manager** is a powerful open-source app manager that shows detailed app information.

**Installation:**
- Download from F-Droid, IzzyOnDroid, or GitHub
- Grant necessary permissions
- Enable Work Profile support

**Finding UID and Package Name:**

**Step 1: Open App Manager**
- Launch App Manager
- Switch to **Work Profile** tab (user icon at top)

![App Manager Screenshot Placeholder - Work Profile tab selected]

**Step 2: Find your app**
- Scroll or search for the app
- Tap on the app to open details

**Step 3: View UID and Package**
- **Package name** is shown at the top (e.g., `com.spotify.music`)
- Scroll down to **"App Info"** section
- **UID** is shown (e.g., `1010444`)
- **Long-press to copy** either value

![App Manager Screenshot Placeholder - App details showing UID and package]

**Step 4: Add to uid.txt**
```
1010444 com.spotify.music Spotify Music
```

**Pro Tips:**
- Use the **search** function to find apps quickly
- You can **share** app info directly
- App Manager works without root for basic info
- Shows both **main profile** and **Work Profile** apps

---

### Method B: ADB Commands

If you prefer command-line tools, use ADB to query package information.

**Prerequisites:**
- ADB installed on computer
- USB debugging enabled on phone
- Device connected via USB or WiFi

#### Finding Package Names

**Search by keyword:**
```bash
# List all packages containing "spotify"
adb shell "pm list packages | grep spotify"

# Output example:
# package:com.spotify.music
```

**List all Work Profile packages:**
```bash
# List all packages in Work Profile (user 10)
adb shell "pm list packages --user 10"
```

**Search in Work Profile only:**
```bash
# Find packages containing "chrome" in Work Profile
adb shell "pm list packages --user 10 | grep chrome"
```

---

#### Finding UIDs

**Get UID for a specific package:**
```bash
# Get UID for com.spotify.music in Work Profile
adb shell "pm list packages --user 10 -U | grep com.spotify.music"

# Output example:
# package:com.spotify.music uid:1010444
```

**Get UID from the output:**
```bash
# Extract just the UID
adb shell "pm list packages --user 10 -U | grep com.spotify.music" | cut -d':' -f3

# Output:
# 1010444
```

---

#### Finding Package from UID

**If you have a UID and need the package:**
```bash
# Find package for UID 1010444 in Work Profile
adb shell "pm list packages --user 10 --uid 1010444"

# Output example:
# package:com.spotify.music
```

---

#### Bulk Export

**Export all Work Profile apps with UIDs:**
```bash
# Create a list of all Work Profile packages with UIDs
adb shell "pm list packages --user 10 -U" > work_profile_apps.txt

# View the file
cat work_profile_apps.txt
```

**Parse and format for uid.txt:**
```bash
# Extract package and UID, format for uid.txt
adb shell "pm list packages --user 10 -U" | sed 's/package://; s/ uid:/ /' | awk '{print $2, $1, "App Name"}'

# Output format:
# 1010444 com.spotify.music App Name
# 1010445 com.chrome Chrome
```

---

### Method C: Quick Terminal Method (On-Device)

If you have a terminal app on your phone (like Termux):

**Find package:**
```bash
su
pm list packages --user 10 | grep keyword
```

**Find UID:**
```bash
su
pm list packages --user 10 -U | grep package.name
```

---

## 3. Troubleshooting xtables Lock Issues

### Understanding the Error

**Error message:**
```
Another app is currently holding the xtables lock. Perhaps you want to use the -w option?
Can't lock /system/etc/xtables.lock: Try again
```

**What this means:**
- Another process is modifying iptables rules simultaneously
- AFWall+ or another firewall app is running
- Multiple script instances trying to apply rules at once

---

### How v1.1 Fixes This ✅

The script now **automatically detects and uses** the `-w` flag when supported:

**What it does:**
1. Tests if your iptables supports `-w` flag
2. If supported: Uses `-w 5` (wait up to 5 seconds for lock)
3. If not supported: Uses regular commands (older Android)

**In the script:**
```bash
# Automatic detection
if $IPTABLES -w 1 -L -n >/dev/null 2>&1; then
    IPTABLES_SUPPORTS_WAIT=true
fi

# Automatic usage
if [ "$IPTABLES_SUPPORTS_WAIT" = "true" ]; then
    $IPTABLES -w 5 -I "$chain" -m owner --uid-owner "$uid" -j RETURN
else
    $IPTABLES -I "$chain" -m owner --uid-owner "$uid" -j RETURN
fi
```

**Configuration:**
The wait time is set in the script:
```bash
IPTABLES_WAIT=5  # Wait up to 5 seconds for lock
```

You can change this value if needed (range: 1-60 seconds).

---

### Debug Information

**Enable debug mode to see if `-w` is supported:**

```bash
# Edit uid.txt line 1:
debug=1

# Then tap Apply in AFWall+
# Check output:
adb shell "logcat -d | grep IPTABLES"
```

**Output will show:**
```
[IPTABLES] iptables supports -w flag (will wait for lock)
```
or
```
[IPTABLES-WARN] iptables does NOT support -w flag (older version)
```

---

### Manual Testing

**Test if your device supports `-w` flag:**

```bash
# Test iptables with -w flag
adb shell "su -c 'iptables -w 1 -L -n'"

# If it works: Your device supports -w
# If it fails: Your device doesn't support -w (older Android)
```

**Check iptables version:**
```bash
adb shell "su -c 'iptables --version'"

# Newer versions (1.4.14+) support -w
# Older versions don't
```

---

### Alternative Solutions

If you still experience lock issues:

**Solution 1: Increase wait time**
Edit `afw.sh` line 19:
```bash
IPTABLES_WAIT=10  # Increase from 5 to 10 seconds
```

**Solution 2: Disable parallel execution**
Edit `afw.sh` line 23:
```bash
RUN_PARALLEL=false  # Already set to false by default
```

**Solution 3: Check for conflicting apps**
```bash
# See what's using iptables:
adb shell "su -c 'lsof /system/etc/xtables.lock'"

# Kill the process if needed:
adb shell "su -c 'kill -9 PID'"
```

**Solution 4: Restart AFWall+**
- Force stop AFWall+
- Clear AFWall+ cache (optional)
- Restart AFWall+
- Try again

---

### Prevention Tips

**Best practices to avoid lock conflicts:**

1. ✅ **Don't run multiple firewall apps** simultaneously
2. ✅ **Let script finish** before applying rules again
3. ✅ **Use debug mode** to monitor timing
4. ✅ **Keep AFWall+ updated** to latest version
5. ✅ **Reboot device** after major firewall changes

---

## 🎉 Summary

### Homescreen Shortcut
- Use any file manager (X-plore, MiXplorer, Solid Explorer, Total Commander)
- Long-press uid.txt → Create Shortcut
- One-tap editing!

### Finding UIDs/Packages
- **Best method**: App Manager (visual, easy)
- **Alternative**: ADB commands (batch operations)
- **Quick**: On-device terminal

### xtables Lock
- **Fixed in v1.1**: Automatic `-w 5` support
- Tests compatibility automatically
- Works on old and new Android versions
- Configurable wait time if needed

---

**Remember:** Always tap **Apply** in AFWall+ after editing uid.txt!

*Screenshots to be added - showing actual file manager interfaces*
