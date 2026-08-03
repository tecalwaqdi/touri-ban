param(
    [string]$SuperEmail = "demo.super@arawatan.sa",
    [string]$AgentEmail = "demo.agent@arawatan.sa",
    [string]$Password = "Demo@2026",
    [string]$Project = "tutorial-multi-language-70gx4j",
    [string]$ApiKey = "AIzaSyCynvmYpEHNlSvB-tf5v6AdaA2q7IT4P5w"
)

$Passes = 0
$Fails = 0
$Skips = 0

function Pass($m) { $script:Passes++; Write-Host "[PASS] $m" -ForegroundColor Green }
function Fail($m) { $script:Fails++; Write-Host "[FAIL] $m" -ForegroundColor Red }
function Skip($m) { $script:Skips++; Write-Host "[SKIP] $m" -ForegroundColor Yellow }

function Get-Token([string]$Email) {
    $body = @{ email = $Email; password = $Password; returnSecureToken = $true } | ConvertTo-Json
    $auth = Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey" -Body $body -ContentType "application/json"
    return @{ Token = $auth.idToken; Uid = $auth.localId }
}

function Get-UserDoc([hashtable]$Auth) {
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/user/$($Auth.Uid)"
    return Invoke-RestMethod -Uri $uri -Headers $headers
}

function Ref-Id($fieldValue) {
    if (-not $fieldValue) { return $null }
    if ($fieldValue.stringValue) { return $fieldValue.stringValue }
    if ($fieldValue.referenceValue) { return ($fieldValue.referenceValue -split '/')[-1] }
    return $null
}

function Test-Delete([hashtable]$Auth, [string]$Collection, [string]$DocId, [string]$Label) {
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/$Collection/$DocId"
    try {
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers | Out-Null
        try {
            Invoke-RestMethod -Uri $uri -Headers $headers | Out-Null
            Fail "$Label delete denied or failed (still exists)"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 404) {
                Pass "$Label delete OK"
            } else {
                Fail "$Label delete verify: $($_.Exception.Message)"
            }
        }
    } catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        Fail "$Label delete: $detail"
    }
}

function Get-FirstDoc([hashtable]$Auth, [string]$Collection, [int]$PageSize = 20) {
    $headers = @{ Authorization = "Bearer $($Auth.Token)" }
    $list = Invoke-RestMethod -Uri "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/${Collection}?pageSize=$PageSize" -Headers $headers
    if (-not $list.documents) { return $null }
    return $list.documents
}

function Get-AgentScopedVillage([hashtable]$Auth, [string]$AgentCountryId) {
    $docs = Get-FirstDoc $Auth "villages" 50
    if (-not $docs) { return $null }
    foreach ($doc in $docs) {
        $id = ($doc.name -split '/')[-1]
        $fields = $doc.fields
        $dolh = Ref-Id $fields.dolh
        if ($dolh -eq $AgentCountryId) { return $id }
        $city = Ref-Id $fields.cities
        if ($city) {
            $headers = @{ Authorization = "Bearer $($Auth.Token)" }
            try {
                $cityDoc = Invoke-RestMethod -Uri "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/cities/$city" -Headers $headers
                $cityDolh = Ref-Id $cityDoc.fields.dolh
                if ($cityDolh -eq $AgentCountryId -or ($AgentCountryId -in @('saudi_arabia','demo_saudi') -and $cityDolh -in @('saudi_arabia','demo_saudi'))) {
                    return $id
                }
            } catch { }
        }
    }
    return $null
}

Write-Host "=== Backend CRUD Audit ===" -ForegroundColor Cyan

$super = Get-Token $SuperEmail
$agent = Get-Token $AgentEmail
Pass "Super login uid=$($super.Uid)"
Pass "Agent login uid=$($agent.Uid)"

$agentUser = Get-UserDoc $agent
$agentCountry = Ref-Id $agentUser.fields.Rev_dloh_agent
if (-not $agentCountry) { $agentCountry = Ref-Id $agentUser.fields.Rev_dolh }
if ($agentCountry) { Pass "Agent country=$agentCountry" } else { Fail "Agent has no country ref" }

$mkanSuper = (Get-FirstDoc $super "mkan" 1)
if ($mkanSuper) { Test-Delete $super "mkan" (($mkanSuper[0].name -split '/')[-1]) "super/mkan" } else { Skip "No mkan for super delete test" }

$mkanAgent = (Get-FirstDoc $agent "mkan" 1)
if ($mkanAgent) { Test-Delete $agent "mkan" (($mkanAgent[0].name -split '/')[-1]) "agent/mkan" } else { Skip "No mkan for agent delete test" }

$citySuper = (Get-FirstDoc $super "cities" 1)
if ($citySuper) { Test-Delete $super "cities" (($citySuper[0].name -split '/')[-1]) "super/cities" } else { Skip "No cities for super delete test" }

if ($agentCountry) {
    $villAgent = Get-AgentScopedVillage $agent $agentCountry
    if ($villAgent) {
        Test-Delete $agent "villages" $villAgent "agent/villages (in-scope)"
    } else {
        Skip "No in-scope village for agent delete test"
    }
}

Write-Host ""
Write-Host "PASS: $Passes  FAIL: $Fails  SKIP: $Skips"
if ($Fails -gt 0) { exit 1 }
exit 0
