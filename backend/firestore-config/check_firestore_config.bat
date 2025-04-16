@echo off
echo Checking Firestore configuration structure...
echo.

rem Check if required files exist
set missing=0
if not exist "firebase.json" (
  echo MISSING: firebase.json
  set /a missing+=1
)
if not exist "firestore-config\firestore.rules" (
  echo MISSING: firestore-config\firestore.rules
  set /a missing+=1
)
if not exist "firestore-config\firestore.indexes.json" (
  echo MISSING: firestore-config\firestore.indexes.json
  set /a missing+=1
)
if not exist ".firebaserc" (
  echo MISSING: .firebaserc
  set /a missing+=1
)
if %missing% GTR 0 (
  echo.
  echo Found %missing% missing files!
) else (
  echo All configuration files are present!
)

echo.
echo Firebase Configuration:
echo ---------------------
if exist "firebase.json" (
  type "firebase.json"
)
echo.
echo.
echo Firestore Rules:
echo ---------------------
if exist "firestore-config\firestore.rules" (
  type "firestore-config\firestore.rules"
)

echo.
echo Configuration check complete!
pause
