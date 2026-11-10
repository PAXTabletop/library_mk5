. "$PSScriptRoot\common.ps1"
Ensure-Password
if (-not $env:LIBRARY_PROD_DB) { $env:LIBRARY_PROD_DB = Read-Host 'Database name to back up' }
Assert-Safe-DatabaseName
$dump = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $dump) {
  $candidates = @(Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\pg_dump.exe' -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)
  if ($candidates.Count -eq 0) { throw 'pg_dump not found. Install PostgreSQL command line tools.' }
  $dumpPath = $candidates[0].FullName
} else { $dumpPath = $dump.Source }
$folder = Join-Path $PSScriptRoot 'backups'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$filename = Join-Path $folder ("library_backup_" + $timestamp + '.dump')
$env:PGPASSWORD = $env:POSTGRES_PASSWORD
try { & $dumpPath -h localhost -U postgres -Fc -f $filename -- $env:LIBRARY_PROD_DB }
finally { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue }
if ($LASTEXITCODE -ne 0) { throw 'pg_dump failed.' }
if ((Get-Item $filename).Length -lt 100) { throw 'Backup is suspiciously small.' }
Write-Host "Backup created: $filename" -ForegroundColor Green
Write-Host 'Copy the backup to a second drive. Restore-test it into a NEW database before relying on it.'
