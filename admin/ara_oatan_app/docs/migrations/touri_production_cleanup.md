# Touri Taxi — Production Cleanup (Landmarks / Leakage)

## Client-side (already shipped in this branch)

- `touryFilterLandmarksForUi` hides aircraft / military / junk names.
- `touryLocalizedText` no longer falls back to Arabic for `ky`/`ru`/`en`.
- GPS/manual location stores **localized** country/city labels via `names_i18n`.
- Language change calls `TouryLocationService.refreshStoredGeoLabels()`.

## Firestore dry-run

```bash
cd admin/ara_oatan_app
python tool/migrations/cleanup_touri_production_data.py --dry-run
```

## Admin / Functions (manual)

1. In Admin landmarks list, search: `Boeing`, `Tornado`, `F-15`, `aircraft`.
2. Soft-delete (`isActive=false`) or hard-delete after backup.
3. Ensure each `mkan` has `names_i18n.{ar,en,ru,ky}` and `cityId`/`villages` ref.
4. Do **not** invent landmarks to fill quotas.

## Seed policy

Only enable cities with verified landmarks. Missing ky translations: fall back to **English**, never Arabic chrome for Kyrgyz UI.

## Published 2026-07-19

- Soft-disabled 6 aircraft/military OSM landmarks in production Firestore.
- Upserted 16 curated multilingual landmarks (Makkah / Jeddah / Riyadh / Bishkek).
- Sanitized `names_i18n` on 247 docs (removed Arabic copies from ky/ru/en when Latin exists).
- Deployed Firestore rules fix so admin can update `mkan`.
- Script: `admin/Admi/firebase/scripts/publish_landmarks_ready.js`
- Report: `docs/audits/touri_taxi_landmarks_report.md`
