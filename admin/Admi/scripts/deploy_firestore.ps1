# Deploy Firestore indexes and security rules for the admin panel.
# Run from repository root: .\scripts\deploy_firestore.ps1
#
# Syncs indexes from the live project first (avoids 409 duplicate / 400 unnecessary
# index errors), then appends any admin-only composite indexes missing in cloud.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$FirebaseDir = Join-Path $Root "firebase"
$Project = "tutorial-multi-language-70gx4j"
$IndexesFile = Join-Path $FirebaseDir "firestore.indexes.json"
$SyncFile = Join-Path $FirebaseDir ".indexes.sync.json"

$partnerIndexes = @(
  @{
    collectionGroup = "order"
    queryScope        = "COLLECTION"
    fields            = @(
      @{ fieldPath = "ALLNOW"; order = "ASCENDING" }
      @{ fieldPath = "partner_mkans"; arrayConfig = "CONTAINS" }
      @{ fieldPath = "data_order"; order = "DESCENDING" }
    )
  }
  @{
    collectionGroup = "order"
    queryScope        = "COLLECTION"
    fields            = @(
      @{ fieldPath = "ALLNOW"; order = "ASCENDING" }
      @{ fieldPath = "partner_mkans"; arrayConfig = "CONTAINS" }
      @{ fieldPath = "Rev_dolh"; order = "ASCENDING" }
      @{ fieldPath = "data_order"; order = "DESCENDING" }
    )
  }
)

function Index-Key($idx) {
  $parts = @($idx.collectionGroup)
  foreach ($f in $idx.fields) {
    if ($f.fieldPath) { $parts += "$($f.fieldPath):$($f.order)" }
    elseif ($f.arrayConfig) { $parts += "$($f.fieldPath):array:$($f.arrayConfig)" }
  }
  return ($parts -join "|")
}

Write-Host "Syncing Firestore indexes from project $Project ..."
Push-Location $FirebaseDir
try {
  firebase firestore:indexes --project $Project | Out-File -Encoding utf8 $SyncFile
  $cloud = Get-Content $SyncFile -Raw | ConvertFrom-Json
  $seen = @{}
  foreach ($idx in $cloud.indexes) { $seen[Index-Key $idx] = $true }

  $merged = [System.Collections.ArrayList]@($cloud.indexes)
  foreach ($idx in $partnerIndexes) {
    $key = Index-Key $idx
    if (-not $seen[$key]) {
      [void]$merged.Add($idx)
      $seen[$key] = $true
      Write-Host "  + adding index: $key"
    }
  }

  $out = [ordered]@{
    indexes        = $merged
    fieldOverrides = $cloud.fieldOverrides
  }
  ($out | ConvertTo-Json -Depth 20) | Set-Content $IndexesFile -Encoding utf8

  Write-Host "Deploying Firestore rules and indexes ..."
  firebase deploy --only firestore:rules,firestore:indexes --project $Project
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host ""
  Write-Host "Done. New index builds may take several minutes in Firebase Console."
} finally {
  Pop-Location
  if (Test-Path $SyncFile) { Remove-Item $SyncFile -Force }
}
