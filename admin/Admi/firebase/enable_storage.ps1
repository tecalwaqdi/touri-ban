# تفعيل Firebase Storage لمشروع أرى وطن
# 1) فعّل الفوترة يدوياً من الرابط أدناه (مطلوب مرة واحدة)
# 2) شغّل هذا السكربت لنشر قواعد Storage

$ProjectId = "tutorial-multi-language-70gx4j"
$BillingUrl = "https://console.firebase.google.com/project/$ProjectId/usage/details"
$StorageUrl = "https://console.firebase.google.com/project/$ProjectId/storage"

Write-Host ""
Write-Host "=== تفعيل Firebase Storage ===" -ForegroundColor Cyan
Write-Host "المشروع: $ProjectId"
Write-Host ""
Write-Host "الخطوة 1 (يدوية — مرة واحدة):" -ForegroundColor Yellow
Write-Host "  افتح الفوترة وفعّل Blaze (الدفع حسب الاستخدام):"
Write-Host "  $BillingUrl"
Write-Host ""
Write-Host "  ثم افتح Storage وتأكد أن الدلو موجود:"
Write-Host "  $StorageUrl"
Write-Host ""
Write-Host "الخطوة 2: نشر قواعد Storage..." -ForegroundColor Yellow

Set-Location $PSScriptRoot
npx --yes firebase-tools@14.11.0 login --no-localhost 2>$null
npx --yes firebase-tools@14.11.0 deploy --only storage --project $ProjectId

if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "تم نشر قواعد Storage بنجاح." -ForegroundColor Green
  Write-Host "جرّب رفع صورة من تطبيق الأدمن — يجب أن يظهر رابط https://firebasestorage..." -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "فشل النشر. تأكد من:" -ForegroundColor Red
  Write-Host "  - تسجيل الدخول: npx firebase-tools login"
  Write-Host "  - تفعيل الفوترة (Blaze) في Firebase Console"
  Write-Host "  - صلاحيات Owner/Editor على المشروع"
}
