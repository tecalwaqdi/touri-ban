# Production source of truth — Touri Taxi

**Date:** 2026-07-19  
**Branch intent:** `fix/full-production-readiness` (repo currently has no commits on `main`; work proceeds in working tree)

## Customer app (PRODUCTION)

| Item | Value |
|------|-------|
| Path | `d:\Projects\ara\admin\ara_oatan_app` |
| Android applicationId | `com.mycompany.araoatanapp` |
| Android namespace | `com.mycompany.araoatanapp` |
| Firebase project | `tutorial-multi-language-70gx4j` |
| google-services.json | Present under `android/app/` |
| Entry | `lib/main.dart` |
| Cloud Functions source | `firebase/functions` (+ codebase `custom_cloud_functions`) |
| Region | `us-central1` |

## Driver / Courier

| Item | Value |
|------|-------|
| Path | `d:\Projects\ara\admin\mndob-main` |
| Note | Separate app; do not build customer APK from here |

## Admin panel

| Item | Value |
|------|-------|
| Path | `d:\Projects\ara\admin\Admi` |
| Seed scripts | `admin/Admi/firebase/scripts` |

## Duplicate / abandoned trees (DO NOT EDIT for customer release)

| Path | Reason |
|------|--------|
| `d:\Projects\ara\arawatan\` | Legacy / duplicate |
| `d:\Projects\ara\mndob-main\` (repo root) | Archive of driver app |
| Older `list_vi_copy*` screens inside customer | Legacy FF copies — prefer `list_vi` + `checkout66` |

## Payment / booking truth

| Concern | Truth |
|---------|-------|
| Cash booking CF | `createCashBooking` in `firebase/functions/ngenius_payments.js` |
| Card booking CF | `createNGeniusPayment` / `finalizeNGeniusBooking` |
| Client calls | `makeCloudCall(..., region: us-central1)` |
| Deployed status (2026-07-19) | Payment CFs **NOT** listed on project — only FCM/Braintree/chat helpers |
| Deploy blocker | Google Cloud **billing** required for Functions upload + Secret Manager |
| Firestore Rules | Deployable without Functions billing |
| Order create by client | Historically `allow create: if false` on `/order` |

## Interim cash path (until billing + CF deploy)

1. Prefer callable `createCashBooking`.
2. On `not-found` / missing function: create cash order via Firestore with strict Rules validation (`payment_status=cash_pending`, `PaymentMethod=Cash`, `USER=auth`).
3. N-Genius still requires CF deploy + secrets + billing — cannot be fully verified in production until then.

## Files actively modified for readiness

- `lib/core/toury_booking_service.dart` — cash CF + fallback
- `firebase/firestore.rules` — constrained cash create
- `firebase/functions/ngenius_payments.js` — payment CF exports (await deploy)
- `lib/app/list_vi/list_vi_widget.dart`, `placedetails_widget.dart`, `aldol_widget.dart`
- `lib/core/toury_pricing.dart`, `toury_landmark_filter.dart`, `toury_error_localizer.dart`
- `docs/release/manual_external_requirements.md`
