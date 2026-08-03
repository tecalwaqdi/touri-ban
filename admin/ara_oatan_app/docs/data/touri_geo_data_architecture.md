# Touri Geo Data Architecture

**Status:** Phase 1–4 pilot scaffolding (dry-run only)  
**Date:** 2026-07-22  
**Canonical Firebase root:** `ara_oatan_app/firebase`  
**Production writes:** **blocked** until explicit approval

## Current production hierarchy (as implemented)

| Ideal concept | Firestore collection | Link fields |
|---|---|---|
| Country | `countries` | `iso_code`, `names_i18n`, `CurrencySymbol`, bounds |
| Administrative region | **`cities`** | `dolh` → country |
| City / district | **`villages`** | `cities` → region, `dolh` → country, `lat_ling` |
| Landmark | `mkan` | `id_cit`, `id_vill`, `Rev_dolh`, `Location`, `names_i18n`, `osf_i18n` |
| Vehicle category | `type_car` | `names_i18n`, `codeCar`, `sr` |

### Naming conflict (documented, non-destructive)

The app historically stores **regions in `cities`** and **cities in `villages`**.  
The geo import toolkit maps ideal Country→Region→City→Landmark onto this schema without renaming collections in production.

## Migration policy

1. Additive fields only (`geo_import_id`, `wikidata_id`, `source_*`, `verification_*`).
2. No deletes.
3. Landmarks with `needs_review` import as `acctev: false` if ever written.
4. Idempotent doc IDs from stable `geo_import_id` / Wikidata / OSM.
5. Dry-run default; production never default.

## Tooling location

`ara_oatan_app/firebase/tools/geo_import/`

## Pilot scope

Saudi Arabia → **Makkah Region (SA-02 / منطقة مكة المكرمة)** only.

## Security notes

- Do not reuse API keys found in legacy scripts (e.g. embedded Maps key in `Admi/firebase/scripts/seed_saudi_osm_landmarks.js`).
- Service accounts stay outside Git.
- Client apps must not embed secret API keys.
