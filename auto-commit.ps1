param(
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"

# Check for changes
$status = git status --porcelain
if (-not $status) {
    Write-Host "No changes to commit." -ForegroundColor Yellow
    exit 0
}

# Generate commit message if not provided
if (-not $Message) {
    $files = git diff --name-only
    if (-not $files) {
        $files = git diff --cached --name-only
    }
    if (-not $files) {
        $files = git status --porcelain | ForEach-Object { $_ -replace '^.. ' }
    }

    $changed = @()
    $added = @()
    $deleted = @()
    $modified = @()

    git status --porcelain | ForEach-Object {
        $statusCode = $_[0]
        $path = $_ -replace '^.. '
        if ($statusCode -eq 'M') { $modified += $path }
        elseif ($statusCode -eq 'A') { $added += $path }
        elseif ($statusCode -eq 'D') { $deleted += $path }
        elseif ($statusCode -eq '?') { $added += $path }
    }

    $parts = @()
    if ($added.Count -gt 0) { $parts += "Add $($added -join ', ')" }
    if ($modified.Count -gt 0) { $parts += "Update $($modified -join ', ')" }
    if ($deleted.Count -gt 0) { $parts += "Remove $($deleted -join ', ')" }

    $Message = $parts -join '; '
    if ($Message.Length -gt 100) {
        $Message = $Message.Substring(0, 97) + "..."
    }
}

# Stage all changes, commit, and push
git add -A
git commit -m "$Message"
git push

Write-Host "Done: committed and pushed with message:" -ForegroundColor Green
Write-Host "$Message" -ForegroundColor Cyan
