. "$PSScriptRoot\common.ps1"
Require-Command ruby
Require-Command bundle
Ensure-Password
Ensure-Secret
$env:RAILS_ENV = 'production'
if (-not $env:LIBRARY_PROD_DB) {
  $env:LIBRARY_PROD_DB = Read-Host 'Database name to use (RESTORED TEST COPY recommended)'
}
Assert-Safe-DatabaseName
Write-Host "Selected database: $env:LIBRARY_PROD_DB" -ForegroundColor Yellow
Write-Host 'Use a RESTORED COPY for initial deployment testing. This app can modify data during normal use.' -ForegroundColor Yellow
$confirm = Read-Host "Type the database name exactly to confirm"
if ($confirm -cne $env:LIBRARY_PROD_DB) { throw 'Database confirmation did not match. Cancelled.' }
Invoke-Checked 'Check database connection (read-only)' { bundle exec rails runner 'puts "Connected database: #{ActiveRecord::Base.connection.current_database}; Games: #{Game.count}; Events: #{Event.count}"' }
$port = if ($env:LIBRARY_PORT) { $env:LIBRARY_PORT } else { '3000' }
if ($port -notmatch '^\d{2,5}$' -or [int]$port -gt 65535) { throw 'Invalid LIBRARY_PORT.' }
Write-Host "Starting Library Mk5 on port $port. Keep this window open. Press Ctrl+C to stop." -ForegroundColor Green
Write-Host "Host browser: http://localhost:$port"
Write-Host "Other devices: http://HOST-COMPUTER-IP:$port"
& bundle exec rails server --environment production --binding 0.0.0.0 --port $port
if ($LASTEXITCODE -ne 0) { throw 'Rails server exited with an error.' }
