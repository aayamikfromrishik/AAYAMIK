# Sends the KD WEBSITE folder to the website.
# Runs every 10 minutes from Windows Task Scheduler (set up by setup-website-sync.ps1).
# Copies the folder into the local copy of the website's repository, and if anything changed,
# sends it to GitHub. GitHub then rebuilds the site and uploads it to Erichost.

$ErrorActionPreference = 'Stop'
$config = Get-Content -Raw (Join-Path $PSScriptRoot 'sync-config.json') | ConvertFrom-Json
$source = $config.ContentFolder          # the studio folder, as a network path (\\server\share\...)
$repo   = $config.RepoFolder             # local copy of the repository, e.g. C:\KD-Website
$branch = $config.Branch                 # main
$log    = Join-Path $source '_website-log.txt'

function Write-Log($text) {
  $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $text
  try { Add-Content -Path $log -Value $line -Encoding UTF8 } catch { }
  Write-Output $line
}

try {
  if (-not (Test-Path $source)) { throw "The website folder is not reachable: $source" }
  Set-Location $repo

  # bring in any changes made on GitHub first (for example by the web developer)
  git pull --quiet --rebase --autostash origin $branch 2>&1 | Out-Null

  # mirror the folder; files starting with _ are notes, the log and Windows clutter stay out
  $dest = Join-Path $repo 'site-content'
  robocopy $source $dest /MIR /XF '_*' 'Thumbs.db' 'desktop.ini' '~$*' '*.tmp' /XD '_*' /MAX:83886080 /R:2 /W:5 /NP /NFL /NDL /NJH /NJS | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "Copying the folder failed (robocopy code $LASTEXITCODE)." }

  # files over 80 MB are skipped: say which
  Get-ChildItem -Path $source -Recurse -File | Where-Object { $_.Length -gt 83886080 -and $_.Name -notlike '_*' } | ForEach-Object {
    Write-Log "Skipped (larger than 80 MB): $($_.FullName.Substring($source.Length))"
  }

  git add --all site-content
  $changes = git status --porcelain site-content
  if (-not $changes) { exit 0 }

  $count = ($changes | Measure-Object).Count
  git commit --quiet -m "Website content update from the studio folder ($count changes)" | Out-Null
  git push --quiet origin $branch 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Sending to GitHub failed. Check the internet connection, or sign in to GitHub again by running setup-website-sync.ps1.' }
  Write-Log "Sent $count changes. The website updates in a few minutes."
}
catch {
  Write-Log "PROBLEM: $($_.Exception.Message)"
  exit 1
}
