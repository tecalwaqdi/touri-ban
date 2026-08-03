# Touri Deployment Guide

**Date:** 2026-07-18  
**Firebase:** `tutorial-multi-language-70gx4j`

## What ships where

| Artifact | Path | Target |
|----------|------|--------|
| Customer app | `admin/ara_oatan_app` | Stores / internal tracks — Android `com.mycompany.araoatanapp`, iOS `com.mycompany.araoatanapp2` |
| Driver app | `admin/mndob-main` | Same Firebase — Android `com.mycompany.mndob2`, iOS `com.mycompany.mndob3` |
| Admin | `admin/Admi` | Web / panel — `com.mycompany.tutorialmultilanguageapp` |
| Cloud Functions | project functions (incl. `ngenius_payments.js`) | Firebase Functions |
| Do **not** ship | `mndob-main` (root), `arawatan/` | ARCHIVE |

## Pre-deploy checklist

| Step | Status |
|------|--------|
| Unit regression green | Run `flutter test` regression + localization |
| Redeploy Functions with `pending_driver` write | OPEN — local only this session |
| Redeploy Rules if changed | OPEN |
| Fix driver `google-services.json` package_name = `com.mycompany.mndob2` | OPEN |
| Confirm N-Genius env (sandbox vs live) | OPEN |
| Smoke customer pay → pending on device | OPEN |

## Suggested order

1. Fix driver Firebase config mismatch  
2. Deploy Cloud Functions (payment status writers)  
3. Deploy Rules if needed  
4. Build & distribute customer + driver internal builds  
5. Run sandbox E2E before widening track  

## Build commands (customer)

```bash
cd admin/ara_oatan_app
flutter test
flutter build apk --release   # confirm locally before store
# iOS: flutter build ipa (on macOS CI/host)
```

## Functions deploy

Deploy from the Firebase project that owns `tutorial-multi-language-70gx4j`. Ensure `ngenius_payments.js` (or bundled equivalent) includes:

- `status_code=pending_driver`
- Arabic pending `halh_text`

**Status:** Functions **not** redeployed this session — OPEN.

## Tracks

| Track | When |
|-------|------|
| Internal QA | Unit tests pass + internal APK/IPA |
| Closed testing | Sandbox payment E2E pass |
| Store | All OPEN blockers closed; prod payment configured |

## Rollback

See `docs/deployment/touri_migration_and_rollback.md`.
