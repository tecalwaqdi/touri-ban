param(
    [string]$Abi = "arm64-v8a"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "Building optimized release APK (split per ABI)..." -ForegroundColor Cyan
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$outDir = Join-Path $root "build\app\outputs\flutter-apk"
$split = Join-Path $outDir "app-$Abi-release.apk"
$dest = Join-Path $outDir "app-release-$Abi.apk"

if (-not (Test-Path $split)) {
    Write-Host "FAIL: $split not found" -ForegroundColor Red
    exit 1
}

Copy-Item $split $dest -Force
$mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host ""
Write-Host "Ready: $dest ($mb MB)" -ForegroundColor Green
Write-Host "Install: adb install -r `"$dest`""
