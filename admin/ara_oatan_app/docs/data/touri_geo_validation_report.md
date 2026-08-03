# Touri Geo Validation Report — Pilot SA Makkah

**Generated:** 2026-07-22  
**Mode:** dry-run (no Firestore writes)  
**Dataset:** `firebase/tools/geo_import/datasets/pilots/sa_makkah_region.js`

## Summary

| Metric | Value |
|---|---|
| Landmarks total | 20 |
| Validation hard errors | 0 |
| OK structurally | 20 |
| Publishable candidates (confidence ≥ 0.8, not needs_review) | 12 |
| Needs review | 8 |
| Licensed Commons images attached | 10 |
| Near-duplicate coordinate pairs | 1 (Haram ↔ Kaaba — expected adjacent sites) |

## Near-duplicate handling

`lm_sa_makkah_masjid_al_haram` and `lm_sa_makkah_kaaba` share nearly identical coordinates because the Kaaba is inside the Haram courtyard.  
**Do not auto-merge.** Keep both as related places.

## Needs review (examples)

- Mina, Historic Jeddah (Al-Balad), Floating Mosque, Masjid Aisha, Al-Hada, Obhur, Kiswa exhibition — missing Wikidata/OSM IDs or approximate coords.
- Jeddah Corniche — Commons image OK; coordinates are representative centroid.
- Abraj Al Bait / Mount Arafat — coords verified; image license deferred.

## Machine-readable artifacts

- `firebase/tools/geo_import/reports/validation_sa_makkah.json`
- `firebase/tools/geo_import/reports/dry_run_sa_makkah.json`
- `firebase/tools/geo_import/reports/firestore_preview_sa_makkah.json`

## Acceptance for pilot gate

- [x] No invented places in Wikidata-backed set  
- [x] ≥20 landmarks for Makkah Region  
- [x] Dry-run does not write Production  
- [x] Sources recorded  
- [ ] Full dual-source for every record (8 still pending IDs)  
- [ ] Storage upload of licensed images (not started)  
- [ ] Human review of ky/uz translations  
