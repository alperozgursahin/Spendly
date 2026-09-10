[CmdletBinding()]
param(
  [string]$ProjectRef = 'lbalfjhpfslvqigdmbdg',
  [switch]$SkipFunctionDeploy,
  [switch]$RestartProjectOnTimeout
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Windows PowerShell 5.1 may otherwise negotiate an obsolete TLS version.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$migrationVersion = '20260910000100'
$migrationName = 'secure_account_deletion'
$migrationPath = Join-Path $PSScriptRoot "supabase\migrations\${migrationVersion}_${migrationName}.sql"
$queryUri = "https://api.supabase.com/v1/projects/$ProjectRef/database/query"

if (-not (Test-Path -LiteralPath $migrationPath -PathType Leaf)) {
  throw "Migration file was not found: $migrationPath"
}

function Get-HttpErrorMessage {
  param([System.Management.Automation.ErrorRecord]$ErrorRecord)

  $message = $ErrorRecord.Exception.Message
  $details = $null
  $errorDetailsProperty = $ErrorRecord.PSObject.Properties['ErrorDetails']
  if ($null -ne $errorDetailsProperty -and
      $null -ne $errorDetailsProperty.Value -and
      -not [string]::IsNullOrWhiteSpace($errorDetailsProperty.Value.Message)) {
    $details = $errorDetailsProperty.Value.Message
  }

  # Invoke-RestMethod throws different exception types in Windows PowerShell
  # and PowerShell 7. Do not assume every exception exposes Response.
  $responseProperty = $ErrorRecord.Exception.PSObject.Properties['Response']
  if ($null -eq $responseProperty -or $null -eq $responseProperty.Value) {
    if (-not [string]::IsNullOrWhiteSpace($details)) {
      return "$message - $details"
    }
    return $message
  }

  $response = $responseProperty.Value
  try {
    $statusCode = 'unknown'
    $statusCodeProperty = $response.PSObject.Properties['StatusCode']
    if ($null -ne $statusCodeProperty) {
      $statusCode = [int]$statusCodeProperty.Value
    }

    $body = $details
    $contentProperty = $response.PSObject.Properties['Content']
    if ($null -ne $contentProperty -and $null -ne $contentProperty.Value) {
      $content = $contentProperty.Value
      $readMethod = $content.PSObject.Methods['ReadAsStringAsync']
      if ($null -ne $readMethod) {
        $body = $content.ReadAsStringAsync().GetAwaiter().GetResult()
      }
      elseif ($content -is [string]) {
        $body = $content
      }
    }
    else {
      $streamMethod = $response.PSObject.Methods['GetResponseStream']
      if ($null -ne $streamMethod) {
        $stream = $response.GetResponseStream()
        if ($null -ne $stream) {
          $reader = [System.IO.StreamReader]::new($stream)
          try {
            $body = $reader.ReadToEnd()
          }
          finally {
            $reader.Dispose()
          }
        }
      }
    }

    if (-not [string]::IsNullOrWhiteSpace($body)) {
      return "HTTP $statusCode - $body"
    }
    return "HTTP $statusCode - $message"
  }
  catch {
    return $message
  }
}

function Invoke-SupabaseQuery {
  param(
    [Parameter(Mandatory = $true)][string]$Sql,
    [Parameter(Mandatory = $true)][bool]$ReadOnly,
    [Parameter(Mandatory = $true)][string]$AccessToken
  )

  $headers = @{
    Authorization = "Bearer $AccessToken"
    Accept = 'application/json'
  }
  $body = @{
    query = $Sql
    read_only = $ReadOnly
  } | ConvertTo-Json -Compress

  try {
    return Invoke-RestMethod `
      -Uri $queryUri `
      -Method Post `
      -Headers $headers `
      -ContentType 'application/json; charset=utf-8' `
      -Body $body
  }
  catch {
    $safeMessage = Get-HttpErrorMessage -ErrorRecord $_
    throw "Supabase Management API query failed: $safeMessage"
  }
}

function Restart-SupabaseProject {
  param([Parameter(Mandatory = $true)][string]$AccessToken)

  $headers = @{
    Authorization = "Bearer $AccessToken"
    Accept = 'application/json'
  }
  $restartUri = "https://api.supabase.com/v1/projects/$ProjectRef/restart"

  try {
    $null = Invoke-RestMethod `
      -Uri $restartUri `
      -Method Post `
      -Headers $headers `
      -ContentType 'application/json; charset=utf-8' `
      -Body '{}'
  }
  catch {
    $safeMessage = Get-HttpErrorMessage -ErrorRecord $_
    throw "Supabase project restart failed: $safeMessage"
  }
}

$secureToken = $null
$accessToken = $null

try {
  Write-Host ''
  Write-Host 'This deployment uses HTTPS and does not use the database password or pooler.' -ForegroundColor Cyan
  Write-Host 'Create a token at https://supabase.com/dashboard/account/tokens' -ForegroundColor Cyan
  Write-Host 'Do not paste the token into chat or pass it on the command line.' -ForegroundColor Yellow
  Write-Host ''

  $secureToken = Read-Host -Prompt 'Supabase Personal Access Token' -AsSecureString
  $accessToken = [System.Net.NetworkCredential]::new('', $secureToken).Password
  if ([string]::IsNullOrWhiteSpace($accessToken)) {
    throw 'No Personal Access Token was provided.'
  }

  Write-Host '[1/4] Applying account deletion migration through the Management API...'
  $migrationSql = Get-Content -LiteralPath $migrationPath -Raw -Encoding UTF8
  $migrationApplied = $false
  $migrationAttempt = 0
  $maximumAttempts = if ($RestartProjectOnTimeout) { 5 } else { 1 }

  while (-not $migrationApplied -and $migrationAttempt -lt $maximumAttempts) {
    $migrationAttempt++
    try {
      $null = Invoke-SupabaseQuery -Sql $migrationSql -ReadOnly $false -AccessToken $accessToken
      $migrationApplied = $true
    }
    catch {
      $isDatabaseTimeout = $_.Exception.Message -match 'HTTP 5(04|24|44)'
      if (-not $RestartProjectOnTimeout -or -not $isDatabaseTimeout) {
        if ($isDatabaseTimeout) {
          throw "$($_.Exception.Message)`nThe database is unresponsive. Re-run this script with -RestartProjectOnTimeout to restart the project and retry automatically."
        }
        throw
      }

      if ($migrationAttempt -eq 1) {
        Write-Host '      Database returned a gateway timeout (Supabase incident recovery).' -ForegroundColor Yellow
        Write-Host '      Restarting the project through the Management API...' -ForegroundColor Yellow
        Restart-SupabaseProject -AccessToken $accessToken
        Write-Host '      Restart accepted. Waiting 90 seconds for database services...' -ForegroundColor Yellow
        for ($elapsed = 15; $elapsed -le 90; $elapsed += 15) {
          Start-Sleep -Seconds 15
          Write-Host "      Recovery wait: $elapsed/90 seconds"
        }
      }
      elseif ($migrationAttempt -lt $maximumAttempts) {
        Write-Host "      Database is still recovering. Waiting 30 seconds before attempt $($migrationAttempt + 1)/$maximumAttempts..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
      }
    }
  }

  if (-not $migrationApplied) {
    throw "The database remained unavailable after $maximumAttempts attempts. Supabase must finish recovering the project before SQL can be applied."
  }
  Write-Host '      Migration executed successfully.' -ForegroundColor Green

  Write-Host '[2/4] Verifying required database objects...'
  $validationSql = @'
select
  to_regprocedure('public.check_account_deletion_v1(uuid)') is not null as check_rpc_exists,
  to_regprocedure('public.prepare_account_deletion_v1(uuid)') is not null as prepare_rpc_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'is_deleted'
  ) as profile_deleted_flag_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'deleted_at'
  ) as profile_deleted_at_exists;
'@
  $validationResult = Invoke-SupabaseQuery -Sql $validationSql -ReadOnly $true -AccessToken $accessToken
  $validationRows = @($validationResult)
  if ($validationRows.Count -ne 1) {
    throw "Unexpected validation result: $($validationResult | ConvertTo-Json -Compress -Depth 5)"
  }

  $validation = $validationRows[0]
  $requiredFlags = @(
    'check_rpc_exists',
    'prepare_rpc_exists',
    'profile_deleted_flag_exists',
    'profile_deleted_at_exists'
  )
  foreach ($flag in $requiredFlags) {
    if (-not ($validation.PSObject.Properties.Name -contains $flag) -or $validation.$flag -ne $true) {
      throw "Database validation failed for '$flag': $($validation | ConvertTo-Json -Compress -Depth 5)"
    }
  }
  Write-Host '      Both RPCs and both profile deletion columns exist.' -ForegroundColor Green

  Write-Host '[3/4] Recording the migration in Supabase migration history...'
  $historySql = @"
do `$history`$
begin
  if to_regclass('supabase_migrations.schema_migrations') is not null
     and exists (
       select 1 from information_schema.columns
       where table_schema = 'supabase_migrations'
         and table_name = 'schema_migrations'
         and column_name = 'version'
     )
     and exists (
       select 1 from information_schema.columns
       where table_schema = 'supabase_migrations'
         and table_name = 'schema_migrations'
         and column_name = 'name'
     )
     and exists (
       select 1 from information_schema.columns
       where table_schema = 'supabase_migrations'
         and table_name = 'schema_migrations'
         and column_name = 'statements'
     ) then
    execute 'insert into supabase_migrations.schema_migrations (version, name, statements)
             values (`$1, `$2, `$3)
             on conflict (version) do update
             set name = excluded.name, statements = excluded.statements'
      using '$migrationVersion', '$migrationName',
            array['Applied through Supabase Management API /database/query']::text[];
  end if;
end
`$history`$;
"@
  $null = Invoke-SupabaseQuery -Sql $historySql -ReadOnly $false -AccessToken $accessToken
  Write-Host '      Migration history synchronized.' -ForegroundColor Green

  if ($SkipFunctionDeploy) {
    Write-Host '[4/4] Edge Function deployment skipped by request.' -ForegroundColor Yellow
  }
  else {
    Write-Host '[4/4] Deploying delete-account Edge Function through the API...'
    & supabase functions deploy delete-account --project-ref $ProjectRef --use-api
    if ($LASTEXITCODE -ne 0) {
      throw "Edge Function deployment failed with exit code $LASTEXITCODE. The SQL migration is already applied and verified."
    }
    Write-Host '      Edge Function deployed successfully.' -ForegroundColor Green
  }

  Write-Host ''
  Write-Host 'Account deletion backend deployment completed successfully.' -ForegroundColor Green
}
finally {
  $accessToken = $null
  $secureToken = $null
  [GC]::Collect()
}
