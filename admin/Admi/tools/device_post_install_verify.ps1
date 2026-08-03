param(
    [string]$Device = "RF8M73GXMYV",
    [string]$Package = "com.mycompany.tutorialmultilanguageapp",
    [string]$SuperEmail = "demo.super@arawatan.sa",
    [string]$AgentEmail = "demo.agent@arawatan.sa",
    [string]$Password = "Demo@2026"
)

. "$PSScriptRoot\adb_helpers.ps1"

$Passes = 0
$Fails = 0

function Pass($m) { $script:Passes++; Write-Host "[PASS] $m" -ForegroundColor Green }
function Fail($m) { $script:Fails++; Write-Host "[FAIL] $m" -ForegroundColor Red }
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & adb.exe -s $Device @Args
}

function Tap([int]$X, [int]$Y) {
    Invoke-Adb shell input tap $X $Y | Out-Null
    Start-Sleep -Milliseconds 600
}

function Get-UiXml {
    Invoke-Adb shell uiautomator dump /sdcard/ui_verify.xml | Out-Null
    Start-Sleep -Milliseconds 400
    return [string](Invoke-Adb shell cat /sdcard/ui_verify.xml 2>$null)
}

function App-Running {
    return -not [string]::IsNullOrWhiteSpace([string](Invoke-Adb shell pidof $Package 2>$null).Trim())
}

function Do-Login([string]$Email) {
    Info "Login $Email"
    Invoke-Adb shell am force-stop $Package | Out-Null
    Start-Sleep -Seconds 1
    Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
    Start-Sleep -Seconds 8
    $xml = Get-UiXml
    if ($xml -notmatch 'password="true"') {
        Tap 80 212
        Start-Sleep -Seconds 2
        Invoke-Adb shell input swipe 400 2200 400 400 600 | Out-Null
        Start-Sleep -Seconds 1
        Tap 720 2700
        Start-Sleep -Seconds 3
        Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
        Start-Sleep -Seconds 8
    }
    Tap 720 1545
    Invoke-Adb shell input text ($Email -replace '@', '%40') | Out-Null
    Start-Sleep -Milliseconds 400
    Tap 720 1860
    Invoke-Adb shell input text ($Password -replace '@', '%40') | Out-Null
    Invoke-Adb shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 300
    Tap 720 2529
    Start-Sleep -Seconds 20
    $after = Get-UiXml
    if ($after -match 'password="true"') {
        Fail "login failed: $Email"
        return $false
    }
    Pass "login OK: $Email"
    return $true
}

function Go-Route([string]$Path) {
    Start-AdbDeepLink -Device $Device -Package $Package -Path $Path
    Start-Sleep -Seconds 6
}

if (-not (Test-AdbDevice $Device)) { Fail "no device"; exit 4 }

Info "Post-install verification on $Device"

# Login screen image asset
Invoke-Adb shell am force-stop $Package | Out-Null
Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 8
$loginUi = Get-UiXml
if ($loginUi -match 'password="true"') { Pass "login screen shown" } else { Fail "login screen missing" }
if (App-Running) { Pass "app launches" } else { Fail "app crash on launch"; exit 1 }

if (-not (Do-Login $SuperEmail)) { exit 1 }

$dash = Get-UiXml
$nums = [regex]::Matches($dash, 'content-desc="(\d+)"') | ForEach-Object { $_.Groups[1].Value }
if ($nums.Count -gt 0) { Pass "super admin dashboard loaded ($($nums.Count) stats)" } else { Fail "super admin dashboard empty" }

Go-Route "/adminM3alm"
if (App-Running) { Pass "super admin landmarks page" } else { Fail "crash on landmarks" }

Go-Route "/adminDol"
if (App-Running) { Pass "super admin countries page" } else { Fail "crash on countries" }

if (-not (Do-Login $AgentEmail)) { exit 1 }

$agentDash = Get-UiXml
$agentNums = [regex]::Matches($agentDash, 'content-desc="(\d+)"') | ForEach-Object { $_.Groups[1].Value }
if ($agentNums.Count -gt 0) { Pass "agent dashboard loaded ($($agentNums.Count) stats)" } else { Fail "agent dashboard empty" }

Go-Route "/adminM3alm"
if (App-Running) { Pass "agent landmarks page" } else { Fail "agent crash on landmarks" }

Go-Route "/adminregion"
if (App-Running) { Pass "agent regions page" } else { Fail "agent crash on regions" }

Go-Route "/adminDol"
Start-Sleep -Seconds 3
if (App-Running) { Pass "agent blocked route no crash" } else { Fail "agent crash on blocked route" }

Info "Stability 30s"
$ok = $true
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 1
    if (-not (App-Running)) { Fail "crash at ${i}s"; $ok = $false; break }
}
if ($ok) { Pass "stable 30s pid=$((Invoke-Adb shell pidof $Package).Trim())" }

Write-Host ""
Write-Host "PASS: $Passes  FAIL: $Fails"
if ($Fails -gt 0) { exit 1 }
exit 0
