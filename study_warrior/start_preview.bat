@echo off
title Study Warrior - Smartphone Preview
color 0A

echo ========================================================
echo       STUDY WARRIOR - SMARTPHONE PREVIEW SERVER
echo ========================================================
echo.
echo Make sure your smartphone is connected to the same Wi-Fi!
echo.
echo 1. Open your smartphone browser.
echo 2. Type this exact URL: http://10.255.96.164:8080
echo.
echo Starting server...
echo.

flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

pause
