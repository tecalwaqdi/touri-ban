param(
    [string]$Device = "RF8M73GXMYV",
    [string]$Package = "com.mycompany.tutorialmultilanguageapp",
    [int]$Seconds = 500
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

function Get-AppPid {
    $raw = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
    if ($raw -match '\s') { return $raw.Split()[0] }
    return $raw
}

function Go-Route([string]$Path) {
    Start-AdbDeepLink -Device $Device -Package $Package -Path $Path
    Start-Sleep -Seconds 4
}

function Get-UiXml {
    Invoke-Adb shell uiautomator dump /sdcard/ui_stress.xml 2>$null | Out-Null
    Start-Sleep -Milliseconds 350
    return [string](Invoke-Adb shell cat /sdcard/ui_stress.xml 2>$null)
}

function Get-StatNumbers([string]$Xml) {
    [regex]::Matches($Xml, 'content-desc="(\d+)"') |
        ForEach-Object { [int]$_.Groups[1].Value } |
        Where-Object { $_ -ge 0 -and $_ -le 999999 }
}

function Test-LoginScreen([string]$Xml) {
    return $Xml -match 'class="android.widget.EditText"' -and $Xml -match 'password="true"'
}

function Invoke-DeviceLogin {
    Invoke-Adb shell input tap 720 1447 | Out-Null; Start-Sleep 1
    Invoke-Adb shell input text "demo.super%40arawatan.sa" | Out-Null; Start-Sleep 1
    Invoke-Adb shell input tap 720 1762 | Out-Null; Start-Sleep 1
    Invoke-Adb shell input text "Demo%402026" | Out-Null
    Invoke-Adb shell input keyevent 4 | Out-Null; Start-Sleep 1
    Invoke-Adb shell input tap 720 2431 | Out-Null
    Start-Sleep -Seconds 20
}

function Tap-CountryDropdown {
    Invoke-Adb shell input tap 720 835 | Out-Null
    Start-Sleep -Milliseconds 900
}

function Pick-CountryOption([int]$Index) {
    $y = 1050 + ($Index * 180)
    Invoke-Adb shell input tap 720 $y | Out-Null
    Start-Sleep -Seconds 5
}

function Tap-ReportsRefresh {
    Invoke-Adb shell input tap 720 1073 | Out-Null
    Start-Sleep -Seconds 6
}

function Tap-DashboardRefresh {
    Invoke-Adb shell input tap 1320 450 | Out-Null
    Start-Sleep -Seconds 6
}

$script:logLines = New-Object System.Collections.Generic.List[string]
function Write-TestLog([string]$Msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Msg"
    Write-Host $line
    [void]$script:logLines.Add($line)
}

Invoke-Adb logcat -c | Out-Null
Go-Route "/home22Dashboard"
$xml = Get-UiXml
if (Test-LoginScreen $xml) {
    Write-TestLog "Login required"
    Invoke-DeviceLogin
    Go-Route "/home22Dashboard"
}

$startPid = Get-AppPid
Write-TestLog "START pid=$startPid duration=${Seconds}s"

$routes = @(
    @{ Name = "dashboard"; Path = "/home22Dashboard"; Refresh = { Tap-DashboardRefresh } },
    @{ Name = "reports"; Path = "/adminReportsHub"; Refresh = { Tap-ReportsRefresh } },
    @{ Name = "landmarks"; Path = "/adminM3alm"; Refresh = { } },
    @{ Name = "agents"; Path = "/adminAgent"; Refresh = { } },
    @{ Name = "bookings"; Path = "/adminALLhgZ"; Refresh = { } },
    @{ Name = "countries"; Path = "/adminDol"; Refresh = { } }
)

$countryIdx = 0
$deadAt = 0
$elapsed = 0
$step = 0
$interval = [math]::Max(28, [int]($Seconds / 16))

$dashStats = @()
$reportStatsAll = @()
$reportStatsFiltered = @()

while ($elapsed -lt $Seconds) {
    $appPid = Get-AppPid
    if ([string]::IsNullOrWhiteSpace($appPid)) {
        $deadAt = $elapsed
        Write-TestLog "CRASH process dead at ${elapsed}s"
        break
    }

    if ($elapsed -ge ($step * $interval)) {
        $r = $routes[$step % $routes.Count]
        Write-TestLog "NAV -> $($r.Name)"
        Go-Route $r.Path
        $xml = Get-UiXml
        $nums = Get-StatNumbers $xml
        Write-TestLog ("  stats: " + ($nums -join ', '))

        if ($r.Name -eq "dashboard") {
            & $r.Refresh
            $xml2 = Get-UiXml
            $dashStats += ,@(Get-StatNumbers $xml2)
            Write-TestLog ("  dashboard refresh: " + ((Get-StatNumbers $xml2) -join ', '))
        }
        elseif ($r.Name -eq "reports") {
            Tap-CountryDropdown
            Pick-CountryOption ($countryIdx % 4)
            $countryIdx++
            $xmlF = Get-UiXml
            $reportStatsFiltered += ,@(Get-StatNumbers $xmlF)
            Write-TestLog ("  reports country filter: " + ((Get-StatNumbers $xmlF) -join ', '))
            Tap-CountryDropdown
            Invoke-Adb shell input tap 720 980 | Out-Null
            Start-Sleep -Seconds 5
            & $r.Refresh
            $xmlA = Get-UiXml
            $reportStatsAll += ,@(Get-StatNumbers $xmlA)
            Write-TestLog ("  reports all countries: " + ((Get-StatNumbers $xmlA) -join ', '))
            Invoke-Adb shell input swipe 720 2200 720 800 350 | Out-Null
            Start-Sleep -Seconds 2
        }
        else {
            Invoke-Adb shell input swipe 720 2000 720 900 300 | Out-Null
            Start-Sleep -Seconds 2
            Invoke-Adb shell input keyevent 4 | Out-Null
            Start-Sleep -Milliseconds 600
        }
        $step++
    }

    Start-Sleep -Seconds 5
    $elapsed += 5
    if (($elapsed % 60) -eq 0) {
        Write-TestLog "ALIVE ${elapsed}s pid=$appPid"
    }
}

if ($deadAt -eq 0) {
    Write-TestLog "PASS stable ${Seconds}s final pid=$(Get-AppPid)"
}

Write-TestLog "=== Stats accuracy ==="
if ($dashStats.Count -gt 0) {
    $lastDash = $dashStats[-1]
    Write-TestLog ("Dashboard last sample: " + ($lastDash -join ', '))
}
if ($reportStatsAll.Count -gt 0) {
    $lastAll = $reportStatsAll[-1]
    Write-TestLog ("Reports all-countries last: " + ($lastAll -join ', '))
    if ($lastAll.Count -gt 0 -and $dashStats.Count -gt 0) {
        $d0 = $dashStats[-1][0]
        $r0 = $lastAll[0]
        if ($d0 -eq $r0) { Write-TestLog "OK landmarks match dashboard=$d0 reports=$r0" }
        else { Write-TestLog "WARN landmarks mismatch dashboard=$d0 reports=$r0" }
    }
}
if ($reportStatsFiltered.Count -gt 0) {
    Write-TestLog ("Reports filtered samples count: $($reportStatsFiltered.Count)")
}

Write-TestLog "=== Crash scan ==="
$crash = Invoke-Adb logcat -d -t 600 2>&1 | Select-String -Pattern "FATAL|SIGABRT|Process.*died" -CaseSensitive:$false
if ($crash) { $crash | Select-Object -Last 10 | ForEach-Object { Write-TestLog $_.Line } }
else { Write-TestLog "No fatal crash in logcat" }

$out = Join-Path $env:TEMP "admin_500s_stress.log"
$script:logLines | Out-File $out -Encoding utf8
Write-TestLog "Saved: $out"
if ($deadAt -gt 0) { exit 2 }
exit 0
