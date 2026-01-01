@echo off
setlocal enabledelayedexpansion
mode con: cols=103 lines=22

:start
color 07
title   scrcpy Connection Manager
cls
echo ================================================================================
echo                        SCRCPY CONNECTION MANAGER                                
echo ================================================================================
echo.
echo  This program helps you connect to your Android device using scrcpy.
echo.
echo  Two connection methods available:
echo    1. WIRELESS (TCP/IP) - Connect over Wi-Fi using device IP address
echo    2. USB CABLE - Direct connection via USB cable
echo.
echo  The program will:
echo    - Store multiple device IPs for quick reconnection
echo    - Automatically troubleshoot connection issues
echo    - Fall back to alternative methods if needed
echo.
echo  ================================================================================
echo.
pause
goto choice

:choice
title   initialising....
timeout 1 /nobreak >nul
cls
echo.
echo.

rem Check if IP file exists
if not exist "%~dp0lastip.txt" (
    echo  No saved IPs found. Setting up new IP address...
    timeout 2 /nobreak >nul
    goto newip
)

rem Count saved IPs and load them
set ipcount=0
for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
    set /a ipcount+=1
    set "savedip!ipcount!=%%a"
)

if !ipcount!==0 (
    echo  No saved IPs found. Setting up new IP address...
    timeout 2 /nobreak >nul
    goto newip
)

rem Show saved IPs and ask to auto-connect
echo  Found !ipcount! saved IP address(es):
echo.
for /l %%i in (1,1,!ipcount!) do (
    echo    IP %%i: !savedip%%i!
)
echo.
echo  Do you want to automatically try all saved IPs? (1=Yes / 0=No)
set /p "autoconnect=Your choice: "

if "!autoconnect!"=="1" goto tryall
if /i "!autoconnect!"=="Y" goto tryall
if /i "!autoconnect!"=="y" goto tryall

rem If user chose not to auto-connect, show manual menu
:manualmenu
cls
echo.
echo  ================================================================================
echo                              MANUAL CONNECTION MENU
echo  ================================================================================
echo.
echo  Saved IP addresses:
echo.
for /l %%i in (1,1,!ipcount!) do (
    echo    %%i. !savedip%%i!
)
echo.
echo  Options:
echo    1 - Auto-try all saved IPs
echo    2 - Select specific IP to connect
echo    3 - Add new IP address
echo    4 - Manage saved IPs (view/remove)
echo    5 - Try USB connection
echo    0 - Exit program
echo.
set /p "menuchoice=Your choice: "

if "!menuchoice!"=="1" goto tryall
if "!menuchoice!"=="2" goto manualselect
if "!menuchoice!"=="3" goto newip
if "!menuchoice!"=="4" goto manageips
if "!menuchoice!"=="5" goto usb
if "!menuchoice!"=="0" goto exitnow
echo.
echo  Invalid choice. Please try again.
timeout 2 /nobreak >nul
goto manualmenu

:tryall
title   Trying saved IPs...

rem Check if tools are available first
where adb >nul 2>&1
if errorlevel 1 (
    echo  ================================================================================
    echo  ERROR: ADB not found in PATH
    echo  Please install Android SDK Platform Tools
    echo  ================================================================================
    pause
    goto exit
)

where scrcpy >nul 2>&1
if errorlevel 1 (
    echo  ================================================================================
    echo  ERROR: scrcpy not found in PATH
    echo  Please install scrcpy from https://github.com/Genymobile/scrcpy
    echo  ================================================================================
    pause
    goto exit
)

echo.
echo  Attempting automatic connection to all saved IPs...
echo.

for /l %%i in (1,1,!ipcount!) do (
    echo  [%%i/!ipcount!] Trying !savedip%%i!:5555...
    adb connect !savedip%%i!:5555 >nul 2>&1
    timeout 2 /nobreak >nul
    
    start /wait scrcpy -s !savedip%%i!:5555 --video-codec=h264 --max-size=1080 2>nul
    if !errorlevel!==0 (
        title   Connected to !savedip%%i!
        set "savedip=!savedip%%i!"
        echo.
        echo  Successfully connected to !savedip%%i!!
        
        rem Move successful IP to top of list
        call :moveiptotop "!savedip!"
        
        goto reconnect
    )
    echo     Failed.
    echo.
)

echo  ================================================================================
echo  All saved IPs failed to connect
echo  ================================================================================
echo.
echo  What would you like to do?
echo    1 - Retry all saved IPs again
echo    2 - Try manual troubleshooting with saved IPs
echo    3 - Add new IP address
echo    4 - Manage saved IPs (view/remove)
echo    5 - Try USB connection
echo    0 - Exit program
echo.
set /p "retry=Your choice: "
if "!retry!"=="1" goto tryall
if "!retry!"=="2" goto manualselect
if "!retry!"=="3" goto newip
if "!retry!"=="4" goto manageips
if "!retry!"=="5" goto usb
if "!retry!"=="0" goto exitnow
goto manualmenu

:manageips
cls
echo.
echo  ================================================================================
echo                           MANAGE SAVED IP ADDRESSES
echo  ================================================================================
echo.
echo  Currently saved IPs:
echo.

rem Reload IPs in case of changes
set ipcount=0
if exist "%~dp0lastip.txt" (
    for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
        set /a ipcount+=1
        set "savedip!ipcount!=%%a"
    )
)

rem Display IPs
if !ipcount!==0 (
    echo    No IPs saved.
    echo.
    echo  Press any key to return to menu...
    pause >nul
    goto manualmenu
)

for /l %%i in (1,1,!ipcount!) do (
    echo    %%i. !savedip%%i!
)

echo.
echo  Options:
echo    - Enter number (1-!ipcount!) to remove that IP
echo    - Press 0 to return to menu
echo.
set /p "removechoice=Your choice: "

if "!removechoice!"=="0" goto manualmenu

rem Check if valid number
set /a testnum=!removechoice! 2>nul
if !testnum! GEQ 1 if !testnum! LEQ !ipcount! (
    set "iptoremove=!savedip%removechoice%!"
    echo.
    echo  Are you sure you want to remove !iptoremove!? (1=Yes / 0=No)
    set /p "confirmremove=Your choice: "
    if "!confirmremove!"=="1" (
        call :removeip "!iptoremove!"
        echo.
        echo  IP !iptoremove! removed successfully!
        timeout 2 /nobreak >nul
        
        rem Check if there are still IPs left
        set tempcount=0
        if exist "%~dp0lastip.txt" (
            for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do set /a tempcount+=1
        )
        if !tempcount!==0 (
            echo  No more IPs saved. Redirecting to add new IP...
            timeout 2 /nobreak >nul
            goto newip
        )
        goto manageips
    ) else (
        goto manageips
    )
) else (
    echo.
    echo  Invalid choice. Please try again.
    timeout 2 /nobreak >nul
    goto manageips
)

:removeip
rem Create temp file without the IP to remove
set "tempfile=%~dp0temp_ips.txt"
if exist "!tempfile!" del "!tempfile!"
for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
    if not "%%a"=="%~1" (
        >>!tempfile! echo %%a
    )
)
rem Replace original file with temp file
del "%~dp0lastip.txt"
if exist "!tempfile!" (
    move "!tempfile!" "%~dp0lastip.txt" >nul
)
goto :eof

:moveiptotop
rem Move the selected IP to the top of the list
set "selectedip=%~1"
set "tempfile=%~dp0temp_ips.txt"

rem Create temp file with selected IP at top
if exist "!tempfile!" del "!tempfile!"
echo !selectedip!>!tempfile!

rem Add all other IPs (excluding the selected one)
for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
    if not "%%a"=="!selectedip!" (
        >>!tempfile! echo %%a
    )
)

rem Replace original file with reordered temp file
del "%~dp0lastip.txt"
move "!tempfile!" "%~dp0lastip.txt" >nul

rem Reload the IPs into memory
set ipcount=0
for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
    set /a ipcount+=1
    set "savedip!ipcount!=%%a"
)

goto :eof

:manualselect
cls
echo.
echo  Select an IP address to connect:
echo.
for /l %%i in (1,1,!ipcount!) do (
    echo    %%i. !savedip%%i!
)
echo.
echo    0 - Return to menu
echo.
set /p "ipchoice=Your choice: "

if "!ipchoice!"=="0" goto manualmenu

rem Check if valid number
set /a testnum=!ipchoice! 2>nul
if !testnum! GEQ 1 if !testnum! LEQ !ipcount! (
    set "savedip=!savedip%ipchoice%!"
    
    rem Move selected IP to top of list
    call :moveiptotop "!savedip!"
    
    goto connectip
)

echo.
echo  Invalid choice. Please try again.
timeout 2 /nobreak >nul
goto manualselect

:connectip
title   connecting to !savedip!...

echo.
echo  Attempting to connect to !savedip!:5555...
adb connect !savedip!:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo  Testing connection with scrcpy...
start /wait scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080 2>nul
if !errorlevel!==0 (
    title   Connected to !savedip!
    echo.
    echo  Connection successful!
    goto reconnect
)

:troubleshoot
echo.
echo  ================================================================================
echo                            CONNECTION FAILED
echo  ================================================================================
echo.
echo  Please confirm the following:
echo    - Wireless debugging is ENABLED on your device
echo    - Device IP address is correct: !savedip!
echo    - Both devices are on the SAME Wi-Fi network
echo.
echo  ================================================================================
echo.
echo  Do you want to continue with automatic troubleshooting? (1=Yes / 0=No)
set /p "continue=Your choice: "
if "!continue!"=="0" goto aftertroubleshoot
if "!continue!"=="2" goto aftertroubleshoot
if /i "!continue!"=="N" goto aftertroubleshoot
if /i "!continue!"=="n" goto aftertroubleshoot

echo.
echo  Attempting automatic fixes...
echo.
echo  [Step 1/2] Restarting ADB server...
adb kill-server >nul 2>&1
timeout 1 /nobreak >nul
adb start-server >nul 2>&1
timeout 2 /nobreak >nul

echo  [Step 2/2] Retrying connection to !savedip!:5555...
adb connect !savedip!:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo  Testing connection with scrcpy...
start /wait scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080 2>nul
if !errorlevel!==0 (
    title   Connected to !savedip!
    echo.
    echo  Connection successful!
    goto reconnect
)

echo.
echo  ================================================================================
echo  Automatic troubleshooting failed. Trying TCP/IP mode setup...
echo.
echo  IMPORTANT: Please connect your device via USB cable now
echo  ================================================================================
timeout 3 /nobreak >nul

adb tcpip 5555
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  WARNING: Failed to enable TCP/IP mode
    echo  ================================================================================
    goto aftertroubleshoot
)

timeout 2 /nobreak >nul
echo  Connecting to !savedip!:5555...
adb connect !savedip!:5555
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  ERROR: Still unable to connect
    echo  ================================================================================
    goto aftertroubleshoot
)

timeout 1 /nobreak >nul
echo  Starting scrcpy...
start /wait scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080
if !errorlevel!==0 (
    title   Connected to !savedip!
    echo.
    echo  Connection successful!
    goto reconnect
) else (
    echo.
    echo  ================================================================================
    echo  ERROR: scrcpy failed to start
    echo  ================================================================================
    echo.
    echo  This could be due to:
    echo    - Device not authorized (check device screen for prompt)
    echo    - Network connection issues
    echo    - Device screen is off
    echo.
    pause
)

:aftertroubleshoot
echo.
echo  What would you like to do next?
echo    1 - Retry with same IP
echo    2 - Try all saved IPs again
echo    3 - Enter a new IP address
echo    4 - Connect via USB instead
echo    0 - Return to main menu
echo.
set /p "retry=Your choice: "
if "!retry!"=="1" goto connectip
if "!retry!"=="2" goto tryall
if "!retry!"=="3" goto newip
if "!retry!"=="4" goto usb
if "!retry!"=="0" goto manualmenu
goto aftertroubleshoot

:usb
title   connecting via USB....
cls
echo.
echo.

rem Check if adb is available
where adb >nul 2>&1
if errorlevel 1 (
    echo  ================================================================================
    echo  ERROR: ADB not found in PATH
    echo  ================================================================================
    pause
    goto exit
)

rem Check if scrcpy is available
where scrcpy >nul 2>&1
if errorlevel 1 (
    echo  ================================================================================
    echo  ERROR: scrcpy not found in PATH
    echo  ================================================================================
    pause
    goto exit
)

echo  Checking for USB connected devices...
adb devices | findstr /R "device$" >nul
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  ERROR: No USB devices found
    echo  ================================================================================
    echo.
    echo  Please verify:
    echo    - Device is connected via USB cable
    echo    - USB debugging is ENABLED in Developer Options
    echo    - Device is AUTHORIZED (check device screen for USB debugging prompt)
    echo    - USB cable supports data transfer (not charge-only)
    echo.
    echo  ================================================================================
    echo.
    echo  What would you like to do?
    echo    1 - Retry USB connection
    echo    2 - Try wireless connection
    echo    0 - Return to menu
    echo.
    set /p "usbretry=Your choice: "
    if "!usbretry!"=="1" goto usb
    if "!usbretry!"=="2" goto manualmenu
    if "!usbretry!"=="0" goto manualmenu
    goto manualmenu
)

echo  Device detected! Starting scrcpy via USB...
start /wait scrcpy -d --video-codec=h264 --max-size=1080
if !errorlevel!==0 (
    title   Connected via USB
    set "savedip=USB"
    echo.
    echo  Connection successful!
    goto reconnect
) else (
    echo.
    echo  ================================================================================
    echo  ERROR: scrcpy failed to start
    echo  ================================================================================
    pause
    goto exit
)

:newip
title   setting up new IP connection....
cls
echo.
echo  ================================================================================
echo                           NEW IP ADDRESS SETUP
echo  ================================================================================
echo.
echo  To find your device's IP address:
echo    1. Open Settings on your Android device
echo    2. Go to: About Phone ^> Status ^> IP Address
echo       OR: Settings ^> Wi-Fi ^> Current Network ^> IP Address
echo.
echo  ================================================================================
echo.
echo  Enter your device's IP address (e.g., 192.168.18.11):
set "ipaddress="
set /p "ipaddress=IP Address: "

rem Validate IP is not empty
if not defined ipaddress (
    echo.
    echo  ERROR: No IP address entered. Please try again.
    timeout 2 /nobreak >nul
    goto newip
)

rem Remove any spaces
set "ipaddress=%ipaddress: =%"

rem Basic validation - check if it contains dots
echo %ipaddress% | findstr /C:"." >nul
if errorlevel 1 (
    echo.
    echo  ERROR: Invalid IP format
    echo  Please enter a valid IP address like 192.168.1.100
    timeout 3 /nobreak >nul
    goto newip
)

rem Check if IP already exists
set "ipalreadyexists=0"
if exist "%~dp0lastip.txt" (
    for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
        if "%%a"=="%ipaddress%" set "ipalreadyexists=1"
    )
)

if "!ipalreadyexists!"=="1" (
    echo.
    echo  ================================================================================
    echo  This IP address is already saved in your list!
    echo  ================================================================================
    echo.
    echo  What would you like to do?
    echo    1 - Connect with this IP anyway
    echo    2 - Enter a different IP
    echo    0 - Return to menu
    echo.
    set /p "existchoice=Your choice: "
    if "!existchoice!"=="1" (
        set "savedip=%ipaddress%"
        
        rem Move existing IP to top
        call :moveiptotop "!savedip!"
        
        goto connectip
    )
    if "!existchoice!"=="2" goto newip
    if "!existchoice!"=="0" goto manualmenu
    goto newip
)

rem Add new IP to top of list
set "tempfile=%~dp0temp_ips.txt"
if exist "!tempfile!" del "!tempfile!"

rem Write new IP first
echo %ipaddress%>!tempfile!

rem Add existing IPs
if exist "%~dp0lastip.txt" (
    for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
        >>!tempfile! echo %%a
    )
)

rem Replace original file
if exist "%~dp0lastip.txt" del "%~dp0lastip.txt"
move "!tempfile!" "%~dp0lastip.txt" >nul

echo.
echo  IP address %ipaddress% saved successfully at top of list!
timeout 1 /nobreak >nul

set "savedip=%ipaddress%"

rem Reload IPs
set ipcount=0
for /f "usebackq delims=" %%a in ("%~dp0lastip.txt") do (
    set /a ipcount+=1
    set "savedip!ipcount!=%%a"
)

rem Check if adb is available
where adb >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  ERROR: ADB not found in PATH
    echo  ================================================================================
    pause
    goto exit
)

rem Check if scrcpy is available
where scrcpy >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  ERROR: scrcpy not found in PATH
    echo  ================================================================================
    pause
    goto exit
)

echo.
echo  Attempting to connect to %ipaddress%:5555...
adb connect %ipaddress%:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo  Testing connection with scrcpy...
start /wait scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080 2>nul
if !errorlevel!==0 (
    title   Connected to %ipaddress%
    echo.
    echo  Connection successful!
    goto reconnect
)

goto troubleshoot

:reconnect
echo.
echo  ================================================================================
echo                         SESSION ENDED
echo  ================================================================================
echo.
if "!savedip!"=="USB" (
    echo  Would you like to:
    echo    1 - Reconnect via USB
    echo    2 - Try wireless connection
    echo    3 - Add new IP address
    echo    0 - Exit program
) else (
    echo  Would you like to:
    echo    1 - Reconnect with same IP (!savedip!)
    echo    2 - Try all saved IPs again
    echo    3 - Try different saved IP
    echo    4 - Add new IP address
    echo    0 - Exit program
)
echo.
set /p "choice=Your choice: "
if "!choice!"=="1" (
    if "!savedip!"=="USB" (
        goto usb
    ) else (
        goto connectip
    )
)
if "!choice!"=="2" (
    if "!savedip!"=="USB" (
        goto manualmenu
    ) else (
        goto tryall
    )
)
if "!choice!"=="3" (
    if "!savedip!"=="USB" (
        goto newip
    ) else (
        goto manualselect
    )
)
if "!choice!"=="4" goto newip
if "!choice!"=="0" goto exitnow
goto reconnect

:exit
title   disconnected.
cls
echo.
echo.
echo  ================================================================================
echo                         SESSION ENDED
echo  ================================================================================
echo.
echo  Would you like to:
echo    1 - Exit program
echo    2 - Return to main menu
echo    3 - Connect with new IP
echo.
set /p "choice=Your choice: "
if not defined choice goto exitnow
if "!choice!"=="1" goto exitnow
if "!choice!"=="2" goto manualmenu
if "!choice!"=="3" goto newip
echo.
echo  Invalid input. Please enter a valid option.
timeout 2 /nobreak >nul
goto exit

:exitnow
title   exiting....
cls
echo.
echo  ================================================================================
echo                     Thank you for using scrcpy Manager!
echo  ================================================================================
echo.
timeout 1 /nobreak >nul
if exist "%~dp0daw10.txt" (
    type "%~dp0daw10.txt"
) else (
    echo  Goodbye!
)
echo.
timeout 2 /nobreak >nul
cls
exit
