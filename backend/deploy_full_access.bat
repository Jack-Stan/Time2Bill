@echo off
echo Deploying FULL ACCESS Firestore Rules (DEVELOPMENT ONLY!)...
echo.

cd %~dp0

echo rules_version = '2';> "firestore-config\firestore.rules"
echo service cloud.firestore {>> "firestore-config\firestore.rules"
echo   match /databases/{database}/documents {>> "firestore-config\firestore.rules"
echo     // VERY PERMISSIVE RULES - FOR DEVELOPMENT ONLY>> "firestore-config\firestore.rules"
echo     match /{document=**} {>> "firestore-config\firestore.rules"
echo       allow read, write: if true;>> "firestore-config\firestore.rules"
echo     }>> "firestore-config\firestore.rules"
echo   }>> "firestore-config\firestore.rules"
echo }>> "firestore-config\firestore.rules"

echo.
echo Rules file updated with FULL ACCESS permissions.
echo.

firebase deploy --only firestore:rules

echo.
echo WARNING: Your Firestore database now has NO SECURITY!
echo Only use this for development and testing.
echo.
pause
