# One-time setup on an office computer that is on during working hours.
# Right-click this file > "Run with PowerShell". Run it as the person who normally uses this computer.
#
# It will:
#  1. install Git for Windows if it is missing,
#  2. make a local copy of the website's repository in C:\KD-Website,
#  3. fill Z:\2_Office Data\KD WEBSITE with the starter folders if it is empty,
#  4. ask you to sign in to GitHub once,
#  5. schedule the sync to run every 10 minutes.

param(
  [string]$ContentFolder = 'Z:\2_Office Data\KD WEBSITE',
  [string]$RepoUrl = 'https://github.com/aayamikfromrishik/AAYAMIK.git',
  [string]$RepoFolder = 'C:\KD-Website',
  [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'
function Step($t) { Write-Host "`n== $t" -ForegroundColor Green }

Step 'Checking Git'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'Installing Git for Windows...'
  winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git did not install. Install it from https://git-scm.com and run this again.' }
}

Step 'Finding the website folder on the network'
# Scheduled tasks cannot always see mapped drive letters, so use the network path behind Z:
$unc = $ContentFolder
if ($ContentFolder -match '^([A-Za-z]):\\(.*)$') {
  $drive = Get-PSDrive -Name $Matches[1] -ErrorAction SilentlyContinue
  if ($drive -and $drive.DisplayRoot) { $unc = Join-Path $drive.DisplayRoot $Matches[2] }
}
if (-not (Test-Path $unc)) { New-Item -ItemType Directory -Path $unc -Force | Out-Null }
Write-Host "Website folder: $unc"

Step 'Making a local copy of the website'
if (-not (Test-Path (Join-Path $RepoFolder '.git'))) {
  git clone $RepoUrl $RepoFolder
}
Set-Location $RepoFolder
git fetch origin
if (git ls-remote --heads origin $Branch) { git checkout $Branch; git pull --rebase origin $Branch }
else { throw "The branch '$Branch' does not exist on GitHub yet. Ask the developer to publish it first." }
git config user.name 'KD Website Sync'
git config user.email 'ceo@karukritdesigns.com'

Step 'Preparing the folder'
if (-not (Get-ChildItem -Path $unc -Force | Where-Object { $_.Name -notlike '_*' })) {
  Copy-Item -Path (Join-Path $RepoFolder 'tools\windows\KD WEBSITE template\*') -Destination $unc -Recurse -Force
  Write-Host 'The starter folders and READ ME FIRST.txt were added.'
} else { Write-Host 'The folder already has content; nothing was changed.' }

Step 'Signing in to GitHub'
Write-Host 'A GitHub sign-in window may open. Sign in with the account that owns the website repository.'
git push --dry-run origin $Branch
if ($LASTEXITCODE -ne 0) { throw 'Could not sign in to GitHub. Run this again and complete the sign-in.' }

Step 'Saving the settings'
@{ ContentFolder = $unc; RepoFolder = $RepoFolder; Branch = $Branch } | ConvertTo-Json | Set-Content -Path (Join-Path $RepoFolder 'tools\windows\sync-config.json') -Encoding UTF8

Step 'Scheduling the sync every 10 minutes'
$script = Join-Path $RepoFolder 'tools\windows\sync-website.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 10)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 20)
Register-ScheduledTask -TaskName 'KD Website Sync' -Action $action -Trigger $trigger -Settings $settings -Description 'Sends Z:\2_Office Data\KD WEBSITE to the Karukrit Designs website every 10 minutes.' -Force | Out-Null

Step 'First sync'
powershell -NoProfile -ExecutionPolicy Bypass -File $script
Write-Host "`nDone. Anything saved in $ContentFolder now reaches the website within about 15 minutes." -ForegroundColor Green
Write-Host 'Progress and problems are written to _website-log.txt in that folder.'
Read-Host 'Press Enter to close'
