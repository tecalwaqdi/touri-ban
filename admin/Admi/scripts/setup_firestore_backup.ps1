# Firestore backup setup for tutorial-multi-language-70gx4j
# Requires: Firebase CLI (firebase) + Blaze plan for scheduled backups
# Optional: Google Cloud SDK (gcloud) for automated schedules

$ErrorActionPreference = "Stop"
$ProjectId = "tutorial-multi-language-70gx4j"
$Bucket = "gs://${ProjectId}-backups"
$Region = "europe-west1"

Write-Host "=== Firestore Backup Setup ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectId"
Write-Host ""

# 1) One-time manual export (needs Storage bucket)
Write-Host "[1] Manual export command (run after creating bucket):" -ForegroundColor Yellow
Write-Host "  firebase use $ProjectId"
Write-Host "  gcloud storage buckets create $Bucket --project=$ProjectId --location=$Region"
Write-Host "  gcloud firestore export $Bucket/manual-backup-`$(Get-Date -Format yyyyMMdd-HHmm) --project=$ProjectId"
Write-Host ""

# 2) Scheduled daily backup (requires gcloud + Blaze)
Write-Host "[2] Scheduled daily backup (Firebase Console or gcloud):" -ForegroundColor Yellow
Write-Host "  Console: Firebase > Firestore > Backups > Enable scheduled backups"
Write-Host "  Or with gcloud:"
Write-Host "  gcloud firestore backups schedules create \"
Write-Host "    --database='(default)' \"
Write-Host "    --recurrence=daily \"
Write-Host "    --retention=7d \"
Write-Host "    --project=$ProjectId"
Write-Host ""

# 3) Try firebase login status
Write-Host "[3] Checking Firebase CLI..." -ForegroundColor Yellow
firebase projects:list 2>&1 | Select-Object -First 5

Write-Host ""
Write-Host "Done. Enable Blaze plan in Firebase Console if backups are not available." -ForegroundColor Green
