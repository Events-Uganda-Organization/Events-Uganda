param(
    [string]$Message = "",
    [switch]$Watch = $false,
    [int]$Interval = 60
)

$ErrorActionPreference = "Stop"
$RepoPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $RepoPath

function Get-CommitMessage {
    $parts = @()
    $statusLines = git status --porcelain

    $added = @()
    $modified = @()
    $deleted = @()

    foreach ($line in $statusLines) {
        $code = $line.Substring(0, 2).Trim()
        $path = $line.Substring(2).Trim()
        if ($code -eq 'A' -or $code -eq '?') { $added += $path }
        elseif ($code -eq 'M') { $modified += $path }
        elseif ($code -eq 'D') { $deleted += $path }
        else { $modified += $path }
    }

    if ($added.Count -gt 0) { $parts += "Add $($added -join ', ')" }
    if ($modified.Count -gt 0) { $parts += "Update $($modified -join ', ')" }
    if ($deleted.Count -gt 0) { $parts += "Remove $($deleted -join ', ')" }

    $msg = $parts -join '; '
    if ($msg.Length -gt 100) { $msg = $msg.Substring(0, 97) + "..." }

    return $msg
}

function Do-CommitAndPush {
    $status = git status --porcelain
    if (-not $status) { return $false }

    if (-not $Message) {
        $commitMsg = Get-CommitMessage
    } else {
        $commitMsg = $Message
    }

    git add -A
    git commit -m "$commitMsg"
    git push

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Committed and pushed: $commitMsg" -ForegroundColor Green
    return $true
}

if ($Watch) {
    Write-Host "Watching for changes every $Interval seconds... (Ctrl+C to stop)" -ForegroundColor Cyan
    while ($true) {
        Do-CommitAndPush | Out-Null
        Start-Sleep -Seconds $Interval
    }
} else {
    Do-CommitAndPush
    if (-not (git status --porcelain)) {
        Write-Host "No changes to commit." -ForegroundColor Yellow
    }
}
