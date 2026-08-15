# App Store Review Fix — Driver 11.1.4 (Aug 13, 2026)

## Rejection summary

| Guideline | Issue | Fix |
|-----------|-------|-----|
| **2.5.4** | `UIBackgroundModes` included `location` without demonstrable persistent background tracking | Removed `location` from iOS + removed `ACCESS_BACKGROUND_LOCATION` on Android. App uses **When In Use** location only. |
| **2.1** | Demo login `info@touri-taxi.com` / `tourytaxi@2030` failed | Seed script recreates Auth user + approved driver profile + wallet |

## Code changes (this repo)

- `ios/Runner/Info.plist` — removed `location` background mode + Always location usage strings
- `android/app/src/main/AndroidManifest.xml` — removed background location permission
- `pubspec.yaml` — **11.1.4+18**
- `ios/ImageNotification/Info.plist` — aligned to 11.1.4 / 18
- `admin/scripts/seed_app_store_driver_review.js` — production demo account seeder

## Before uploading build — REQUIRED

Refresh Firebase Admin credentials, then seed the review account:

```bash
gcloud auth application-default login
cd admin/ara_oatan_app/firebase/functions && npm ci
node ../../scripts/seed_app_store_driver_review.js
```

Expected output: `"ok": true` with uid + wallet.

Verify on simulator/device:

1. Open **Touri Taxi Driver**
2. Sign in: `info@touri-taxi.com` / `tourytaxi@2030`
3. Allow location **While Using the App**
4. Home screen loads (approved driver, offline)
5. Wallet shows balance (~2000 SAR)

## Build & upload

```bash
cd admin/mndob-main
flutter pub get
cd ../..
./admin/scripts/build_driver_ipa.sh
./admin/scripts/upload_ios_store_ipas.sh   # or your usual ASC upload
```

## App Store Connect — Review notes (paste)

**Demo account (full driver access):**

- Email: `info@touri-taxi.com`
- Password: `tourytaxi@2030`

Account is pre-approved with wallet balance. After sign-in, tap **Go Online** (location permission: **While Using the App** only).

**Background location:**

We removed persistent background location from this build. Location is used only while the app is in the foreground (map, going online, active trip tracking).

## Reply to Apple (App Store Connect message)

```
Hello,

Thank you for the review feedback.

Guideline 2.5.4 — We removed the "location" entry from UIBackgroundModes. The driver app now requests location only while in use (map, matching nearby orders, and trip tracking when the app is open). We do not require persistent background location in this version.

Guideline 2.1 — We reset the demo driver account credentials:
Email: info@touri-taxi.com
Password: tourytaxi@2030

The account is fully approved with an active driver profile and wallet balance. Please sign in and allow location "While Using the App" to access all features.

Thank you.
```
