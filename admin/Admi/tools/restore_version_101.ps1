param(
    [string]$Target = "e:\my project\osama\watan\admin_arawatan-main",
    [string]$Source = "e:\my project\osama\watan\backups\admin_arawatan-v101",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Source)) {
    Write-Error "Backup v101 not found: $Source"
}

Write-Host "=== Restore admin_arawatan version 101 ==="
Write-Host "From: $Source"
Write-Host "To:   $Target"

if ((Test-Path $Target) -and -not $Force) {
    $answer = Read-Host "Target exists. Overwrite? (y/N)"
    if ($answer -notmatch '^[yY]') {
        Write-Host "Cancelled."
        exit 0
    }
}

if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
}

robocopy $Source $Target /MIR /XD build .dart_tool .gradle "android\.gradle" "ios\Pods" "ios\.symlinks" /XF *.apk /NFL /NDL /NJH /NJS /nc /ns /np
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Error "Robocopy failed with code $rc"
}

Write-Host "Done. Restored version 101 to $Target"
Write-Host "Next: cd `"$Target`"; flutter pub get"
