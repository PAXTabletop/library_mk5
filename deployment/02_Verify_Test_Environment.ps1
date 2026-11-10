. "$PSScriptRoot\common.ps1"
Require-Command ruby
Require-Command bundle
Ensure-Password
$env:RAILS_ENV = 'test'
if (-not $env:LIBRARY_TEST_DB) { $env:LIBRARY_TEST_DB = 'library_mk4_test' }
if ($env:LIBRARY_PROD_DB -and $env:LIBRARY_TEST_DB -eq $env:LIBRARY_PROD_DB) { throw 'Test and production database names must differ.' }
Invoke-Checked 'Bundler dependency check' { bundle check }
Invoke-Checked 'Zeitwerk check (test)' { bundle exec rails zeitwerk:check }
Write-Host "WARNING: Rails tests can rebuild the TEST database: $env:LIBRARY_TEST_DB" -ForegroundColor Yellow
$confirmation = Read-Host "Type TEST to confirm that this database is disposable"
if ($confirmation -cne 'TEST') { throw 'Cancelled; no tests were run.' }
Invoke-Checked 'Create test database if needed' { bundle exec rails db:create RAILS_ENV=test }
Invoke-Checked 'Load schema into disposable test database' { bundle exec rails db:schema:load RAILS_ENV=test }
Invoke-Checked 'Automated tests' { bundle exec rails test }
$env:RAILS_ENV = 'production'
$env:SECRET_KEY_BASE_DUMMY = '1'
try { Invoke-Checked 'Production asset precompile' { bundle exec rails assets:precompile } }
finally { Remove-Item Env:SECRET_KEY_BASE_DUMMY -ErrorAction SilentlyContinue }
Write-Host "Automated checks passed. Database restore and browser workflow testing still required." -ForegroundColor Green
