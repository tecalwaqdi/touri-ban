# Touri Taxi - Historical Engineering Report (Superseded)

Date: 2026-07-17

> This report is retained for history only. The controlling release decision is
> `touri_taxi_release_readiness_audit.md` dated 2026-07-18. The current verdict is
> **NOT READY** until payment credentials, Firebase deployment, end-to-end tests,
> and fresh release artifacts are completed.

## Executive status

The source now has a stronger foundation for localization, location resolution,
route validation, centralized pricing, and hosted N-Genius payments. Automated
source tests pass, but the post-change Android bundle has not been produced and
payment is not live. Multiple launch gates remain open; see the controlling audit.

## Completed work

### Localization and language handling

- Supported locales are discovered dynamically from `assets/langs/*.json`.
- 11 locale files are currently discovered: ar, az, en, fr, id, ka, ky, ru, tr,
  ur, and zh-Hans.
- Locale persistence, device-locale matching, script-aware Chinese handling, and
  FlutterFlow locale registration use the same discovered locale list.
- Replaced the corrupted legacy language-name source for the active locales with
  clean native names, including `Русский` and `Кыргызча`.
- Corrected the login welcome card and Success Partner panel to use JSON
  translations instead of incomplete FlutterFlow opaque keys.
- Added route, map, unit, payment, wallet, VAT, and location messages to all locales.
- Unified the visible brand to `Touri Taxi` while preserving Android and iOS IDs.
- Automated localization validation checks missing/empty keys, replacement
  characters, and placeholder parity.

### Location and routes

- GPS failure no longer assumes that the user is in Saudi Arabia.
- Country matching prefers ISO country codes and uses Firestore geographic bounds.
- Added ISO codes, centers, and south-west/north-east bounds for 19 target countries.
- Invalid coordinates are rejected: null, zero/zero, NaN, infinity, invalid ranges,
  and implausible out-of-area points.
- Route fallback now sums route legs sequentially instead of selecting one distance.
- OSRM results are accepted only when distance and duration are plausible.
- Impossible values such as 13,036 km and 211 hours are rejected.
- Google Maps launch and map labels follow the selected application locale.

### Booking and pricing

- Added one pricing engine using integer halalas.
- The checkout summary and payment request use the same quote.
- Minimum hours are capped to a practical range and no longer produce values such as
  776 additional hours.
- Pricing invariant is enforced:
  driver net + app fee + VAT - discount = customer total.
- Additional-hour discounts have an explicit configured cap.
- Currency values are locale-formatted in checkout and route displays.

### N-Genius payment security

- Kept Network International / N-Genius as the card provider.
- Removed the obsolete hard-coded outlet fallback; production configuration is
  required.
- Booking payments no longer trust the amount supplied by the mobile application.
- The callable function reads the selected car and country from Firestore, verifies
  they are active, reads hourly price/VAT/discount configuration, and calculates the
  charge in halalas on the server.
- A reconciliation record is written to `payment_quotes` after payment creation.
- Authentication, card validation, expiry validation, gateway status normalization,
  3DS handling, payment verification, and refund paths remain in place.
- Sensitive card state is cleared after use and service credentials are not tracked
  in the public repository.

### Content data

- Verified 19 required countries with flags, ISO codes, centers, and bounds.
- Verified all 13 Saudi administrative regions.
- Verified 260 Saudi landmarks, exactly 20 per region, including coordinates and
  images.
- Added and verified all 7 Kyrgyzstan regions with geographic centers and bounds.
- Added and verified 70 real Kyrgyzstan landmarks, exactly 10 per region, with
  coordinates, images, and Arabic, English, Russian, and Kyrgyz names.
- Added an idempotent Kyrgyzstan seeding command and extended the live Firestore
  verifier to prevent incomplete regions or landmarks from passing silently.
- The final geographic metadata backfill was non-destructive and did not touch
  users, orders, or payment records.

### User interface

- Improved checkout navigation and car-selection return behavior.
- Improved My Trip list and shared surfaces for dark mode.
- Replaced mixed-language and hard-coded checkout/map text with translations.
- Standardized payment, map, price summary, error, and empty-state components.
- Unified visible branding in the splash screen, Android label, and iOS display name.
- Added the selected country's map above its region list in the customer app.
- Country creation in the admin app now resolves and previews the actual map, ISO
  code, center, and bounds; saving is blocked when valid map data cannot be found.
- Added the country-map label to all 11 application locales.

## Verification evidence

- Flutter tests: 17 passed.
- Full Flutter analysis: passed with no issues.
- Android post-change release build: not completed; the older AAB is not valid
  evidence for this update.
- Localization audit: passed for all 11 discovered locales.
- Local content datasets include 19 countries, 13 Saudi regions, 260 Saudi
  landmarks, 7 Kyrgyzstan regions, and 70 Kyrgyzstan landmarks. Production
  migration and post-deployment verification remain pending.
- N-Genius and content JavaScript syntax: passed.
- ESLint for payment/content scripts: passed with zero warnings.
- Targeted Dart analysis for the admin country/map screen: passed with no issues.
- Full Dart analysis completed successfully with no issues.

## Launch blockers

The supplied N-Genius Service Account API keys do not authenticate. Functions,
rules, indexes, and Storage rules are not deployed and verified; a live hosted
payment test has not passed; and fresh Android/iOS release artifacts are missing.

Required owner action:

1. Revoke the previously exposed Firebase Admin service-account key.
2. Obtain and configure a new active N-Genius key through Firebase Secret Manager.
3. Configure all required server secrets, deploy the prepared backend and rules,
   and validate App Check and API-key restrictions.
4. Complete low-value 3DS, decline, retry, refund, webhook, and cash tests.
5. Produce and verify fresh Android and iOS release artifacts.

## Non-blocking maintenance

- Flutter warns that Gradle 8.12, Android Gradle Plugin 8.7.3, and Kotlin 2.1.0 will
  need upgrades in a future Flutter release. The current release build succeeds.
- Google Play and App Store title, description, screenshots, and search metadata must
  be updated in their respective store consoles; application code cannot update an
  already published listing.
- Run final device smoke tests for Arabic RTL, Russian, Kyrgyz, dark mode, GPS denied,
  weak network, 3DS return, and route opening before production rollout.
