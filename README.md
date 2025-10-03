# Advanced AFWall+ Automation Script for Work Profiles

A powerful, self-managing script designed to extend AFWall+ functionality, providing first-class support for Android's Work Profile, dynamic UID management, and robust configuration handling.

## Table of Contents
1.  [Core Features](#1-core-features)
2.  [The Problem: Why is This Needed?](#2-the-problem-why-is-this-needed)
3.  [Prerequisites](#3-prerequisites)
4.  [Installation: One-Time Setup](#4-installation-one-time-setup)
5.  [Managing Your App List (`uid.txt`)](#5-managing-your-app-list-uidtxt)
    *   [Recommended Tool: X-plore File Manager](#recommended-tool-x-plore-file-manager)
    *   [How to Add a New App to the Firewall](#how-to-add-a-new-app-to-the-firewall)
6.  [Advanced Usage: Backup, Restore & Migration](#6-advanced-usage-backup-restore--migration)
7.  [Technical Deep Dive: How It Works](#7-technical-deep-dive-how-it-works)
8.  [Example Configuration Files](#8-example-configuration-files)
9.  [The Final Script: `afw.sh`](#9-the-final-script-afwsh)

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
|             | A text editor on your Android device (e.g., QuickEdit, X-plore's built-in).      |
|             | A root-capable file explorer (e.g., MiXplorer, X-plore).                         |

### 4. Installation: One-Time Setup

Follow these steps carefully to install and configure the script.

1.  **Connect your device to your computer** and ensure ADB is authorized. Open a terminal or command prompt.

2.  **Create the script directory** on your device's internal storage:
    ```bash
    adb shell "mkdir -p /sdcard/afw/"
    ```

3.  **Create the configuration file (`uid.txt`)**. Using a text editor on your computer, create a new file named `uid.txt`. Copy the contents from the [Example Configuration Files](#8-example-configuration-files) section into it.

4.  **Push the configuration file** to your device:
    ```bash
    adb push uid.txt /sdcard/afw/
    ```

5.  **Create the script file (`afw.sh`)**. On your computer, create a new file named `afw.sh`. Copy the entire script from [The Final Script](#9-the-final-script-afwsh) section below into this file.

6.  **Push the script file** to a persistent location on your device. `/data/local/` is a standard choice.
    ```bash
    adb push afw.sh /data/local/afw.sh
    ```

7.  **Make the script executable**. This is a critical step.
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

### 5. Managing Your App List (`uid.txt`)

This section explains the day-to-day use of the script: adding new apps to your firewall rules.

#### Recommended Tool: X-plore File Manager

X-plore is an excellent root file explorer with a built-in text editor, making it a perfect all-in-one tool for this task.

**How to Edit `uid.txt` with X-plore:**
1.  Open X-plore.
2.  Navigate to `/sdcard/afw/`.
3.  Long-press on `uid.txt`.
4.  From the menu, select **Edit Text**.
5.  Make your changes and save the file.

**How to Create a Homescreen Shortcut with X-plore:**
1.  Navigate to `/sdcard/afw/`.
2.  Long-press on `uid.txt` to select it.
3.  Tap the **More** button in the action bar at the bottom.
4.  Choose **Create Shortcut**.
5.  A shortcut will be placed on your homescreen for one-tap access.

#### How to Add a New App to the Firewall

There are two primary ways to add an app. Using the package name is easiest.

**Method 1: By Package Name (Recommended)**

This is the simplest and most reliable method.

1.  **Find the app's package name.** You have two easy options:
    *   **From the Play Store:** Open the app's page in the Play Store. Look at the URL in your browser's address bar. The package name is the part after `id=`.
        *   `.../details?id=**com.google.android.apps.maps**` -> The package name is `com.google.android.apps.maps`.
    *   **Using an App Manager:** Install a tool like **App Manager** (available on F-Droid) *inside your Work Profile*. Open it, find your app, and its package name will be listed prominently (e.g., `org.videolan.vlc`).

2.  **Edit your `uid.txt` file.**
3.  Go to a new line and simply type the package name you found. You can add a comment after it.
    ```
    com.google.android.apps.maps  # Google Maps in Work Profile
    ```
4.  **Save the file.**
5.  **Apply rules in AFWall+.**

The script will automatically run, see the new package name, find its correct UID, apply the firewall rules, and then rewrite the `uid.txt` file for you, placing the new UID at the start of the line.

**Method 2: By UID (Advanced)**

This method is useful if you prefer to work with UIDs directly.

1.  **Install an App Manager** (like App Manager from F-Droid) *inside your Work Profile*.
2.  Open App Manager and find the app you want to add.
3.  Note its **UID** (sometimes called App ID). It will be a number like `1010444`.
4.  **Edit your `uid.txt` file.**
5.  Go to a new line and type the UID.
    ```
    1010444
    ```
6.  **Save the file.**
7.  **Apply rules in AFWall+.**

The script will run, see the new UID, apply the firewall rules, and then perform a reverse-lookup to find the matching package name, which it will add to the line for you.

### 6. Advanced Usage: Backup, Restore & Migration

This script makes migrating your firewall rules to a new device or a fresh ROM installation incredibly simple.

**The Problem:** An application's UID is **not permanent**. It is assigned by the Android system during installation and will be different on a new device. Simply copying your old `uid.txt` file would result in rules for incorrect UIDs.

**The Solution:** The `recalculate=1` flag was designed for this. It tells the script to ignore the old, invalid UIDs and use the human-readable package names—which are permanent—to look up the new, correct UIDs on the new system.

#### Step-by-Step Migration Guide:

1.  **Backup (Old Device):** Save a copy of `/sdcard/afw/uid.txt`.
2.  **Setup (New Device):** Perform the complete [One-Time Setup](#4-installation-one-time-setup).
3.  **Restore (New Device):** Copy your backed-up `uid.txt` file to `/sdcard/afw/` on the new device.
4.  **Activate Recalculation:** Open the restored `uid.txt` file and **change the second line to `recalculate=1`**.
5.  **Trigger the Script:** Open AFWall+ and tap **"Apply"**.

The script will run, find all the new UIDs for your apps, apply the correct firewall rules, and rewrite the `uid.txt` file with the updated information, automatically setting `recalculate=0` for the next run.

### 7. Technical Deep Dive: How It Works

The script operates in distinct, sequential phases for stability and performance.

*   **Phase 0: Lock Acquisition:** Atomically creates a lock directory. The first instance to succeed gains write-access.
*   **Phase 1: Parse:** Reads `uid.txt` into an in-memory structure (UID, package name, comments).
*   **Phase 2: Augment:** Fills in any missing UIDs or package names by querying the `pm` service.
*   **Phase 3: Recalculate:** If `recalculate=1`, this phase re-queries the UID for every package name.
*   **Phase 4: Apply Rules:** With the final, validated data, it loops through each UID and inserts (`-I`) firewall rules for both IPv4 and IPv6 into the configured `TARGET_CHAINS`.
*   **Phase 5: Write File:** If the script instance holds the lock, it writes the cleaned-up data back to `uid.txt`.

### 8. Example Configuration Files

#### `uid.txt`
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
