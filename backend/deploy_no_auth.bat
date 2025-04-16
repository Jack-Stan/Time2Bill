@echo off
echo Deploying NO-AUTH Firestore Rules (EXTREME CAUTION!)...
echo.
echo This will give FULL PUBLIC ACCESS to your Firestore database!
echo ONLY use this for LOCAL development and testing.
echo.
echo Press CTRL+C to cancel or any key to continue...
pause

cd %~dp0

echo rules_version = '2';> "firestore-config\firestore.rules"
echo service cloud.firestore {>> "firestore-config\firestore.rules"
echo   match /databases/{database}/documents {>> "firestore-config\firestore.rules"
echo     // NO SECURITY RULES - PUBLIC ACCESS!>> "firestore-config\firestore.rules"
echo     match /{document=**} {>> "firestore-config\firestore.rules"
echo       allow read, write: if true;>> "firestore-config\firestore.rules"
echo     }>> "firestore-config\firestore.rules"
echo   }>> "firestore-config\firestore.rules"
echo }>> "firestore-config\firestore.rules"

echo.
echo Rules file updated with PUBLIC ACCESS permissions.
echo.

firebase deploy --only firestore:rules

echo.
echo WARNING: Your Firestore database now has ABSOLUTELY NO SECURITY!
echo REMEMBER to restore proper security rules after testing.
echo.

pause
