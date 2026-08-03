# Landmarks readiness report

**Date:** 2026-07-19  
**Firebase project:** `tutorial-multi-language-70gx4j`  
**Collection:** `mkan`

## Verdict

**Landmarks are READY for Internal QA** (not inventing filler to hit 20/city where OSM already supplies ~20).

## Published this session

| Action | Result |
|--------|--------|
| Soft-disable aircraft/junk OSM nodes | **6 disabled** (`acctev=false`) — Boeing 707, F-15, Tornado, DC-4, C-130, L-1011 |
| Curated landmarks with ar/en/ru/ky | **16 upserted** (Makkah 5, Jeddah 3, Riyadh 4, Bishkek 4) |
| Firestore rules fix (mkan update) | **Deployed** — admin updates were blocked by recursive `isSuperAdmin()` |
| Client ban list | Extended (Lockheed / Hercules / Tristar / DC-4) |
| i18n sanitize (Arabic leakage in ky/ru/en) | Running / applied on docs needing fix |

## City coverage (pre-existing OSM + curated)

Major Saudi `villages/*` already had **~20 active landmarks** each (including `city_makkah`).  
Curated docs add verified multilingual names for hero places (Haram, Clock Tower, Black Stone, etc.).

## How to re-run

```bash
cd admin/Admi/firebase/scripts
node publish_landmarks_ready.js --dry-run
node publish_landmarks_ready.js --apply
```

Data file: `curated_landmarks_ready.json`

## Remaining gaps (honest)

- Full Kyrgyz/Russian **human** translations for every OSM import (~500+) — sanitize uses English when available; Arabic-only OSM names may still lack a Latin label.
- Russia (Moscow) curated pack not seeded in this pass.
- Image quality still depends on Unsplash / Static Maps / Storage URLs.
- Admin Console can still edit/disable any `mkan` under `/adminM3alm`.
