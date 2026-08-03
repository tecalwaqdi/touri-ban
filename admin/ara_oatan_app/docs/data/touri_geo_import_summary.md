# Touri Geo Import Summary — Gate Review

## What was delivered (this stop point)

1. Schema audit of current `countries` → `cities`(regions) → `villages`(cities) → `mkan`  
2. Documentation under `docs/data/`  
3. Import toolkit at `ara_oatan_app/firebase/tools/geo_import/`  
4. Makkah Region pilot with **20 real landmarks**  
5. Validation + **dry-run only** (Firestore not written)  
6. Unit tests passing (6/6)

## Country table (pilot only)

| Country | Official regions (target) | Regions imported (pilot) | Cities (pilot) | Landmarks | Regions with ≥20 LM | Licensed images | Needs review LM |
|---|---|---|---|---|---|---|---|
| Saudi Arabia | 13 | 1 (Makkah) | 3 (Makkah, Jeddah, Taif) | 20 | 1 | 10 | 8 |
| Kyrgyzstan | — | 0 | 0 | 0 | — | — | — |
| Uzbekistan | — | 0 | 0 | 0 | — | — | — |
| Russia | — | 0 | 0 | 0 | — | — | — |

## Publishable candidates (Wikidata-backed, higher confidence)

Examples: Masjid al-Haram, Kaaba, Abraj Al Bait, Mount Arafat, Jabal al-Nour, Jabal Thawr, Muzdalifah, Masjid Namirah, Jannat al-Mu'alla, King Fahd Fountain, Al-Shallal, Shubra Palace.

## Blocked / waiting for your approval

- Any Firestore write (staging or production)  
- Firebase Storage image upload pipeline  
- Expansion to other SA regions / KG / UZ / RU  
- Google Places enrichment (needs secret key, not in Git)  
- Removal/rotation of legacy embedded Maps key in old Admin seed script

## How to review

```bash
cd ara_oatan_app/firebase/tools/geo_import
npm test
npm run geo:dry-run
```

Open:

- `reports/dry_run_sa_makkah.json`
- `reports/firestore_preview_sa_makkah.json`
- `docs/data/touri_geo_validation_report.md`

**Stopped here for review as requested.**
