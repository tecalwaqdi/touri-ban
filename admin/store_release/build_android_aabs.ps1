param(
  [switch]$CustomerOnly,
  [switch]$DriverOnly
)

$ErrorActionPreference = "Stop"

$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA "Android\sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:Path"

$root = Split-Path -Parent $PSScriptRoot
$artifacts = Join-Path $PSScriptRoot "artifacts"
New-Item -ItemType Directory -Force -Path $artifacts | Out-Null

function Build-Aab {
  param(
    [string]$AppDir,
    [string]$Label,
    [string]$BuildName,
    [string]$BuildNumber,
    [string]$OutName
  )

  Write-Host "==> Building $Label AAB $BuildName+$BuildNumber" -ForegroundColor Cyan
  Push-Location $AppDir
  try {
    flutter pub get
    flutter build appbundle --release --build-name=$BuildName --build-number=$BuildNumber
    $src = Join-Path $AppDir "build\app\outputs\bundle\release\app-release.aab"
    if (!(Test-Path $src)) {
      throw "AAB not found for $Label at $src"
    }
    $dest = Join-Path $artifacts $OutName
    Copy-Item $src $dest -Force
    $info = Get-Item $dest
    Write-Host ("OK: {0} ({1:N1} MB)" -f $info.FullName, ($info.Length / 1MB)) -ForegroundColor Green
  }
  finally {
    Pop-Location
  }
}

$buildCustomer = -not $DriverOnly
$buildDriver = -not $CustomerOnly

if ($buildDriver) {
  Build-Aab `
    -AppDir (Join-Path $root "mndob-main") `
    -Label "Driver" `
    -BuildName "2.0.1" `
    -BuildNumber "8" `
    -OutName "driver-mndob-2.0.1-8.aab"
}

if ($buildCustomer) {
  Build-Aab `
    -AppDir (Join-Path $root "ara_oatan_app") `
    -Label "Customer" `
    -BuildName "9.1.9" `
    -BuildNumber "17" `
    -OutName "customer-toury-9.1.9-17.aab"
}

Write-Host "Done. Artifacts folder: $artifacts" -ForegroundColor Green
Get-ChildItem $artifacts | Format-Table Name, Length, LastWriteTime
