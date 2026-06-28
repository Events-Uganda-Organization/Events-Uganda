param(
    [int]$IntervalSeconds = 30,
    [string]$Branch = "main"
)

$WatchDir = $PSScriptRoot

Write-Host "Auto-commit running in: $WatchDir"
Write-Host "Checking for changes every $IntervalSeconds seconds."
Write-Host "Press Ctrl+C to stop."

while ($true) {
    try {
        $changedFiles = & git -C $WatchDir status --porcelain
        if ($changedFiles.Count -gt 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Changes detected:"
            $changedFiles | ForEach-Object { Write-Host "  $_" }

            & git -C $WatchDir add -A
            if ($LASTEXITCODE -eq 0) {
                $msg = "auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                & git -C $WatchDir commit -m $msg
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Committed. Pushing to origin/$Branch..."
                    & git -C $WatchDir push origin $Branch
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  Pushed successfully."
                    } else {
                        Write-Host "  Push failed (exit code: $LASTEXITCODE)"
                    }
                } else {
                    Write-Host "  Commit failed (exit code: $LASTEXITCODE)"
                }
            } else {
                Write-Host "  Add failed (exit code: $LASTEXITCODE)"
            }
        }
    } catch {
        Write-Host "Error: $_"
    }

    Start-Sleep -Seconds $IntervalSeconds
}
