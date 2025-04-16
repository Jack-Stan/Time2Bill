@echo off
echo Creating Firestore configuration directories...

mkdir "firestore-config"

rem Move existing config files to the new directory
if exist "firestore.rules" (
  move /Y "firestore.rules" "firestore-config\"
)
if exist "firestore.indexes.json" (
  move /Y "firestore.indexes.json" "firestore-config\"
)

rem Create necessary files if they don't exist
if not exist "firestore-config\firestore.rules" (
  echo rules_version = '2';> "firestore-config\firestore.rules"
  echo service cloud.firestore {>> "firestore-config\firestore.rules"
  echo   match /databases/{database}/documents {>> "firestore-config\firestore.rules"
  echo     // Allow authenticated users to read/write their own data>> "firestore-config\firestore.rules"
  echo     match /{document=**} {>> "firestore-config\firestore.rules"
  echo       allow read, write: if request.auth != null;>> "firestore-config\firestore.rules"
  echo     }>> "firestore-config\firestore.rules"
  echo   }>> "firestore-config\firestore.rules"
  echo }>> "firestore-config\firestore.rules"
)

if not exist "firestore-config\firestore.indexes.json" (
  echo {> "firestore-config\firestore.indexes.json"
  echo   "indexes": [],>> "firestore-config\firestore.indexes.json"
  echo   "fieldOverrides": []>> "firestore-config\firestore.indexes.json"
  echo }>> "firestore-config\firestore.indexes.json"
)

echo Configuration directory setup complete!
pause
