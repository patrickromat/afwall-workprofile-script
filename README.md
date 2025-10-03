# afwall-workprofile-script
Script solution for AFWall issue with work profile apps
Of course. Based on the complete history of our collaboration and the final version of the script you provided, here is the comprehensive README documentation suitable for a GitHub repository.

***

# Advanced AFWall+ Automation Script for Work Profiles

A powerful, self-managing script designed to extend AFWall+ functionality, providing first-class support for Android's Work Profile, dynamic UID management, and robust configuration handling.

## Table of Contents

1.  [Core Features](#1-core-features)
2.  [The Problem: Why is This Needed?](#2-the-problem-why-is-this-needed)
3.  [Prerequisites](#3-prerequisites)
4.  [Installation: One-Time Setup](#4-installation-one-time-setup)
5.  [Configuration: The `uid.txt` File](#5-configuration-the-uidtxt-file)
6.  [Advanced Usage: Backup, Restore & Migration](#6-advanced-usage-backup-restore--migration)
7.  [Convenience Tip: Homescreen Shortcut](#7-convenience-tip-homescreen-shortcut)
8.  [Technical Deep Dive: How It Works](#8-technical-deep-dive-how-it-works)
9.  [Example Configuration Files](#9-example-configuration-files)
10. [The Final Script: `afw.sh`](#10-the-final-script-afwsh)

---

### 1. Core Features

*   **First-Class Work Profile Support:** All operations are targeted specifically at the Work Profile (`user 10`), allowing you to control work apps by their familiar package names.
*   **Dynamic UID Management:** Automatically finds the correct User ID (UID) for an application based on its package name, and vice-versa.
*   **Self-Managing Configuration:** Intelligently updates its own config file, converting package names to UIDs for performance while keeping human-readable names for easy editing.
*   **Concurrency Protection:** A robust locking mechanism prevents file corruption from simultaneous script executions (e.g., during rapid network changes).
*   **High Performance & Flexibility:** Applies firewall rules based on the most up-to-date data *before* performing slower file maintenance tasks.
*   **Fully Configurable:** Key behaviors like target chains and parallel execution are controlled by simple switches.
*   **Full IPv4 & IPv6 Support:** Ensures rules are applied consistently across both network protocols by inserting (`-I`) them at the top of the firewall chains for high priority.
*   **Advanced Debug & Performance-Tuning:** An optional debug mode provides detailed reports, execution timers, and previews without making any live changes.

### 2. The Problem: Why is This Needed?

On modern Android versions (Android 12+), AFWall+'s ability to manage applications within the sandboxed **Work Profile** (also known as Dual Apps, Secure Folder, etc.) has become less reliable. These apps run under a separate user space and are often difficult to identify and control through the firewall's GUI.

This script solves that problem by using the command-line `pm` tool to directly query the Android system for application UIDs within the Work Profile, providing a reliable and future-proof way to manage their network access. It automates the entire process, turning a complex manual task into a simple, editable text file.

### 3. Prerequisites

| Type        | Requirement                                                                      |
| :---------- | :------------------------------------------------------------------------------- |
| **Device**  | A **rooted** Android device.                                                     |
| **Skillset**  | Basic understanding of command-line interfaces (like Termux or ADB).             |
|             | Familiarity with Android file systems (`/data/`, `/sdcard/`).                    |
| **Tools**     | A computer with **ADB (Android Debug Bridge)** installed for the one-time setup. |
|             | A text editor on your Android device (e.g., QuickEdit).                          |
|             | (Optional) A root-capable file explorer (e.g., MiXplorer).                       |

### 4. Installation: One-Time Setup

Follow these steps carefully to install and configure the script.

1.  **Connect your device to your computer** and ensure ADB is authorized. Open a terminal or command prompt.

2.  **Create the script directory** on your device's internal storage:
    ```bash
    adb shell "mkdir -p /sdcard/afw/"
    ```

3.  **Create the initial configuration file (`uid.txt`)** on your computer. Copy the contents from the [Example Config Files](#9-example-configuration-files) section into a new file named `uid.txt`.

4.  **Push the configuration file** to your device:
    ```bash
    adb push uid.txt /sdcard/afw/
    ```

5.  **Create the script file (`afw.sh`)** on your computer. Copy the entire script from [The Final Script](#10-the-final-script-afwsh) section below into a new file named `afw.sh`.

6.  **Push the script file** to a persistent location on your device. `/data/local/` is a standard choice.
    ```bash
    adb push afw.sh /data/local/afw.sh
    ```

7.  **Make the script executable:**
    ```bash
    adb shell "chmod 755 /data/local/afw.sh"
    ```

8.  **Configure AFWall+ to run the script:**
    *   Open AFWall+.
    *   Go to the menu (three dots) > **Set custom script**.
    *   In the text box, enter the following command. This ensures the script runs reliably in the background and does not block AFWall+.
        ```
        nohup /data/local/afw.sh > /dev/null 2>&1 &
        ```
    *   Tap **Save**.

The setup is now complete. Every time you tap "Apply" in AFWall+, the script will execute.

### 5. Configuration: The `uid.txt` File

This is the only file you will ever need to edit.

*   **Line 1: `debug=0` or `debug=1`**
    *   `debug=0`: **Normal Operation.** The script runs silently (logging to `logcat`) and makes permanent changes to your firewall and the `uid.txt` file.
    *   `debug=1`: **Debug Mode.** The script prints detailed reports, execution timers, and previews to the shell (run via `adb shell`). It makes **no changes** to your system.
*   **Line 2: `recalculate=0` or `recalculate=1`**
    *   `recalculate=0`: **Normal Operation.** The script trusts existing UIDs and only looks up missing information.
    *   `recalculate=1`: **Force Recalculation.** On the next run, the script will re-verify the UID for every single package name in the file. It will then automatically reset this value to `0` in the file. This is essential for device migrations (see next section).
*   **Data Lines (Line 3 onwards):** You can use three formats. The script will automatically organize them.
    1.  **UID First (Recommended):** `1010384 com.alibaba.aliexpresshd aliexpress app`
    2.  **Package Name First:** `com.microsoft.emmx Work Profile Edge Browser`
    3.  **UID or Package Name Only:** `1010411` or `pl.allegro`

### 6. Advanced Usage: Backup, Restore & Migration

This script makes migrating your firewall rules to a new device or a fresh ROM installation incredibly simple.

**The Problem:** An application's UID is **not permanent**. It is assigned by the Android system during installation and will be different on a new device. Simply copying your old `uid.txt` file would result in rules for incorrect UIDs.

**The Solution:** The `recalculate=1` flag was designed for this. It tells the script to ignore the old, invalid UIDs and use the human-readable package names—which are permanent—to look up the new, correct UIDs on the new system.

#### Step-by-Step Migration Guide:

1.  **Backup (Old Device):** Save a copy of `/sdcard/afw/uid.txt`. This is your master list.
2.  **Setup (New Device):** Perform the complete [One-Time Setup](#4-installation-one-time-setup).
3.  **Restore (New Device):** Copy your backed-up `uid.txt` file to `/sdcard/afw/` on the new device, overwriting the blank one.
4.  **Activate Recalculation:** Open the restored `uid.txt` file and **change the second line to `recalculate=1`**. Save the file.
5.  **Trigger the Script:** Open AFWall+ and tap **"Apply"**.

The script will run, find all the new UIDs for your apps, apply the correct firewall rules, and rewrite the `uid.txt` file with the updated information, automatically setting `recalculate=0` for the next run.

### 7. Convenience Tip: Homescreen Shortcut

To make editing your app list easier, create a shortcut to `uid.txt` on your homescreen.

**Example using MiXplorer:**

1.  Navigate to `/sdcard/afw/`.
2.  Long-press on `uid.txt` to select it.
3.  Tap the menu (three dots) > **Add to** > **Shortcut**.
4.  The shortcut will be placed on your homescreen for one-tap access.

### 8. Technical Deep Dive: How It Works

The script operates in distinct phases for stability and performance.

#### Process Flow

```
        [ START ]
            |
            V
  [ Acquire Lock? ] --(No)--> [ RUN_PARALLEL=true? ] --(No)--> [ EXIT ]
            |                               |
           (Yes)                           (Yes)
            |                               V
            V                  (Read-Only, No File Write)
  [ PHASE 1: Parse uid.txt ]
            |
            V
  [ PHASE 2: Augment Data (Fill Blanks) ]
            |
            V
  [ PHASE 3: Recalculate? (If flag=1) ]
            |
            V
  [ PHASE 4: Apply FINAL IPTABLES Rules ]
            |
            V
  [ PHASE 5: Write uid.txt File? ] --(Only if Lock Acquired)
            |
            V
         [ END ]
```

*   **Phase 0: Lock Acquisition:** Atomically creates a lock directory. The first instance to succeed gains write-access.
*   **Phase 1: Parse:** Reads and parses `uid.txt` into an in-memory structure (UID, package name, comments).
*   **Phase 2: Augment:** Fills in any missing UIDs or package names by querying the `pm` service.
*   **Phase 3: Recalculate:** If `recalculate=1`, this phase re-queries the UID for every package name, ensuring data is correct for the current system.
*   **Phase 4: Apply Rules:** With the final, validated data, it loops through each UID and inserts (`-I`) firewall rules for both IPv4 and IPv6 into the configured `TARGET_CHAINS`.
*   **Phase 5: Write File:** If the script instance holds the lock, it writes the cleaned-up data back to `uid.txt` and resets the `recalculate` flag if needed.

### 9. Example Configuration Files

#### Example `uid.txt`

```
debug=0
recalculate=0
# --- Browsers ---
# Allow Work Profile Chrome by its package name
com.android.chrome

# --- Communication ---
# Allow WhatsApp using its UID and add a comment
1010211 com.whatsapp Work Profile WhatsApp

# --- Utilities ---
# Add a file explorer. The script will find its UID.
com.mixplorer.silver

# Add a maps client. The script will find the package name.
1010150
```
