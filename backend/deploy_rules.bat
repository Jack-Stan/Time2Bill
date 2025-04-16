@echo off
echo Deploying Firestore Rules from backend directory...
echo.

cd %~dp0
echo Using rules from: firestore-config\firestore.rules

firebase deploy --only firestore:rules

echo.
echo Rules deployed! Press any key to exit.
pause >nul
