# Touri Taxi Localization Audit (Initial)

**Date:** 2026-07-18
**Production customer app:** `admin/ara_oatan_app` (Touri Taxi)
**Production driver app:** `admin/mndob-main`
**Stale duplicates ignored:** `ara/mndob-main`, `arawatan/` (redirect only)

## Localization architecture (before fix)

- Dual stack: **EasyLocalization** (`assets/langs/*.json`) + FlutterFlow **FFLocalizations**
- No `l10n.yaml` / ARB / `flutter gen-l10n` initially
- Locale discovery from JSON assets (11 languages including fr, tr, ur, az, ka, id, zh-Hans)
- Persistence: SharedPreferences `__locale_key__` + Firestore `preferred_locale`
- Fallback: English (silent for missing FF / notifications)

## Required languages

| Code | Name |
|------|------|
| ar | العربية |
| en | English |
| ru | Русский |
| ky | Кыргызча |

## Languages found before fix

en, ar, ru, ky, fr, tr, ur, az, ka, id, zh-Hans

**Archived out of runtime assets:** (none)

## Completeness (after JSON key parity pass)

| Language | Keys | Empty | Identical to EN (nontrivial) | Est. coverage |
|----------|------|-------|------------------------------|---------------|
| English | 784 | 0 | 0 | 100.0% |
| Arabic | 784 | 0 | 10 | 98.7% |
| Russian | 784 | 0 | 23 | 97.1% |
| Kyrgyz | 784 | 0 | 25 | 96.8% |

## Critical issues discovered

### Severity: Critical
1. Order details show raw Arabic `halhText` from Firestore.
2. Status strings stored as Arabic human text instead of codes.
3. FF entry `6bdi3tuo` = "Looking for a teacher".
4. Corrupted FF glyphs in some map category strings.
5. `checkout_order_status_pending` was English in ar/ru/ky.
6. Notification localizer silently falls back to English.
7. FF `getText` / `getVariableText` silently fall back to English.
8. Extra languages (fr, …) exposed in picker.
9. Cairo-only fonts risk missing Kyrgyz/Cyrillic glyphs.
10. Legacy "Ara Watan" brand strings.

### Severity: High
- Hardcoded Arabic UI in map/places/schedule/support.
- Dual translation systems diverge.
- Phrase keys require ARB sanitization map.
- Driver app writes Arabic `halh_text` constants.

## Hardcoded Text(...) candidates: **490**

- `lib/aaaaa/aaaaa_widget.dart`: `Page Title`
- `lib/chat2/chat2_widget.dart`: `yvnt7xqi`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `annspca1`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `mcloprue`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `nqmjfztr`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `uf8tvdq8`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `2gie7hge`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `jnlfevn6`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `35vq7cxk`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `3vd0zode`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `hps58ox2`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `cmuygo0x`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `00swgjcm`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `fwustt3y`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `fj1afbbi`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `0ttnj4jl`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `64mbfw71`
- `lib/checkout66_copy/checkout66_copy_widget.dart`: `em74sqch`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `k7bwtga6`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `e2p9bqag`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `4t5pmmpz`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `grnb4jcy`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `1jnhdrno`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `qdh43sza`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `ptn5zdw3`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `ufw7fgrl`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `cvo7w5qx`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `n4minjo8`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `3f6pytzl`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `veo115ap`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `wka7ux46`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `be0v7eti`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `1mfsgnmt`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `tl7tpkur`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `${FFAppState().saatcar.toString()}${`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `prxk3k9a`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `cvynf9d6`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `iyjh4m9g`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `r4njg998`
- `lib/checkout66_copy2/checkout66_copy2_widget.dart`: `2pqf8rlw`

## Kyrgyz character presence

```json
{
  "ң": true,
  "ө": true,
  "ү": true,
  "Ң": true,
  "Ө": true,
  "Ү": true
}
```

## Next steps

1. `l10n.yaml` + gen-l10n
2. Restrict locales to ar/en/ru/ky
3. Status/payment/error localizers
4. Replace raw `halhText` UI
5. Fonts + tools + tests + reports
