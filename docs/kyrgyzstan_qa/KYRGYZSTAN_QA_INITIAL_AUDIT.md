# Kyrgyzstan QA — Initial Audit

**Date:** 2026-08-06  
**Apps:** `admin/ara_oatan_app` (customer), `admin/mndob-main` (driver), `admin/Admi` (admin)  
**Firebase SoT:** `admin/ara_oatan_app/firebase`  
**Status:** Analysis complete — fixes follow in same branch work

---

## Issue A — Cancel Order permission denied (confirmed in screenshots)

| Field | Detail |
|-------|--------|
| **Symptom** | Snackbar: `فشل الإلغاء :The caller does not have permission…` while UI language is Russian |
| **App** | Customer — `tfasel_order_widget.dart` |
| **Root cause** | `TouryCustomerOrderActions.writeCancelled` does **two** writes. First `update()` sets only `halh_*` / `NotSestem` **without** `status_code == cancelled`. Firestore `consumerCanCancelOrder()` requires `request.resource.data.status_code == 'cancelled'` on that update → **permission-denied**. |
| **Layer** | Flutter client write shape vs **Firestore Rules** (rules themselves allow cancel when done correctly) |
| **Files** | `lib/core/toury_customer_order_actions.dart`, `firebase/firestore.rules` (`consumerCanCancelOrder`) |
| **Fix plan** | Single atomic write setting `status_code`, legacy `halh_*`, `ALLNOW=false`, cancel metadata. Map errors to translation keys. Localize button + snackbars. |

---

## Issue B — Cash create permission (reported; order `#CASH-1463077497` exists)

| Field | Detail |
|-------|--------|
| **Symptom** | Same Firebase permission text during create (intermittent / env-dependent) |
| **App** | Customer checkout66 → `toury_booking_service.dart` |
| **Path** | Cash-only default skips CF → client Firestore fallback |
| **Likely causes** | (1) Rules deploy lag vs client fields; (2) missing required keys for `isValidClientCashOrderCreate`; (3) CF path when online enabled without Blaze → not-found then fallback fails; (4) auth/session edge cases |
| **Layer** | Flutter + Firestore Rules (+ CF when deployed) |
| **Note** | Screenshot proves create **succeeded** for this order; cancel is the hard failure shown. Still harden create: country `currency`/`currencyCode`, clearer error codes. |
| **Fix plan** | Persist country currency on create; map `permission-denied` → `booking_permission_denied`; keep fallback fields aligned with rules. |

---

## Issue C — Mixed language (RU UI + EN Cancel + AR error)

| Field | Detail |
|-------|--------|
| **Symptom** | `Cancel Order` English; error Arabic+English; WhatsApp brand OK |
| **App** | Customer order details |
| **Root cause** | Button uses `FFLocalizations.getText('hjqgpu0l')` with **`ru`/`ky` values still English**. Errors hardcoded Arabic + raw `FirebaseException.message`. SnackBarAction `تواصل معنا` hardcoded Arabic. |
| **Layer** | Flutter localization |
| **Fix plan** | Fix FF map + prefer `.tr()`; error codes → `assets/langs/{ar,en,ru,ky}.json`. |

---

## Issue D — Currency shows ر.س for Kyrgyzstan order

| Field | Detail |
|-------|--------|
| **Symptom** | `16 800 ر.س` on order details for Парк Панфилова |
| **App** | Customer `tfasel_order_widget.dart` ~362 hardcodes `currency: 'ر.س'` |
| **Also** | Cash create writes `'currency': 'SAR'` always |
| **Layer** | Flutter display + create payload (not locale) |
| **Fix plan** | Store `currency` / `currency_code` from country on create; display via order field or `Rev_dolh` / `FFAppState.RMZCurrency`. Admin currency catalog + migration plan (no prod run). |

---

## Issue E — Driver auth / registration (KG +996)

| Field | Detail |
|-------|--------|
| **Symptom** | Cannot register/login reliably (reported) |
| **App** | `mndob-main` — `DriverAuthGate`, `DriverBootstrapService`, `Login1`, `Regdrever` |
| **Known blockers** | MASTER_BLOCKERS: CF deploy, rules deploy, device QA |
| **Layer** | Auth + Firestore driver docs + possible phone formatting |
| **Fix plan** | Audit +996 / error mapping; fix clear code defects without claiming App Store or live auth fixed without device. |

---

## Issue F — Driver app not in App Store search

| Field | Detail |
|-------|--------|
| **Layer** | **App Store Connect / ASO** — not Flutter-only |
| **Deliverable** | `DRIVER_IOS_APP_STORE_AUDIT.md` from project Bundle IDs + Connect checklist |

---

## Priority order

1. Cancel write + error i18n (unblocks shown screenshot)  
2. Currency display + create currency field  
3. Cancel button FF/ru/ky  
4. Create error mapping  
5. Currency migration plan (dry-run script, not executed on prod)  
6. Driver auth mapping / phone  
7. App Store audit report  
8. Tests + final report  

**No Firebase deploy. No App Store publish. No production data mutation.**
