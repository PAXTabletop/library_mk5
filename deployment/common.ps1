$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $ProjectRoot
function Require-Command([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "$name not found. Install the prerequisite and reopen PowerShell." }
}
function Invoke-Checked([string]$label, [scriptblock]$command) {
  Write-Host "`n$label" -ForegroundColor Cyan
  & $command
  if ($LASTEXITCODE -ne 0) { throw "$label failed (exit code $LASTEXITCODE)" }
}
function Ensure-Secret {
  $folder = Join-Path $PSScriptRoot 'private'
  New-Item -ItemType Directory -Force -Path $folder | Out-Null
  $file = Join-Path $folder 'secret_key_base.txt'
  if (-not (Test-Path $file)) {
    Require-Command ruby
    $secret = (& ruby -rsecurerandom -e 'print SecureRandom.hex(64)')
    if ($LASTEXITCODE -ne 0 -or $secret.Length -lt 64) { throw 'Could not generate secret key.' }
    [System.IO.File]::WriteAllText($file, $secret)
    Write-Host "Created a host-specific signing secret in deployment/private. Keep it private."
  }
  $env:SECRET_KEY_BASE = [System.IO.File]::ReadAllText($file).Trim()
}
function Ensure-Password {
  if (-not $env:POSTGRES_PASSWORD) {
    $secure = Read-Host 'PostgreSQL password (not saved)' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $env:POSTGRES_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
  }
  if (-not $env:POSTGRES_PASSWORD) { throw 'PostgreSQL password is required.' }
}
function Assert-Safe-DatabaseName {
  $db = $env:LIBRARY_PROD_DB
  if (-not $db) { throw 'LIBRARY_PROD_DB is not set. Specify the database name explicitly.' }
  if ($db -eq $env:LIBRARY_TEST_DB -or $db -eq $env:LIBRARY_DEV_DB) { throw 'Production database name matches a development/test database.' }
}
