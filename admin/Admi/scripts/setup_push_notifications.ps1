# إعداد ونشر إشعارات الحجوزات — تطبيق الإدمن
# شغّل من PowerShell:  .\scripts\setup_push_notifications.ps1

$ErrorActionPreference = "Stop"
$ProjectId = "tutorial-multi-language-70gx4j"
$AndroidPackage = "com.mycompany.tutorialmultilanguageapp"
$DebugSha1 = "24:CE:96:6E:CE:9F:04:07:84:7D:C4:FE:6D:31:DA:44:F9:3E:CF:8F"
$Root = Split-Path -Parent $PSScriptRoot
$FirebaseDir = Join-Path $Root "firebase"

Write-Host "=== 1) تثبيت اعتماديات Cloud Functions ===" -ForegroundColor Cyan
Push-Location (Join-Path $FirebaseDir "functions")
npm install
Pop-Location

Write-Host "`n=== 2) تسجيل الدخول إلى Firebase ===" -ForegroundColor Cyan
$authOk = $false
try {
    npx firebase-tools projects:list --project $ProjectId 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $authOk = $true }
} catch {}

if (-not $authOk) {
    Write-Host "جلسة Firebase منتهية. سيفتح نافذة تسجيل دخول..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList '-NoExit', '-Command', "cd `"$FirebaseDir`"; npx firebase-tools login --reauth"
    Read-Host "بعد إكمال تسجيل الدخول في النافذة الجديدة، اضغط Enter هنا للمتابعة"
    npx firebase-tools projects:list --project $ProjectId
    if ($LASTEXITCODE -ne 0) {
        throw "فشل تسجيل الدخول. نفّذ يدوياً: cd firebase && npx firebase-tools login --reauth"
    }
}

Write-Host "`n=== 3) إضافة SHA-1 لتطبيق Android (للإشعارات) ===" -ForegroundColor Cyan
$appsJson = npx firebase-tools apps:list --project $ProjectId --json 2>$null | Out-String
if ($appsJson -match $AndroidPackage) {
    Write-Host "جاري إضافة SHA-1 للتطبيق $AndroidPackage ..."
    $appId = "1:638010533068:android:16c1029a0603103c844e69"
    try {
        npx firebase-tools apps:android:sha:create `
            $appId `
            $DebugSha1 `
            --project $ProjectId
        Write-Host "تمت إضافة SHA-1 بنجاح." -ForegroundColor Green
    } catch {
        Write-Host "تعذر الإضافة تلقائياً. أضف يدوياً من Firebase Console:" -ForegroundColor Yellow
        Write-Host "  Project Settings > Your apps > Android > Add fingerprint"
        Write-Host "  SHA-1: $DebugSha1"
    }
} else {
    Write-Host "أضف SHA-1 يدوياً في Firebase Console: $DebugSha1" -ForegroundColor Yellow
}

Write-Host "`n=== 4) نشر Cloud Function + فهارس Firestore ===" -ForegroundColor Cyan
Push-Location $FirebaseDir
npx firebase-tools deploy `
    --only "functions:functions:notifyAdminsOnNewBooking,firestore:indexes" `
    --project $ProjectId
Pop-Location

Write-Host "`n=== تم ===" -ForegroundColor Green
Write-Host "1) ثبّت التطبيق على جوال المدير"
Write-Host "2) سجّل دخول بحساب IsAdmin = true"
Write-Host "3) اسمح بالإشعارات"
Write-Host "4) تأكد من وجود fcm_token في مستند المدمن بـ Firestore"
