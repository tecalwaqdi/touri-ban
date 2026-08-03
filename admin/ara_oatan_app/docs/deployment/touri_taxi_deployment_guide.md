# Touri Taxi Deployment Guide

## Prerequisites

1. Revoke the Firebase Admin key that previously existed in the project.
2. Create a new N-Genius Service Account API key for the active production
   outlet. Never paste it into Dart, JavaScript, chat, or Git.
3. Confirm Firebase CLI authentication and project
   `tutorial-multi-language-70gx4j`.
4. Register Android/iOS/web App Check providers and obtain release signing data.
5. Restrict mobile/web Google Maps keys by package, SHA certificates, bundle id,
   and web referrer. Keep the server Directions key server-only.

## Function configuration

Set these values using Firebase Secret Manager / environment configuration:

- `NGENIUS_API_KEY` (secret)
- `NGENIUS_OUTLET_REF=63c9f06b-19ad-4963-a8d8-50538be90f54`
- `NGENIUS_PRODUCTION=true`
- `NGENIUS_REALM=networkinternational`
- `ULTRAMSG_TOKEN` (secret)
- `ULTRAMSG_INSTANCE`
- `OPENCAGE_API_KEY` (secret)
- `GOOGLE_MAPS_SERVER_API_KEY` (secret)
- `WASL_DISPATCH_CREDENTIALS` (secret JSON)
- `WASL_TRACKING_CREDENTIALS` (secret JSON)

Use the exact secret declarations present in the Functions source. Do not
create `.env` or service-account files in the repository.

## Pre-deployment commands

From `ara_oatan_app/firebase/functions`:

```powershell
npm.cmd ci
npm.cmd run lint
npm.cmd run test:unit
```

From `ara_oatan_app`:

```powershell
flutter pub get
flutter analyze
flutter test
node tool/check_localizations.js
node tool/check_hardcoded_ui_strings.js
```

Run Firebase emulator tests for Firestore and Storage before production. This
step was not completed in the current environment and is a release gate.

## Deployment order

From `ara_oatan_app/firebase` after all tests pass:

```powershell
firebase use tutorial-multi-language-70gx4j
firebase deploy --only firestore:indexes
firebase deploy --only firestore:rules,storage
firebase deploy --only functions
firebase deploy --only hosting
```

Record command output, deployed function revisions, rule release timestamps,
and hosting version. The current work did **not** execute these deployments.

## Post-deployment verification

1. Confirm unauthorized Firestore and Storage writes are denied.
2. Confirm App Check rejects unverified callable requests.
3. Create one low-value hosted payment under the merchant-approved procedure.
4. Verify 3DS return, webhook signature/state, order creation exactly once,
   receipt, localized notifications, cancellation, and refund.
5. Verify cash booking produces `cash_pending`, never `paid`.
6. Verify customer/driver live route and deep links on real Android devices.
7. Review Functions logs for redaction; no tokens, credentials, PAN, or CVV.

## Android and iOS

Build Android only after Firebase acceptance:

```powershell
flutter build appbundle --release
```

Verify the AAB timestamp, ZIP integrity, manifest, signing certificate, version
code, and SHA-256. The post-change build in this audit timed out and did not
produce a new artifact.

Build iOS on macOS/Xcode, verify bundle/signing/entitlements, then run the same
payment, map, notification, locale, and dark-mode matrix.

## Rollback

- Retain the previous Functions revision and rule source before deployment.
- Roll back Functions through Firebase/Google Cloud revision controls.
- Re-deploy the last approved rules/index files if behavioral tests fail.
- Disable payment initiation with server configuration if reconciliation fails;
  never mark payments successful from the client as a fallback.
