# PowerShell helper to run Splixa flutter project from workspace root
Param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location (Join-Path $scriptDir 'splixa_app')

$fvm = Join-Path $env:USERPROFILE 'AppData\Local\Pub\Cache\bin\fvm.bat'
if (Test-Path $fvm) {
    & $fvm flutter @Args
} else {
    flutter @Args
}

Pop-Location
