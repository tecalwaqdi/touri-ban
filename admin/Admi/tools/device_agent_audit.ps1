param(
    [string]$Device = "RF8M73GXMYV",
    [string]$Package = "com.mycompany.tutorialmultilanguageapp",
    [string]$AgentEmail = "demo.agent@arawatan.sa",
    [string]$Password = "Demo@2026",
    [int]$StabilitySeconds = 60
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
    Invoke-Adb shell uiautomator dump /sdcard/ui_agent_audit.xml | Out-Null
    Start-Sleep -Milliseconds 450
    return [string](Invoke-Adb shell cat /sdcard/ui_agent_audit.xml 2>$null)
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

function App-Running {
    $p = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
    return -not [string]::IsNullOrWhiteSpace($p)
}

function Invoke-AgentLogin {
    Info "Login $AgentEmail"
    Invoke-Adb shell am force-stop $Package | Out-Null
    Start-Sleep -Seconds 1
    Invoke-Adb shell am start -n "$Package/.MainActivity" | Out-Null
    Start-Sleep -Seconds 8
    Tap 720 1545
    $enc = $AgentEmail -replace '@', '%40'
    Invoke-Adb shell input text $enc | Out-Null
    Start-Sleep -Milliseconds 500
    Tap 720 1860
    $pw = $Password -replace '@', '%40'
    Invoke-Adb shell input text $pw | Out-Null
    Invoke-Adb shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 400
    Tap 720 2529
    Start-Sleep -Seconds 22
    $after = Get-UiXml
    if ($after -match 'password="true"') {
        Fail "Agent login failed"
        return $false
    }
    Pass "Agent login OK"
    return $true
}

function Test-Route([string]$Path, [string]$Label) {
    Go-Route $Path
    if (-not (App-Running)) {
        Fail "$Label crashed"
        return
    }
    Pass $Label
}

function Test-BlockedRoute([string]$Path, [string]$Label) {
    Go-Route $Path
    Start-Sleep -Seconds 3
    $xml = Get-UiXml
    if (-not (App-Running)) {
        Fail "$Label caused crash"
        return
    }
    $blockedHints = @('Add country', 'Add agent', 'Super admin', 'Audit log')
    $leaked = $false
    foreach ($h in $blockedHints) {
        if ($xml -match [regex]::Escape($h)) {
            $leaked = $true
            break
        }
    }
    if ($leaked) {
        Fail "$Label accessible"
    } else {
        Pass "$Label blocked"
    }
}

if (-not (Test-AdbDevice $Device)) {
    Write-Host "FAIL: device $Device not connected"
    exit 4
}

Info "=== Agent account audit on $Device ==="

if (-not (Invoke-AgentLogin)) { exit 1 }

Go-Route "/home22Dashboard"
Start-Sleep -Seconds 10
$dash = Get-UiXml
$stats = Get-Stats $dash
if ($stats.Count -ge 3) {
    $slice = $stats[0..([Math]::Min(5, $stats.Count - 1))] -join ', '
    Pass "Dashboard stats: $slice"
} elseif ($stats.Count -gt 0) {
    Pass "Dashboard stats partial: $($stats -join ', ')"
} else {
    Fail "Dashboard stats missing"
}

$allowed = @(
    @{ Path = "/adminM3alm"; Label = "route landmarks" },
    @{ Path = "/adminregion"; Label = "route regions" },
    @{ Path = "/adminvill"; Label = "route cities" },
    @{ Path = "/adminPartners"; Label = "route partners" },
    @{ Path = "/adminuser"; Label = "route users" },
    @{ Path = "/drever"; Label = "route reps" },
    @{ Path = "/adminDrivers"; Label = "route drivers" },
    @{ Path = "/adminTransportCompanies"; Label = "route transport" },
    @{ Path = "/adminALLhgZ"; Label = "route bookings" },
    @{ Path = "/adminProfits"; Label = "route profits" },
    @{ Path = "/adminSuport"; Label = "route support" },
    @{ Path = "/settings"; Label = "route settings" },
    @{ Path = "/addReg"; Label = "route add region" },
    @{ Path = "/addVill"; Label = "route add city" },
    @{ Path = "/adminaddMkan"; Label = "route add landmark" }
)

foreach ($r in $allowed) {
    Test-Route $r.Path $r.Label
}

$blocked = @(
    @{ Path = "/adminDol"; Label = "blocked countries" },
    @{ Path = "/adminAgent"; Label = "blocked agents" },
    @{ Path = "/adminReportsHub"; Label = "blocked reports" },
    @{ Path = "/adminSuperAdmins"; Label = "blocked super admins" },
    @{ Path = "/adminAuditLog"; Label = "blocked audit log" }
)

foreach ($r in $blocked) {
    Test-BlockedRoute $r.Path $r.Label
}

$beforeCount = if ($stats.Count -gt 0) { $stats[0] } else { -1 }
Go-Route "/adminM3alm"
Start-Sleep -Seconds 12
Tap 1320 900
Start-Sleep -Seconds 2
Tap 950 1350
Start-Sleep -Seconds 8
if (App-Running) { Pass "delete landmark list mode" } else { Fail "delete landmark list mode crash" }

Go-Route "/home22Dashboard"
Start-Sleep -Seconds 8
$afterStats = Get-Stats (Get-UiXml)
if ($beforeCount -gt 0 -and $afterStats.Count -gt 0 -and $afterStats[0] -lt $beforeCount) {
    Pass "stats decreased $beforeCount -> $($afterStats[0])"
} elseif ($afterStats.Count -gt 0) {
    Info "stats after delete: $beforeCount -> $($afterStats[0])"
}

Go-Route "/adminM3alm"
Start-Sleep -Seconds 10
Tap 720 350
Start-Sleep -Milliseconds 500
Invoke-Adb shell input text "demo" | Out-Null
Start-Sleep -Seconds 4
Tap 1320 900
Start-Sleep -Seconds 2
Tap 950 1350
Start-Sleep -Seconds 6
if (App-Running) { Pass "delete landmark search mode" } else { Fail "delete landmark search mode crash" }

Info "Stability watch ${StabilitySeconds}s"
$stable = $true
for ($i = 1; $i -le $StabilitySeconds; $i++) {
    Start-Sleep -Seconds 1
    if (-not (App-Running)) {
        Fail "crash at ${i}s"
        $stable = $false
        break
    }
}
if ($stable) {
    $procId = [string](Invoke-Adb shell pidof $Package 2>$null).Trim()
    Pass "stable ${StabilitySeconds}s pid=$procId"
}

Write-Host ""
Write-Host "PASS: $Passes  FAIL: $Fails"
if ($Fails -gt 0) { exit 1 }
exit 0
