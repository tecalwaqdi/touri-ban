# Phase 4 — Driver Document Contract

## Document types

| TYPE | CANONICAL FIELD | LEGACY / ALT | FRONT/BACK | URL / PATH | EXPIRY | REQUIRED (V2) | UI OWNER |
|------|-----------------|--------------|------------|------------|--------|---------------|----------|
| Profile photo | `photo_storage_path` | `photo_url`, `doc_profile_photo` | — | path or https | — | photo for complete | Documents panel |
| National ID | `doc_national_id` | `img_id_rksh` | — | map storagePath/url | map expiry | yes | Documents panel |
| Vehicle registration | `doc_vehicle_registration` | `img_id_car` (photo fallback) | — | map | map expiry | yes | Documents panel |
| License front | `doc_driver_license_front` | — | front | map | map expiry | yes (V2) | Documents panel |
| License back | `doc_driver_license_back` | — | back | map | map expiry | yes when required | Documents panel |
| License legacy | `doc_driver_license` | single image | legacy | map/url | map expiry | approved legacy only | Documents panel **only if no front/back** |
| Tour guide permit | `tour_guide_permit_url` | — | — | url | — | if tour guide | conditional |

## License compatibility rule

```
if hasFront OR hasBack:
  show front slot + back slot
  DO NOT show legacy slot (even if legacy URL exists)
else:
  show legacy slot (present/legacy/missing)
```

Implemented in `AdminDriverProfileView.documents` via `DriverLicenseDocument.hasFront/hasBack`.

## Completeness

Uses `AdminDriverProfileView.authoritativeDocumentsStatus` / `documentsComplete` — **not** recomputed ad hoc in Widget build beyond calling those helpers.

UI shows **localized** chip only (مكتملة / ناقصة / …). Raw enum strings are not displayed.

## Expiry presentation

- Parsed via `parseDocExpiry` (DateTime / ISO / seconds map)
- Parse failure → no expiry line (never fake “expired”)
- Labels: منتهية / تنتهي قريبًا / تنتهي

## Image failure

`_DocRow` / media resolver: missing → warning icon; broken URL → stable fallback (no crash). Preview launch guarded by presence + scope.
