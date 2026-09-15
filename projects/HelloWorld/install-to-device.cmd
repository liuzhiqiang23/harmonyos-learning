@echo off
setlocal
set "DEVECO_SDK_HOME=D:\DevEco Studio\sdk"
set "NODE=D:\DevEco Studio\tools\node\node.exe"
set "HVIGOR=D:\DevEco Studio\tools\hvigor\bin\hvigorw.js"
set "HDC=D:\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
cd /d "%~dp0"

echo [1/3] building HAP ...
"%NODE%" "%HVIGOR%" assembleHap --mode module -p product=default -p module=entry@default --no-daemon
if errorlevel 1 (
  echo.
  echo BUILD FAILED - nothing was installed.
  pause
  exit /b 1
)

echo.
echo [2/3] installing to connected device/emulator ...
"%HDC%" install -r "entry\build\default\outputs\default\entry-default-unsigned.hap"
if errorlevel 1 (
  echo.
  echo INSTALL FAILED - is the emulator running? check: hdc list targets
  pause
  exit /b 1
)

echo.
echo [3/3] launching app ...
"%HDC%" shell "aa start -a EntryAbility -b com.liuzhiqiang.helloworld"

echo.
echo ================================================
echo  DONE - app installed and launched
echo  emulator does NOT need a Huawei account / signing
echo ================================================
pause
