@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cls

:: Set base directory to where the script is located
set "BASEDIR=%~dp0"
set "IPFILE=%BASEDIR%lastip.txt"
set "GOODBYE=%BASEDIR%daw11.txt"

:choice
title Initialising...
timeout /t 1 /nobreak >nul
cls
echo.
echo.

:: Check if lastip.txt exists in script's folder
if not exist "%IPFILE%" goto newip
set /p savedip=<"%IPFILE%"
if "%savedip%"=="" goto newip

echo    ╔══════════════════════════════════════╗
echo    ║        SCRCPY QUICK CONNECTOR        ║
echo    ╚══════════════════════════════════════╝
echo.
echo    [1] Connect using saved IP (%savedip%)
echo    [0,2,6] USB Mode
echo    [4] Back / Restart
echo.
set "starwars="
set /p "starwars=Choose → "
if not defined starwars goto choice
if "%starwars%"=="1" goto ip
if "%starwars%"=="0" goto usbstart
if "%starwars%"=="2" goto usbstart
if "%starwars%"=="6" goto usbstart
if "%starwars%"=="4" goto choice
goto choice

:ip
title Connecting to %savedip%...
adb tcpip 5555 >nul 2>&1
adb connect %savedip%:5555
echo.
echo Connecting to %savedip%:5555 ...
scrcpy -s %savedip%:5555 --video-codec=h264 --max-size=1080 --tcpip=%savedip%
title Connected - %savedip%
pause
goto exit

:usbstart
cls
echo.
echo    [1] Connect via USB
echo    [0,2] Enter new WiFi IP
echo    [4] Back to main menu
echo.
set "starwars="
set /p "starwars=Choose → "
if not defined starwars goto usbstart
if "%starwars%"=="1" goto usb
if "%starwars%"=="0" goto newipstart
if "%starwars%"=="2" goto newipstart
if "%starwars%"=="6" goto newipstart
if "%starwars%"=="4" goto choice
goto usbstart

:usb
title Connecting via USB...
adb devices
echo.
echo Starting scrcpy in USB mode...
scrcpy -d --video-codec=h264 --max-size=1080
title Connected (USB)
pause
goto exit

:newipstart
cls
echo.
echo    [1] Enter new IP address
echo    [0,2] Back to main menu
echo    [6] Exit
echo.
set "starwars="
set /p "starwars=Choose → "
if not defined starwars goto newipstart
if "%starwars%"=="1" goto newip
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="6" goto exitnow
goto newipstart

:newip
title Enter New IP Address
echo.
echo  Example: 192.168.1.150
echo.
set "ipaddress="
set /p "ipaddress=Enter IP → "
if not defined ipaddress goto newip
echo %ipaddress%>"%IPFILE%"

adb tcpip 5555 >nul 2>&1
adb connect %ipaddress%:5555
echo.
echo Connecting to %ipaddress%:5555 ...
scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080 --tcpip=%ipaddress%
title Connected - %ipaddress%
pause
goto exit

:exit
title Disconnected
echo.
echo    [1] Exit
echo    [0,2] Back to menu
echo    [4,6] Change / Enter new IP
echo.
set "starwars="
set /p "starwars=Choose → "
if not defined starwars goto exitnow
if "%starwars%"=="1" goto exitnow
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="4" goto newipstart
if "%starwars%"=="6" goto newipstart
goto exit

:exitnow
title Goodbye...
cls
echo.
echo  Closing in a moment...
timeout /t 1 /nobreak >nul

:: Show custom goodbye message if daw11.txt exists in same folder
if exist "%GOODBYE%" (
    echo.
    type "%GOODBYE%"
    timeout /t 3 /nobreak >nul
)

cls
echo  Bye!
timeout /t 1 /nobreak >nul
endlocal
exit
