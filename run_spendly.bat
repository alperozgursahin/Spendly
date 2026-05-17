@echo off
REM Run Spendly Flutter app from workspace root by switching to spendly_demo
pushd "%~dp0spendly_demo"
if exist "%USERPROFILE%\AppData\Local\Pub\Cache\bin\fvm.bat" (
  "%USERPROFILE%\AppData\Local\Pub\Cache\bin\fvm.bat" flutter %*
) else (
  flutter %*
)
popd
