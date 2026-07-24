@echo off
REM Run Splixa Flutter app from workspace root by switching to splixa_app
pushd "%~dp0splixa_app"
if exist "%USERPROFILE%\AppData\Local\Pub\Cache\bin\fvm.bat" (
  "%USERPROFILE%\AppData\Local\Pub\Cache\bin\fvm.bat" flutter %*
) else (
  flutter %*
)
popd
