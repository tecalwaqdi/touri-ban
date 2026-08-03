# Automated smoke test on connected Android device via adb.
param(
    [string]$Device = "RF8M73GXMYV",
    [string]$Package = "com.mycompany.tutorialmultilanguageapp",
    [string]$Email = "demo.super@arawatan.sa",
    [string]$Password = "Demo@2026",
    [int]$StabilitySeconds = 90
)

. "$PSScriptRoot\adb_helpers.ps1"

if (-not (Test-AdbDevice $Device)) {
    Write-Host "FAIL: device $Device not connected"
    exit 4
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$A)
    Invoke-AdbDevice -Device $Device @A
}

function Tap([int]$X, [int]$Y) { Invoke-Adb shell input tap $X $Y | Out-Null }

function TypeText([string]$Text) {
    $encoded = $Text -replace '@', '%40' -replace ' ', '%s'
    Invoke-Adb shell input text $encoded | Out-Null
}

function Test-AppRunning {
    $p = Invoke-Adb shell pidof $Package 2>$null
    return -not [string]::IsNullOrWhiteSpace([string]$p)
}

function Get-ResumedActivity {
    Invoke-Adb shell dumpsys activity activities 2>$null | Select-String "mResumedActivity"
}

Write-Host "=== Network ==="
Invoke-Adb shell ping -c 1 8.8.8.8
Write-Host ""

Write-Host "=== Launch $Package ==="
Invoke-Adb logcat -c | Out-Null
Invoke-Adb shell am force-stop $Package | Out-Null
Start-Sleep -Seconds 1
& adb.exe -s $Device shell am start -W -n "$Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 8
if (-not (Test-AppRunning)) {
    Write-Host "FAIL: app did not start"
    exit 3
}

Write-Host "=== Login as $Email ==="
Tap 720 1545
Start-Sleep -Milliseconds 500
TypeText $Email
Start-Sleep -Milliseconds 400
Tap 720 1860
Start-Sleep -Milliseconds 400
TypeText $Password
Start-Sleep -Milliseconds 400
Invoke-Adb shell input keyevent 4 | Out-Null
Start-Sleep -Milliseconds 400
Tap 720 2529
Write-Host "Login tapped, waiting for dashboard..."
Start-Sleep -Seconds 20

$resumed = Get-ResumedActivity
Write-Host "Resumed: $resumed"
Write-Host "Process running: $(Test-AppRunning)"

Invoke-Adb shell uiautomator dump /sdcard/ui_test.xml | Out-Null
$ui = [string](Invoke-Adb shell cat /sdcard/ui_test.xml 2>$null)
$labels = [regex]::Matches($ui, 'content-desc="([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -ne '' } |
    Select-Object -First 30
Write-Host "UI labels: $($labels -join ' | ')"

Write-Host ""
Write-Host "=== Stability watch ($StabilitySeconds s) ==="
$logFile = Join-Path $env:TEMP "admin_arawatan_smoke.log"
$proc = Start-Process -FilePath adb.exe -ArgumentList @('-s', $Device, 'logcat', '-v', 'time', '*:E', 'flutter:I', 'AndroidRuntime:E') -RedirectStandardOutput $logFile -PassThru -WindowStyle Hidden

$crash = $false
for ($i = 1; $i -le $StabilitySeconds; $i++) {
    Start-Sleep -Seconds 1
    if (-not (Test-AppRunning)) {
        Write-Host "CRASH/KILL at ${i}s"
        $crash = $true
        break
    }
    if ($i % 15 -eq 0) { Write-Host "  ${i}s OK" }
}

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Error log highlights ==="
if (Test-Path $logFile) {
    Select-String -Path $logFile -Pattern "FATAL|AndroidRuntime|OutOfMemory|Process.*died" -CaseSensitive:$false |
        Select-Object -Last 15 | ForEach-Object { $_.Line }
}

Write-Host "Log: $logFile"
if ($crash) { exit 2 }
if (-not (Test-AppRunning)) {
    Write-Host "FAIL: app not running after stability watch"
    exit 3
}
if ([string]$resumed -notmatch [regex]::Escape($Package)) {
    Write-Host "WARN: login may have failed or app left foreground"
    exit 1
}
Write-Host "PASS: stable $StabilitySeconds seconds"
exit 0
