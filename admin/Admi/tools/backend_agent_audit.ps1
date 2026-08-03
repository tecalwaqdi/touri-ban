param(
    [string]$AgentEmail = "demo.agent@arawatan.sa",
    [string]$Password = "Demo@2026",
    [string]$Project = "tutorial-multi-language-70gx4j",
    [string]$ApiKey = "AIzaSyCynvmYpEHNlSvB-tf5v6AdaA2q7IT4P5w"
)

$Passes = 0
$Fails = 0

function Pass($m) { $script:Passes++; Write-Host "[PASS] $m" -ForegroundColor Green }
function Fail($m) { $script:Fails++; Write-Host "[FAIL] $m" -ForegroundColor Red }

function Get-Token([string]$Email) {
    $body = @{ email = $Email; password = $Password; returnSecureToken = $true } | ConvertTo-Json
    $auth = Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey" -Body $body -ContentType "application/json"
    return @{ Token = $auth.idToken; Uid = $auth.localId }
}

function Get-User([hashtable]$Auth) {
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/user/$($Auth.Uid)"
    return Invoke-RestMethod -Uri $uri -Headers $headers
}

function Ref-Id($f) {
    if (-not $f) { return $null }
    if ($f.referenceValue) { return ($f.referenceValue -split '/')[-1] }
    if ($f.stringValue) { return $f.stringValue }
    return $null
}

function List-Docs([hashtable]$Auth, [string]$Collection, [int]$Size = 5) {
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/${Collection}?pageSize=$Size"
    $r = Invoke-RestMethod -Uri $uri -Headers $headers
    return @($r.documents)
}

function Test-Read([hashtable]$Auth, [string]$Collection) {
    try {
        $docs = List-Docs $Auth $Collection 3
        Pass "read $Collection ($($docs.Count) docs)"
    } catch {
        Fail "read ${Collection}: $($_.Exception.Message)"
    }
}

function Test-DeleteMkan([hashtable]$Auth) {
    $docs = List-Docs $Auth "mkan" 1
    if (-not $docs -or $docs.Count -eq 0) {
        Fail "no mkan to delete"
        return
    }
    $id = ($docs[0].name -split '/')[-1]
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/mkan/$id"
    try {
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers | Out-Null
        try {
            Invoke-RestMethod -Uri $uri -Headers $headers | Out-Null
            Fail "mkan/$id still exists after delete"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 404) {
                Pass "delete mkan/$id"
            } else {
                Fail "verify mkan delete: $($_.Exception.Message)"
            }
        }
    } catch {
        Fail "delete mkan/${id}: $($_.ErrorDetails.Message)"
    }
}

function Test-BlockedDelete([hashtable]$Auth, [string]$Collection) {
    $docs = List-Docs $Auth $Collection 1
    if (-not $docs -or $docs.Count -eq 0) {
        Pass "skip blocked delete $Collection (no docs)"
        return
    }
    $id = ($docs[0].name -split '/')[-1]
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/${Collection}/$id"
    try {
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers | Out-Null
        Fail "agent should not delete $Collection/$id"
    } catch {
        Pass "blocked delete $Collection (permission denied)"
    }
}

Write-Host "=== Backend Agent Audit ===" -ForegroundColor Cyan
$agent = Get-Token $AgentEmail
Pass "login uid=$($agent.Uid)"

$user = Get-User $agent
$country = Ref-Id $user.fields.Rev_dloh_agent
if (-not $country) { $country = Ref-Id $user.fields.Rev_dolh }
if ($country) {
    Pass "agent country=$country"
} else {
    Fail "agent has no country scope"
}

$rule = $user.fields.isAdminRule.integerValue
if ($rule -eq '2') { Pass "role=country agent (2)" } else { Fail "role expected 2 got $rule" }

foreach ($c in @("mkan", "cities", "villages", "order")) {
    Test-Read $agent $c
}

# Agent can read own profile; collection list may be restricted.
try {
    $headers = @{ Authorization = "Bearer $($agent.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/user/$($agent.Uid)"
    Invoke-RestMethod -Uri $uri -Headers $headers | Out-Null
    Pass "read own user profile"
} catch {
    Fail "read own user profile: $($_.Exception.Message)"
}

Test-DeleteMkan $agent
Test-BlockedDelete $agent "countries"

Write-Host ""
Write-Host "PASS: $Passes  FAIL: $Fails"
if ($Fails -gt 0) { exit 1 }
exit 0
