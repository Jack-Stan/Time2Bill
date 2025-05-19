@echo off
echo Deploying Firestore Indexes for better performance...
echo.

cd %~dp0

firebase deploy --only firestore:indexes

echo.
echo Firestore indexes have been deployed!
echo These indexes will improve query performance.
echo.
pause
