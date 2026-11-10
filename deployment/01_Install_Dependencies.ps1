. "$PSScriptRoot\common.ps1"
Require-Command ruby
Require-Command bundle
Invoke-Checked 'Ruby version' { ruby --version }
Invoke-Checked 'Bundler version' { bundle --version }
Invoke-Checked 'Install locked Ruby dependencies' { bundle install }
Write-Host "Dependencies installed. Next: run 02_Verify_Test_Environment.bat"
