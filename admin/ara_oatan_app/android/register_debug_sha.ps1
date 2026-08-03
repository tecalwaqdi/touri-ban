# Registers the local debug SHA-1 in Firebase and refreshes google-services.json.
# Run once after: firebase login --reauth

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AndroidAppId = '1:638010533068:android:6dc1f98d8c07b48a844e69'

$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
Push-Location (Join-Path $ProjectRoot 'android')
try {
    $report = .\gradlew.bat :app:signingReport 2>&1 | Out-String
    if ($report -notmatch 'Variant: debug[\s\S]*?SHA1: ([0-9A-F:]+)') {
        throw 'Could not read debug SHA-1 from signingReport.'
    }
    $shaColon = $Matches[1]
    $shaHex = ($shaColon -replace ':', '').ToUpper()
    Write-Host "Debug SHA-1: $shaColon"
    Write-Host "Registering in Firebase project tutorial-multi-language-70gx4j ..."

    firebase apps:android:sha:create $AndroidAppId $shaHex
    firebase apps:sdkconfig android $AndroidAppId `
        --out (Join-Path $ProjectRoot 'android\app\google-services.json')

    Write-Host 'Done. Also enable Maps SDK for Android in Google Cloud Console for this API key.'
    Write-Host 'Rebuild the app: flutter run'
} finally {
    Pop-Location
}
