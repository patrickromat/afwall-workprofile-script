@echo off
REM AFWall+ Work Profile Script v3.0 - Windows Installation Helper

echo ================================================
echo AFWall+ Work Profile Script v3.0 - Installer
echo ================================================
echo.
echo Prerequisites:
echo - ADB connected to your rooted Android device
echo - AFWall+ installed with root access granted
echo - Work Profile created (user 10)
echo.
set /p CONTINUE="Continue with installation? (y/n): "

if /i "%CONTINUE%" NEQ "y" (
    echo Installation cancelled.
    exit /b 1
)

REM Check ADB connection
echo.
echo Checking ADB connection...
adb devices | findstr "device$" >nul
if errorlevel 1 (
    echo ERROR: No ADB device found. Please connect your device with USB debugging enabled.
    exit /b 1
)

echo Device found!
echo.

REM Step 1: Create directories
echo Step 1: Creating directories...

REM Create config directory (user accessible)
adb shell "mkdir -p /sdcard/afw/" 2>nul
if %errorlevel% == 0 (
    echo √ Created /sdcard/afw/
) else (
    echo × Failed to create /sdcard/afw/
    exit /b 1
)

REM Create script directory with root
echo Creating /data/local/afw/ with root permissions...
adb shell "su -c 'mkdir -p /data/local/afw/'" 2>nul
if %errorlevel% == 0 (
    echo √ Created /data/local/afw/ [root]
) else (
    echo ! Could not create /data/local/afw/ with root
    echo   Will try alternative installation method...
)

REM Step 2: Push and install script
echo.
echo Step 2: Installing script...
if exist "afw.sh" (
    echo Uploading script to temporary location...
    adb push afw.sh /sdcard/afw/afw.sh.tmp
    if %errorlevel% == 0 (
        echo √ Script uploaded to temp location
        
        echo Moving script to final location with root...
        adb shell "su -c 'cp /sdcard/afw/afw.sh.tmp /data/local/afw/afw.sh && chmod 755 /data/local/afw/afw.sh && rm /sdcard/afw/afw.sh.tmp'"
        if %errorlevel% == 0 (
            echo √ Script installed with correct permissions
        ) else (
            echo × Failed to move script with root permissions
            echo.
            echo Manual installation required:
            echo 1. Copy /sdcard/afw/afw.sh.tmp to /data/local/afw/afw.sh
            echo 2. Run: chmod 755 /data/local/afw/afw.sh
            echo 3. Delete: /sdcard/afw/afw.sh.tmp
        )
    ) else (
        echo × Failed to upload script
        exit /b 1
    )
) else (
    echo × afw.sh not found in current directory
    exit /b 1
)

REM Step 3: Push config
echo.
echo Step 3: Installing configuration...
if exist "uid.txt" (
    adb push uid.txt /sdcard/afw/uid.txt
    if %errorlevel% == 0 (
        echo √ Configuration uploaded
    ) else (
        echo × Failed to upload configuration
        exit /b 1
    )
) else (
    echo × uid.txt not found in current directory
    exit /b 1
)

REM Step 4: Verify installation
echo.
echo Step 4: Verifying installation...
adb shell "su -c 'ls -la /data/local/afw/afw.sh'" 2>nul | findstr "rwx" >nul
if %errorlevel% == 0 (
    echo √ Script is installed and executable
) else (
    echo × Script verification failed
    echo   You may need to manually install the script
)

adb shell "test -f /sdcard/afw/uid.txt"
if %errorlevel% == 0 (
    echo √ Configuration file exists
) else (
    echo × Configuration file not found
)

REM Step 5: Check Work Profile
echo.
echo Step 5: Checking Work Profile...
adb shell "pm list users" | findstr "UserInfo{10" >nul
if %errorlevel% == 0 (
    echo √ Work Profile found
) else (
    echo ! Work Profile ^(user 10^) not found!
    echo   You may need to create a Work Profile using Island, Shelter, or Dual Apps
)

REM Final instructions
echo.
echo ================================================
echo Installation Complete!
echo ================================================
echo.
echo Final steps in AFWall+:
echo 1. Open AFWall+
echo 2. Go to Menu → Set custom script
echo 3. Enter exactly: nohup /data/local/afw/afw.sh ^> /dev/null 2^>^&1 ^&
echo 4. Tap OK to save
echo 5. Tap Apply to run the script
echo.
echo To edit your app list:
echo - Edit /sdcard/afw/uid.txt on your device
echo - Add apps in format: com.app.package Custom Name
echo - ALWAYS tap Apply in AFWall+ after editing!
echo.
echo Enable debug mode by changing line 1 to debug=1 in uid.txt
echo.
echo For troubleshooting, check logs with:
echo adb shell "logcat -d | grep afwall_custom"
echo.
pause