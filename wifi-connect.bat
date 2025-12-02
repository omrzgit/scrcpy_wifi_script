@echo off
setlocal enabledelayedexpansion

:: Set the folder where the script is running as base directory
set "BASEDIR=%~dp0"
set "IPFILE=%BASEDIR%lastip.txt"

:choice
title initialising....
timeout 1 /nobreak >nul
cls
echo.
echo.

:: Check if lastip.txt exists in the current folder
if not exist "%IPFILE%" goto newip
set /p savedip=<"%IPFILE%"
if "%savedip%"=="" goto newip

echo ip? 1/0 (1=use saved IP, 0/2/6=USB, 4=back)
set "starwars="
set /p "starwars=input: "
if not defined starwars goto choice
if "%starwars%"=="1" goto ip
if "%starwars%"=="0" goto usbstart
if "%starwars%"=="2" goto usbstart
if "%starwars%"=="6" goto usbstart
if "%starwars%"=="4" goto choice
goto choice

:ip
title connecting....
adb tcpip 5555
adb connect %savedip%:5555
echo Trying to connect to %savedip%:5555 ...
scrcpy -s %savedip%:5555 --video-codec=h264 --max-size=1080
title Connected.
pause
goto exit

:usbstart
cls
echo.
echo.
echo usb? 1/0 (1=USB mode, 0/2=re-enter IP, 4=back)
set "starwars="
set /p "starwars=input: "
if not defined starwars goto usbstart
if "%starwars%"=="1" goto usb
if "%starwars%"=="0" goto newipstart
if "%starwars%"=="2" goto newipstart
if "%starwars%"=="6" goto newipstart
if "%starwars%"=="4" goto choice
goto usbstart

:usb
title connecting via USB....
adb devices
scrcpy -d --video-codec=h264 --max-size=1080
title Connected.
pause
goto exit

:newipstart
cls
echo.
echo.
echo newip? 1/0 (1=enter new IP, 0/2=back, 6=exit)
set "starwars="
set /p "starwars=input: "
if not defined starwars goto newipstart
if "%starwars%"=="1" goto newip
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="6" goto exitnow
if "%starwars%"=="4" goto newipstart
goto newipstart

:newip
title entering new IP....
echo.
echo Enter IP address (example: 192.168.1.100):
set "ipaddress="
set /p "ipaddress=IP: "
if not defined ipaddress goto newip

:: Save the new IP in the same folder as the script
echo %ipaddress%>"%IPFILE%"

adb tcpip 5555
adb connect %ipaddress%:5555
echo Trying to connect to %ipaddress%:5555 ...
scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080
title Connected.
pause
goto exit

:exit
title disconnected.
echo.
echo exit? 1/0 (1=exit, 0/2=back to menu, 4/6=new IP)
set "starwars="
set /p "starwars=input: "
if not defined starwars goto exitnow
if "%starwars%"=="1" goto exitnow
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="4" goto newipstart
if "%starwars%"=="6" goto newipstart
goto exit

:exitnow
title exiting....
timeout 1 /nobreak >nul
cls
echo Bye!
timeout 1 /nobreak >nul
endlocal
exit /b