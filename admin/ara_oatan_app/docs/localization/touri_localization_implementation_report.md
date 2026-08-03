# Touri Localization Implementation Report

**Date:** 2026-07-18  
**App:** `admin/ara_oatan_app` (Touri Taxi customer)

## Architecture after the fix

1. **Official gen-l10n** — `lib/l10n/app_{en,ar,ru,ky}.arb` → `lib/gen_l10n/app_localizations.dart`
2. **EasyLocalization runtime** — `assets/langs/{en,ar,ru,ky}.json` (kept for FlutterFlow `.tr()` compatibility)
3. **Key map** — `lib/l10n/easy_key_map.json` bridges ARB identifiers ↔ EasyLocalization keys
4. **FFLocalizations** — hash-key map bridged to EasyLocalization; no silent EN leak into ar/ru/ky
5. **Production locales only** — ar, en, ru, ky (others archived under `assets/langs_archive/`)

## Files modified / added (high level)

### Added
- `l10n.yaml`
- `lib/l10n/app_*.arb`, `easy_key_map.json`
- `lib/gen_l10n/*` (generated)
- `lib/core/toury_booking_status_localizer.dart`
- `lib/core/toury_error_localizer.dart`
- `tool/check_*.dart`, `tool/localization_coverage_report.dart`, `tool/_bootstrap_l10n.py`
- `docs/audits/touri_localization_audit.md`
- `docs/localization/*`
- `test/localization/localization_core_test.dart`
- `assets/langs_archive/*` (fr, tr, ur, az, ka, id, zh-Hans)

### Updated
- `lib/core/toury_resolve_locale.dart` — production allowlist + legacy migration
- `lib/core/toury_notification_localizer.dart` — no EN leak
- `lib/core/toury_locale_loader.dart` — sync translate helper
- `lib/core/toury_payment_labels.dart` — never return raw codes
- `lib/core/app_design_system.dart` — Noto Sans font fallback
- `lib/flutter_flow/internationalization.dart` — teacher string fix, corrupted glyphs, getText bridge
- `lib/order/tfasel_order/tfasel_order_widget.dart` — BookingStatusLocalizer
- `lib/main.dart` — AppLocalizations.delegate + Noto Sans preload
- `assets/langs/{en,ar,ru,ky}.json` — glossary keys + status labels + brand fixes

## Hardcoded strings

- Scanner found ~490 `Text('...')` candidates (many demo/orphan screens).
- Critical order-status display path fixed.
- Strict CI mode available: `dart run tool/check_hardcoded_strings.dart --strict` (currently non-strict until remaining screens migrated).

## Dynamic / Firebase / notifications / maps

| Area | Change |
|------|--------|
| Booking status | Central `BookingStatusLocalizer` maps `halh_text` + `status_code` |
| Payment labels | Unknown values → localized choose-method text |
| Errors | `ErrorLocalizer` for Firebase/platform/network |
| FCM | Preferred locale clamped to ar/en/ru/ky; missing keys → localized generic |
| Maps | Existing language params retained; place names not machine-translated |
| Legacy locale `fr` | Migrated to `en` at startup |

## Language-specific fixes

### Arabic
- Status terminology unified (بانتظار قبول السائق, تم الإلغاء, …)
- RTL retained via Directionality for `ar`

### English
- Removed "Looking for a teacher"
- Brand Ara Watan → Touri Taxi in permission copy
- Glossary terms normalized (Current location, View route, …)

### Russian
- Status/payment glossary filled with natural taxi phrasing
- ICU plurals for hours/minutes in ARB (`one/few/many/other`)

### Kyrgyz
- Special characters present in `kyrgyz_char_sample` and corpus: ң ө ү Ң Ө Ү
- Status strings written in Kyrgyz (not Russian copies for glossary keys)
- Font fallback Noto Sans for Cyrillic + Kyrgyz letters

## Remaining work

1. Migrate remaining hardcoded Arabic UI in map/places/support widgets to `.tr()` / AppLocalizations
2. Driver app (`admin/mndob-main`) should write `status_code` consistently; keep `halh_text` for legacy
3. Cloud Functions should return `code` not English `message` (partial client mapping ready)
4. Enable `--strict` hardcoded check in CI after screen sweep
5. Manual native-speaker review for Kyrgyz long-form marketing copy

## Migrations

- Archived non-production JSON locales out of `assets/langs/`
- Stored locale `fr` (and other non-prod) → `en` via `touryMigrateLegacyLocale`
