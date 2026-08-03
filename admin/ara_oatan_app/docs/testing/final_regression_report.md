# Final regression report (2026-07-19)

## Commands

| Command | Result |
|---------|--------|
| `flutter analyze` (key payment/UI files) | Pass — no issues |
| `flutter test` screenshot + localization + booking regression | Pass |
| `flutter test` screenshot_critical (incl. cash id) | Pass (6/6) |
| `flutter build apk --release` | Pass — `build/app/outputs/flutter-apk/app-release.apk` (~119 MB) |
| `flutter build appbundle --release` | Pass — `build/app/outputs/bundle/release/app-release.aab` (~88 MB) |
| `firebase deploy --only firestore:rules` | Pass — cash create rules live |
| `firebase deploy --only functions…` | **Fail** — Cloud Billing required |

## Critical scenarios

| Scenario | Automated | Device E2E |
|----------|-----------|------------|
| Extra hours change total | Pass | Pending manual |
| NOT_FOUND not raw | Pass | Pending manual |
| ky prefers en over ar for geo names | Pass | Pending manual |
| Cash order id stable | Pass | Pending manual |
| Cash creates Firestore order | Rules + code | **Manual required on device** |
| N-Genius Sandbox | Blocked | Needs billing + deploy |

## Honesty

Do not mark **Store Ready** until device cash E2E confirmed and N-Genius functions published.
