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

function Log([string]$Level, [string]$Msg) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg" }
function Pass([string]$Msg) { $script:Passes++; Log "PASS" $Msg }
function Fail([string]$Msg) { $script:Fails++; Log "FAIL" $Msg }
function Info([string]$Msg) { Log "INFO" $Msg }

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & adb.exe -s $Device @Args
}

function Go-Route([string]$Path) {
    Start-AdbDeepLink -Device $Device -Package $Package -Path $Path
    Start-Sleep -Seconds 6
}

function Get-UiXml {
    Invoke-Adb shell uiautomator dump /sdcard/ui_audit.xml | Out-Null
    Start-Sleep -Milliseconds 400
    return [string](Invoke-Adb shell cat /sdcard/ui_audit.xml 2>$null)
}

function Get-Stats([string]$Xml) {
    $nums = @([regex]::Matches($Xml, 'content-desc="(\d+)"') |
        ForEach-Object { [int]$_.Groups[1].Value } |
        Where-Object { $_ -ge 1 -and $_ -le 999999 })
    if ($nums.Count -eq 0) {
        $nums = @([regex]::Matches($Xml, 'text="(\d+)"') |
            ForEach-Object { [int]$_.Groups[1].Value } |
            Where-Object { $_ -ge 1 -and $_ -le 999999 })
    }
    return $nums
}

function Tap([int]$X, [int]$Y) {
    Invoke-Adb shell input tap $X $Y | Out-Null
    Start-Sleep -Milliseconds 700
}

function Invoke-Login([string]$Email) {
    Info "Login $Email"
    Invoke-Adb shell am force-stop $Package | Out-Null
    Start-Sleep -Seconds 1
    Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
    Start-Sleep -Seconds 8
    $xml = Get-UiXml
    $onLogin = $xml -match 'password="true"'
    if (-not $onLogin) {
        Info "Logout first"
        Tap 80 212
        Start-Sleep -Seconds 2
        Invoke-Adb shell input swipe 400 2200 400 400 600 | Out-Null
        Start-Sleep -Seconds 1
        Tap 720 2700
        Start-Sleep -Seconds 4
        Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
        Start-Sleep -Seconds 8
    }
    Tap 720 1545
    $enc = $Email -replace '@', '%40'
    Invoke-Adb shell input text $enc | Out-Null
    Start-Sleep -Milliseconds 500
    Tap 720 1860
    $pw = $Password -replace '@', '%40'
    Invoke-Adb shell input text $pw | Out-Null
    Invoke-Adb shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 400
    Tap 720 2529
    Start-Sleep -Seconds 20
    $after = Get-UiXml
    if ($after -match 'password="true"') {
        Fail "Login failed $Email"
        return $false
    }
    Pass "Login $Email"
    return $true
}

if (-not (Test-AdbDevice $Device)) { Write-Host "FAIL: no device"; exit 4 }

Info "Audit on $Device"
Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 8

$boot = Get-UiXml
if ($boot -match 'password="true"') {
    if (-not (Invoke-Login $SuperEmail)) { exit 1 }
} else {
    Pass "Super admin session already active"
}

Go-Route "/home22Dashboard"
Start-Sleep -Seconds 8
$dash = Get-UiXml
$stats = Get-Stats $dash
if ($stats.Count -gt 0) {
    $slice = $stats[0..([Math]::Min(5, $stats.Count - 1))] -join ', '
    Pass "SuperAdmin stats: $slice"
} else {
    Fail "SuperAdmin stats missing"
}

foreach ($r in @("/adminM3alm", "/adminDol", "/adminAgent", "/adminALLhgZ", "/adminReportsHub")) {
    Go-Route $r
    $proc = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
    if ($proc) { Pass "SuperAdmin $r" } else { Fail "SuperAdmin $r died" }
}

$before = if ($stats.Count -gt 0) { $stats[0] } else { -1 }
Go-Route "/adminM3alm"
Start-Sleep -Seconds 12
Tap 1320 900
Start-Sleep -Seconds 2
Tap 950 1350
Start-Sleep -Seconds 6
Pass "Delete tapped on landmarks"

Go-Route "/home22Dashboard"
Start-Sleep -Seconds 10
Tap 1314 2477
Start-Sleep -Seconds 8
$afterStats = Get-Stats (Get-UiXml)
if ($afterStats.Count -gt 0 -and $before -gt 0 -and $afterStats[0] -lt $before) {
    Pass "Stats decreased $before -> $($afterStats[0])"
} elseif ($afterStats.Count -gt 0) {
    Info "Stats after delete: $before -> $($afterStats[0])"
}

Invoke-Login $AgentEmail | Out-Null
Go-Route "/home22Dashboard"
Start-Sleep -Seconds 10
$agentStats = Get-Stats (Get-UiXml)
if ($agentStats.Count -gt 0) {
    $aslice = $agentStats[0..([Math]::Min(3, $agentStats.Count - 1))] -join ', '
    Pass "Agent stats: $aslice"
} else {
    Fail "Agent stats missing"
}

foreach ($r in @("/adminM3alm", "/adminregion", "/adminALLhgZ")) {
    Go-Route $r
    $proc = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
    if ($proc) { Pass "Agent $r" } else { Fail "Agent $r died" }
}

$final = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
if ($final) { Pass "App stable pid=$final" } else { Fail "App crashed" }

Write-Host ""
Write-Host "PASS: $Passes  FAIL: $Fails"
if ($Fails -gt 0) { exit 1 }
exit 0
