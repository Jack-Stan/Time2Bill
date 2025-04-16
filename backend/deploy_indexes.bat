@echo off
echo Deploying Firestore Indexes...
echo.

cd %~dp0
firebase deploy --only firestore:indexes

echo.
echo Indexes deployed! Press any key to exit.
pause >nul
