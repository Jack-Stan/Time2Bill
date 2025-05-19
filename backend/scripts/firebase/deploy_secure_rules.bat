@echo off
echo Deploying SECURE Firestore Rules...
echo.
echo This will apply proper security rules to your Firestore database.
echo.

cd %~dp0

echo Updating rules file with secure settings...
copy /y "firestore-config\secure_rules_template.rules" "firestore-config\firestore.rules"

echo.
echo Rules file updated with SECURE permissions.
echo.

firebase deploy --only firestore:rules

echo.
echo Your Firestore database now has proper security rules!
echo Users can only access their own data.
echo.
pause
