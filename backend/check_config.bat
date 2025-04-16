@echo off
echo Checking Firestore configuration structure...
echo.

rem Check if firestore-config directory exists
if not exist "firestore-config\" (
  echo ERROR: firestore-config directory does not exist!
  goto :error
)

rem Check if required files exist in proper locations
set missing=0
if not exist "firebase.json" (
  echo MISSING: firebase.json in backend directory
  set /a missing+=1
)
if not exist ".firebaserc" (
  echo MISSING: .firebaserc in backend directory
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
if %missing% GTR 0 (
  echo.
  echo Found %missing% missing files!
  goto :error
)

echo All configuration files are present in the correct locations!
echo.
echo Firestore configuration looks good.
goto :end

:error
echo.
echo Firestore configuration check failed!
echo Please make sure all Firebase files are in the correct locations:
echo - firebase.json and .firebaserc in backend root directory
echo - firestore.rules and firestore.indexes.json in backend/firestore-config directory

:end
pause
