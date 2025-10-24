@echo off
cls
echo ============================================
echo    START DATABASE CONNECTION
echo ============================================

REM Check if tunnel is already running
tasklist /fi "imagename eq plink.exe" | find /i "plink.exe"
if %errorlevel% == 0 (
    echo ERROR: Tunnel is already running!
    echo Close previous Plink window and try again.
    pause
    exit
)

REM Start SSH tunnel
echo Starting secure connection...
start "Tunnel ORSD DB" plink.exe -ssh sshuser@192.168.10.59 -pw "orsd123" -L 8080:172.30.1.18:80 -N -batch

REM Wait for connection
echo Waiting for connection...
ping -n 4 127.0.0.1 > nul

REM Open browser
echo Opening database in browser...
start "" "http://localhost:8080/aspnetkp/Common/FindInfo.aspx"

echo.
echo ============================================
echo SUCCESS!
echo ============================================
echo Database opened in browser.
echo DO NOT CLOSE the "Tunnel ORSD DB" window!
echo.
echo When finished working:
echo 1. Close browser tab with database
echo 2. Return to this window 
echo 3. Press any key to close tunnel
echo.
pause

REM Close tunnel
taskkill /f /im plink.exe > nul
echo Tunnel closed. Connection finished.
ping -n 2 127.0.0.1 > nul