param(
    [string]$Device = "RF8M73GXMYV",
    [string]$Package = "com.mycompany.tutorialmultilanguageapp",
    [int]$Seconds = 120
)

. "$PSScriptRoot\adb_helpers.ps1"

if (-not (Test-AdbDevice $Device)) {
    Write-Host "FAIL: device $Device not connected"
    exit 4
}

function Invoke-DeviceAdb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$A)
    Invoke-AdbDevice -Device $Device @A
}

function Get-AppPid {
    $p = [string](Invoke-DeviceAdb shell pidof $Package 2>$null).Trim()
    if ($p -match '\s') { return $p.Split()[0] }
    return $p
}

function Get-UiXml {
    Invoke-DeviceAdb shell uiautomator dump /sdcard/ui_check.xml | Out-Null
    return [string](Invoke-DeviceAdb shell cat /sdcard/ui_check.xml 2>$null)
}

function Test-Dashboard {
    param([string]$Xml)
    return ($Xml -match 'EditText' -eq $false) -and ($Xml.Length -gt 5000)
}

function Ensure-Foreground {
    $r = [string](Invoke-DeviceAdb shell dumpsys activity activities 2>$null | Select-String "mResumedActivity")
    if ($r -notmatch [regex]::Escape($Package)) {
        Invoke-DeviceAdb shell am start -n "$Package/.MainActivity" | Out-Null
    }
}

function Do-Login {
    Invoke-DeviceAdb shell input tap 720 1398 | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input text "demo.super%40arawatan.sa" | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input tap 720 1647 | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input text "Demo%402026" | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input keyevent 4 | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input swipe 720 1500 720 800 250 | Out-Null; Start-Sleep 1
    Invoke-DeviceAdb shell input tap 720 2300 | Out-Null
    Start-Sleep -Seconds 22
}

Write-Host "=== Network ==="
Invoke-DeviceAdb shell ping -c 2 8.8.8.8
Write-Host ""

Write-Host "=== Launch and login ==="
Invoke-DeviceAdb shell am force-stop $Package | Out-Null
Start-Sleep 1
Invoke-DeviceAdb shell am start -n "$Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 8

$xml = Get-UiXml
if (-not (Test-Dashboard $xml)) {
    Write-Host "Attempting login..."
    Do-Login
    $xml = Get-UiXml
}

if (Test-Dashboard $xml) {
    Write-Host "Dashboard detected (xml size $($xml.Length))"
} else {
    Write-Host "WARN: may still be on login screen (xml size $($xml.Length))"
}

Invoke-DeviceAdb logcat -c | Out-Null
Write-Host ""
Write-Host "=== Stability $Seconds s ==="
$deathAt = 0
for ($i = 1; $i -le $Seconds; $i++) {
    Start-Sleep -Seconds 1
    Ensure-Foreground
    $appPid = Get-AppPid
    if ([string]::IsNullOrWhiteSpace($appPid)) {
        $deathAt = $i
        Write-Host "PROCESS DEAD at ${i}s"
        break
    }
    if ($i % 30 -eq 0) { Write-Host "${i}s pid=$appPid OK" }
}

Write-Host ""
Write-Host "=== Crash logs ==="
Invoke-DeviceAdb logcat -d -t 600 2>&1 | Select-String -Pattern "FATAL EXCEPTION|AndroidRuntime|OutOfMemory|Process.*died" -CaseSensitive:$false | Select-Object -Last 20

if ($deathAt -gt 0) { exit 2 }
Write-Host "PASS: stable $Seconds seconds"
exit 0
