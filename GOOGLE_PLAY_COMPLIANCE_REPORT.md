# Google Play Compliance Report — Touri Taxi

**Date:** 2026-09-12  
**Scope:** Customer (`ara_oatan_app`) + Driver (`mndob-main`) + Firebase Functions + `touri-website`

---

## 1) Rejection reasons addressed

| Play issue | Resolution |
|--|--|
| Invalid account deletion link | Added bilingual `/delete-account` pages + verified-request API (no blind delete). **URL not production-live until website deploy.** |
| Data safety Email mismatch | Audit confirms Email is collected; recommend Collected=Yes, Shared=No (processors). See `GOOGLE_PLAY_DATA_SAFETY_AUDIT.md`. |
| Target API too low | Customer raised to compile/target **36** (Driver already 36). Verified in release merged manifests. |

---

## 2) Files changed (high level)

### Android
- `admin/ara_oatan_app/android/app/build.gradle` — compileSdk/targetSdk 36
- `admin/ara_oatan_app/android/build.gradle` — subproject compileSdk 36

### Backend
- `admin/Admi/firebase/functions/account_deletion.js` — **new**
- `admin/Admi/firebase/functions/test/account_deletion.test.js` — **new**
- `admin/Admi/firebase/functions/index.js` — exports `requestAccountDeletion`, `createAccountDeletionRequest`, hardened `onUserDeleted`

### Customer app
- `lib/core/toury_account_deletion_service.dart` — **new**
- `lib/profile/profile05/profile05_widget.dart` — real deletion UI + reauth + callable
- `lib/backend/cloud_functions/cloud_functions.dart` — surface `details`
- `pubspec.yaml` — `9.1.32+51`

### Driver app
- `lib/core/driver_account_deletion_service.dart` — **new**
- `lib/profile07/profile07_widget.dart` — real deletion (was support-ticket only)
- `lib/backend/cloud_functions/cloud_functions.dart` — typed deletion errors
- `pubspec.yaml` — `11.1.14+40`

### Website
- `src/app/[locale]/delete-account/page.tsx`
- `src/components/legal/DeleteAccountForm.tsx`
- `src/app/api/account-deletion-request/route.ts`
- i18n ar/en, sitemap, footer

### Docs
- `GOOGLE_PLAY_DATA_SAFETY_AUDIT.md`
- `PRIVACY_POLICY_GAPS.md`
- `GOOGLE_PLAY_RELEASE_CHECKLIST.md`
- `GOOGLE_PLAY_COMPLIANCE_REPORT.md` (this file)

---

## 3) SDK before / after

| App | compileSdk | targetSdk | versionCode | versionName |
|--|--|--|--|--|
| Customer before | 35 | 35 | 50 | 9.1.31 |
| Customer after | **36** | **36** | **51** | **9.1.32** |
| Driver before | 36 | 36 | 39 | 11.1.13 |
| Driver after | **36** | **36** | **40** | **11.1.14** |

Application IDs **unchanged**.

---

## 4) Account deletion implementation

**Primary:** Callable Gen1 `requestAccountDeletion` (auth UID only, `confirm: true`).  
**Safety net:** `onUserDeleted` runs idempotent cleanup if Auth disappears first.  
**Web:** `createAccountDeletionRequest` → `account_deletion_requests` + support ticket; **never** deletes Auth from public form.

### Strategy (approved financial freeze)
- **Delete/clear only non-financial account data:** profile PII on `user/{uid}`, saved addresses, FCM tokens, removable profile images / personal uploads, saved `PaymentMethods` (instruments), preferences-related profile fields
- **Never write** to `order`, `wallets`, `transactions`, `Paymenthistory`, `financial_*`, `financial_settlements`, invoices/payouts/settlements/audit-accounting records — amounts, prices, commissions, VAT, balances, statuses, operation IDs, and linked customer/driver identity on those records are preserved
- **Gates only (read):** active trip, open settlement (`draft`/`locked`), pending wallet tx, non-zero wallet balance (driver); active order (customer)
- **Chat / support / reviews:** display name may be cleared only; message/ticket bodies preserved for disputes/safety
- Driver KYC Storage retained pending legal decision (`PRIVACY_POLICY_GAPS`)

### Re-auth (client)
Password / Google / Apple via `reauthenticateWithCredential` (or popup on web). Phone: prompts re-login.

---

## 5) Build results

| Artifact | Path | Result |
|--|--|--|
| Customer AAB | `admin/ara_oatan_app/build/app/outputs/bundle/release/app-release.aab` | ✓ Built (~116MB) |
| Driver AAB | `admin/mndob-main/build/app/outputs/bundle/release/app-release.aab` | ✓ Built (~76MB) |
| Website | `npm run build` | ✓ `/ar/delete-account`, `/en/delete-account` |

### targetSdk verified (merged release manifests)
- Customer: `minSdk=24`, `targetSdk=36`, `versionCode=51`, package `com.mycompany.araoatanapp`
- Driver: `minSdk=24`, `targetSdk=36`, `versionCode=40`, package `com.mycompany.mndob2`

---

## 6) Test results

| Test | Result |
|--|--|
| Customer `flutter analyze` | **No issues found** |
| Driver `flutter analyze` | 2 **pre-existing errors** in `driver_cash_collection_panel.dart` (missing `driver_trip_completion.dart`) — unrelated to this work; AAB still produced |
| `node --test test/account_deletion.test.js` | **6/6 pass** |
| Website `tsc` / Next build | Pass |
| Full device E2E deletion | **Not run against production** (safety). Use emulator/test users after Functions deploy |

---

## 7) Data Safety answers (Email)

| App | Collected | Shared | Required | Purposes |
|--|--|--|--|--|
| Customer | Yes | **No** | Required | Account management; App functionality; Fraud prevention/security/compliance |
| Driver | Yes | **No** | Required | Same (+ Resend OTP as processor) |

Full tables: `GOOGLE_PLAY_DATA_SAFETY_AUDIT.md`.

---

## 8) Exact deletion URL

**Intended production URLs:**
- `https://touri-taxi.com/ar/delete-account`
- `https://touri-taxi.com/en/delete-account`

**Play Console status today:** **NOT READY FOR PLAY SUBMISSION** until:
1. Website is deployed to the live domain, and  
2. Firebase callables are deployed, and  
3. You open the URL in an incognito browser and confirm brand + deletion instructions render.

---

## 9) Remaining risks

1. Functions not yet deployed → in-app delete will fail until deploy  
2. Website not yet on production DNS  
3. Driver KYC retention legal decision pending  
4. Privacy policy HTML/i18n still needs counsel update to match approved financial freeze (delete-account page already updated)  
5. Driver analyze pre-existing missing file (cash collection panel)  
6. Wallet non-zero gate may require support-assisted settle before driver delete  
7. Google Maps API key still embedded in manifests (pre-existing security note)

---

## 10) Google Play Console actions

1. Deploy Functions + website  
2. Verify delete URL live  
3. Update Data safety per checklist  
4. Set Account deletion URL to live delete-account page  
5. Upload Customer AAB (51) and Driver AAB (40)  
6. Submit

Details: `GOOGLE_PLAY_RELEASE_CHECKLIST.md`.

---

## Acceptance criteria status

| Criterion | Status |
|--|--|
| Customer target/compile 36 | ✅ verified in manifest |
| Driver target 36 | ✅ verified |
| Customer delete flow (code) | ✅ |
| Driver delete flow (code) | ✅ |
| Server authz (UID from auth) | ✅ + unit tests |
| Driver financial/active gates | ✅ |
| Storage cleanup + KYC retain | ✅ |
| FCM cleanup | ✅ |
| Financial history intact (freeze — no writes) | ✅ |
| Trip/financial identity fields preserved | ✅ |
| Web AR/EN pages | ✅ in repo/build |
| Data Safety audit | ✅ |
| Email declaration resolved | ✅ recommendation |
| Privacy gaps documented | ✅ |
| Customer analyze clean | ✅ |
| AABs built | ✅ |
| Application ID unchanged | ✅ |
| Production data untouched | ✅ |
| Delete URL live for Play paste | ❌ **NOT READY** until deploy |
| Production E2E deletion | ⏳ after deploy on test accounts only |
