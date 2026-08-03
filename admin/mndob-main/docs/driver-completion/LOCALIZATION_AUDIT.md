# LOCALIZATION AUDIT — Workstream B (phase 1)

**Date:** 2026-07-28  
**App:** `mndob-main`  
**Reference:** `ara_oatan_app` EasyLocalization architecture

## Architecture (aligned)

| Piece | Customer | Driver (after B1) |
|-------|----------|-------------------|
| Package | easy_localization | easy_localization |
| Loader | TouryCachedAssetLoader | DriverCachedAssetLoader (same pattern) |
| Resolve | toury_resolve_locale | driver_resolve_locale |
| Fallback | en | en |
| Assets | assets/langs/{en,ar,ru,ky}.json | same |
| UI API | `.tr()` | `driverTr` → `.tr()` wrapper |
| RTL | Directionality for ar | Directionality for ar |
| Material locale | `_locale ?? context.locale` | same |

## Files touched (B1)

- `lib/core/driver_i18n.dart` — route through EasyLocalization `.tr()` / namedArgs
- `lib/main.dart` — apply `_locale`, RTL Directionality builder

## Screens already using driverTr / t()

- `regdrever_widget.dart` (local `t` → driverTr)
- `login1_widget.dart` (partial; still has FF getText hashes)
- `driver_pending_approval_widget.dart`
- `driver_auth_gate.dart` / onboarding / home status chips

## Remaining for B2+

- Replace remaining `FFLocalizations.getText(hash)` on Login with phrase keys
- Fill missing phrase keys across 4 JSON files for all production screens
- Discover locales from AssetManifest (optional parity)
- Full screen-by-screen hardcoded sweep (orders/trip/wallet) after Workstream C

## Hardcoded Arabic in auth/reg/pending Dart

**0** Arabic script literals in those widgets (English phrase keys + JSON).

## Device QA

Language switch + RTL on device: **TBD**
