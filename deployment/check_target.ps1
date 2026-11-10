# Run from the project's root directory. Read-only checks except Rails' test database and generated assets.
$ErrorActionPreference = 'Stop'
if (-not (Test-Path '.\Gemfile')) { throw 'Run this script from the library_mk5 project folder.' }
if (-not $env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD = Read-Host 'PostgreSQL password (not saved)' }
Write-Host 'Checking Ruby and Bundler...'
ruby --version
bundle --version
Write-Host 'Checking installed dependencies...'
bundle check
if ($LASTEXITCODE -ne 0) { throw 'Dependencies missing: run bundle install.' }
Write-Host 'Checking Rails autoloading...'
bundle exec rails zeitwerk:check
if ($LASTEXITCODE -ne 0) { throw 'Zeitwerk check failed.' }
Write-Host 'Checking configured development database (read only)...'
bundle exec rails runner 'puts "Database: #{ActiveRecord::Base.connection.current_database}"; puts "Events: #{Event.count}, Games: #{Game.count}, Titles: #{Title.count}"'
if ($LASTEXITCODE -ne 0) { throw 'Database connection failed.' }
Write-Host 'Running tests (USES THE SEPARATE TEST DATABASE)...'
bundle exec rails test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
Write-Host 'Compiling production assets with a dummy signing key...'
$previousEnv = $env:RAILS_ENV
$previousDummy = $env:SECRET_KEY_BASE_DUMMY
try {
  $env:RAILS_ENV = 'production'
  $env:SECRET_KEY_BASE_DUMMY = '1'
  bundle exec rails assets:precompile
  if ($LASTEXITCODE -ne 0) { throw 'Production asset compilation failed.' }
} finally {
  $env:RAILS_ENV = $previousEnv
  $env:SECRET_KEY_BASE_DUMMY = $previousDummy
}
Write-Host 'Automated checks completed. Browser testing on the target computer is still required.'
