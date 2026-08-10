# FULL_LOCALIZATION_AUDIT — Touri Taxi

Date: 2026-08-08  
Scope: `admin/ara_oatan_app` (Customer) + `admin/mndob-main` (Driver)  
Official locales: `ar`, `en`, `ru`, `ky`

## Verdict summary

| App | ar | en | ru | ky |
|-----|----|----|----|----|
| Customer | FAIL* | FAIL* | FAIL* | FAIL* |
| Driver | FAIL* | FAIL* | FAIL* | FAIL* |

\* **Automated localization layer: PASS** (key parity, fallback rules, error mapping, unit/localization tests).  
\* **Full product PASS blocked** until Device QA completes a full trip / registration sweep on-device for each locale (language switch + no mixed UI). Remaining risk: FlutterFlow hash leftovers and some legacy/copy screens.

---

## ara_oatan_app (Customer)

### Metrics
| Metric | Value |
|--------|------:|
| Dart files under `lib/` | **406** |
| Production JSON keys | **890** × 4 (`en/ar/ru/ky`) |
| ARB keys (secondary) | 784 × 4 |
| Hardcoded `Text('…')` candidates (`--strict`) | **11** (mostly interpolations / copy routes) |
| Localization unit tests | **17** passed (`test/localization/`) |

### What was fixed
- Removed **ky → ru** content fallback in [`lib/core/toury_i18n_text.dart`](admin/ara_oatan_app/lib/core/toury_i18n_text.dart); chain is now `locale → en → first non-Arabic`.
- Expanded [`lib/core/toury_error_localizer.dart`](admin/ara_oatan_app/lib/core/toury_error_localizer.dart) for common Firebase Auth / Firestore codes (no raw Firebase messages to UI).
- Replaced hardcoded English UI strings in checkout / payment / stub page with `.tr()` keys.
- Added keys to all four JSON files (parity preserved).
- Updated localization tests for the new ky→en content chain.

### New / repaired keys (examples)
- `planning_for_a_longer_trip_Add_more_hours_and_enjoy_the_ride`
- `please_do_not_close_the_page_until_the_payment_is_completed`
- `page_Title`
- `error_email_already_in_use`, `error_weak_password`, `error_user_disabled`, `error_operation_not_allowed`, `error_too_many_requests`, `error_invalid_verification_code`, `error_session_expired`, `error_cancelled`, `error_resource_exhausted`

### RTL / locale persistence
- RTL forced for `ar` only in `main.dart` (`en/ru/ky` = LTR).
- Locale stored in SharedPreferences `__locale_key__` via `FFLocalizations` (`EasyLocalization.saveLocale: false`).
- Startup: stored locale → device locale → `en`.
- Logged-in users also write `user.preferred_locale`.

### Firestore localization
- Content uses `names_i18n` / `osf_i18n` via Toury helpers.
- Non-ar UI suppresses Arabic leakage when alternatives exist.
- Admin records missing `en/ru/ky` still need CMS fill (fallback to `en` then first non-empty).

### Error messages
- Mapped through `ErrorLocalizer` / Google auth helpers → `.tr()` keys.
- Remaining unmapped codes fall back to generic localized error (not raw Firebase text).

### Tooling results
| Check | Result |
|-------|--------|
| `tool/check_localizations.dart` | OK |
| `tool/check_mixed_languages.dart` | OK |
| `tool/check_translation_consistency.dart` | OK |
| `tool/check_hardcoded_strings.dart --strict` | 11 soft candidates (interpolations / legacy copies) |
| `flutter analyze` (touched files) | No issues |
| `flutter test test/localization/` | All passed |

### Device QA still needed
- Full customer path × 4 locales (login → geo → car → checkout → trip → wallet → settings language switch).
- Visual confirmation that copy/legacy routes are not reachable with mixed language.

---

## mndob-main (Driver)

### Metrics
| Metric | Value |
|--------|------:|
| Dart files under `lib/` | **235** |
| Production JSON keys (before) | en 212 / ar 262 / ru 217 / ky 217 |
| Production JSON keys (after) | **343** × 4 (parity OK) |
| New tool | [`tool/check_lang_parity.dart`](admin/mndob-main/tool/check_lang_parity.dart) |
| New tests | [`test/localization/driver_localization_test.dart`](admin/mndob-main/test/localization/driver_localization_test.dart) — **8** passed |

### What was fixed
- Synced **50** ar-only keys + **5** ru/ky-only keys into all four JSON packs.
- Added status / payment / trip / map / dialog keys (EN phrase keys).
- [`DriverPaymentLabels`](admin/mndob-main/lib/core/driver_payment_labels.dart): returns English keys + `driverTr` for UI; cash detection no longer depends on Arabic display.
- [`DriverOrderMeta`](admin/mndob-main/lib/core/driver_order_meta.dart): trip/luggage → English keys.
- [`TourySystemStatusCodes.displayHalhKeyForCode`](admin/mndob-main/lib/core/toury_system_status_codes.dart): UI keys; Arabic `displayHalhForCode` kept for Firestore dual-write only.
- [`TypeCarRecord.localizedName`](admin/mndob-main/lib/backend/schema/type_car_record.dart): removed forced `ar` / `ky→ru` fallback for non-ar.
- Active UI localized: trip banner, ride request sheet, trip plan/map, tfasel dialogs, home payout dialog, profile wallet/delete, Now/Accepted/Completed/Cancel lists (currency from country registry).
- Driver `setAppLanguage` now persists `preferred_locale` on the user doc.
- Cloud Function `notifyAdminsOnNewBooking` sends per-`preferred_locale` copy (`ar/en/ru/ky`) + `data.code=NEW_BOOKING`.

### Arabic files that previously leaked UI (fixed)
- `lib/core/driver_payment_labels.dart`
- `lib/core/driver_order_meta.dart`
- `lib/components/driver_trip_details_banner.dart`
- `lib/components/driver_ride_request_sheet.dart`
- `lib/components/driver_trip_plan_panel.dart`
- `lib/components/driver_trip_map_panel.dart`
- `lib/core/driver_map_actions.dart`
- `lib/core/driver_navigation_service.dart`
- `lib/tfasel_orser/tfasel_orser_widget.dart` (dialogs / currency / notifications)
- `lib/home/home_widget.dart`, `lib/profile07/profile07_widget.dart`
- `lib/now/now_widget.dart`, `lib/accepted/accepted_widget.dart`, `lib/completed/completed_widget.dart`, `lib/cansel/cansel_widget.dart`

### Remaining risks
- FlutterFlow `kTranslationsMap` still en+ar only; ru/ky rely on EasyLocalization bridge via English phrase — works when phrase exists in JSON.
- Some Login / registration screens may still call `FFLocalizations.getText(hash)` — bridge covers ru/ky when EN phrase is present.
- Firestore `halh_text` Arabic constants remain for DB compatibility (not shown as UI when using `displayHalhKeyForCode` + `driverTr`).

### Tooling results
| Check | Result |
|-------|--------|
| `dart run tool/check_lang_parity.dart` | OK (343 keys × 4) |
| `flutter test test/localization/driver_localization_test.dart` | All passed |
| `flutter analyze` (core + active screens) | Warnings/info only (pre-existing style); no new errors in payment/order/status cores |

### Device QA still needed
- Language switch ar↔en↔ru↔ky on Login / Home / Now / Active trip / Wallet / Profile.
- Confirm Online/Offline toasts and accept/reject dialogs in each locale.

---

## Cross-cutting

### RTL / LTR
| Locale | Direction |
|--------|-----------|
| ar | RTL |
| en | LTR |
| ru | LTR |
| ky | LTR |

### Locale persistence
Both apps: SharedPreferences `__locale_key__` + optional Firestore `preferred_locale`. Survives restart when stored.

### Notifications / Cloud Functions
- Customer: `TouryNotificationLocalizer` uses preferred/stored locale.
- Admin booking push: localized by admin `preferred_locale` in [`admin/Admi/firebase/functions/index.js`](admin/Admi/firebase/functions/index.js).

### Firestore content debt (admin CMS)
Records that only have Arabic `naim` / missing `names_i18n.{en,ru,ky}` will show English fallback or blank rather than leaking Arabic into non-ar UI. Fill translations in Admin for full native coverage.

---

## Commands to re-verify

```bash
# Customer
cd admin/ara_oatan_app
dart run tool/check_localizations.dart
dart run tool/check_mixed_languages.dart
dart run tool/check_hardcoded_strings.dart --strict
flutter test test/localization/

# Driver
cd admin/mndob-main
dart run tool/check_lang_parity.dart
flutter test test/localization/driver_localization_test.dart
```

---

## Final table (product acceptance)

| App | ar | en | ru | ky |
|-----|----|----|----|----|
| Customer | FAIL* | FAIL* | FAIL* | FAIL* |
| Driver | FAIL* | FAIL* | FAIL* | FAIL* |

\* Flip to **PASS** after Device QA confirms zero mixed-language UI on the critical paths for each locale. Automated infrastructure for all four locales is in place and tested.
