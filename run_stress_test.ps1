param(
    [ValidateSet('smoke', 'load', 'stress', 'scale')]
    [string]$Profile = 'smoke',
    [string]$UsersFile = (Join-Path $PSScriptRoot 'splixa_test_users.json')
)

$ErrorActionPreference = 'Stop'
$k6 = 'C:\Program Files\k6\k6.exe'
$envFile = Join-Path $PSScriptRoot 'splixa_app\.env'
$testScript = Join-Path $PSScriptRoot 'splixa_stress_test.js'

if (-not (Test-Path -LiteralPath $k6)) {
    throw "k6 was not found at $k6"
}
if (-not (Test-Path -LiteralPath $envFile)) {
    throw "Supabase configuration was not found at $envFile"
}
if (-not (Test-Path -LiteralPath $UsersFile)) {
    throw "Test users file was not found: $UsersFile. Copy splixa_test_users.example.json to splixa_test_users.json and add dedicated test accounts."
}

foreach ($line in Get-Content -LiteralPath $envFile) {
    if ($line -match '^\s*([^#=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        if ($name -in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
            [Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }
}

$profiles = @{
    smoke  = @{ VUS = '1';  DURATION = '10s'; THINK_TIME = '0.5' }
    load   = @{ VUS = '10'; DURATION = '2m';  THINK_TIME = '1' }
    stress = @{ VUS = '25'; DURATION = '5m';  THINK_TIME = '0.5' }
    scale  = @{ VUS = '500'; DURATION = '13m30s'; THINK_TIME = '1' }
}
$selected = $profiles[$Profile]

$env:USERS_FILE = (Resolve-Path -LiteralPath $UsersFile).Path
$env:VUS = $selected.VUS
$env:DURATION = $selected.DURATION
$env:THINK_TIME = $selected.THINK_TIME

$testUsers = Get-Content -LiteralPath $UsersFile -Raw | ConvertFrom-Json
$userCount = @($testUsers).Count
if ($Profile -eq 'scale') {
    $testScript = Join-Path $PSScriptRoot 'splixa_scale_test.js'
    if ($userCount -lt 30) {
        throw "Profile 'scale' requires at least 30 test users, but $userCount were provided."
    }
} elseif ($userCount -lt [int]$env:VUS) {
    throw "Profile '$Profile' requires $($env:VUS) test users, but $userCount were provided."
}

Write-Host "Running Splixa '$Profile' test with $($env:VUS) concurrent users for $($env:DURATION)..."
& $k6 run $testScript
exit $LASTEXITCODE
