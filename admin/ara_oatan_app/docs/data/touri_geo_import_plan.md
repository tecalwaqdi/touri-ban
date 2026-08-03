# Touri Geo Import Plan

## Commands

```bash
cd ara_oatan_app/firebase/tools/geo_import
npm test
npm run geo:audit
npm run geo:validate -- --country=SA --region=makkah
npm run geo:dry-run -- --country=SA --region=makkah
npm run geo:report -- --country=SA --region=makkah
```

`npm run geo:import` **refuses** production and exits non-zero until approval workflow is added.

## Phases

| Phase | Status |
|---|---|
| 1 Schema audit | Done (this folder + docs) |
| 2 Validators | Done (pilot) |
| 3 Collectors (live APIs) | Partial (Wikidata/Commons read-only) |
| 4 Makkah pilot dry-run | Done — awaiting review |
| 5 Full SA | Not started |
| 6–7 Translate/images Storage | Not started |
| 8 Vehicles | Not started |
| 9 Emulator E2E | Blocked — emulator not configured in firebase.json |
| 10 Production | **Stopped — needs approval** |

## Idempotency & resume

- Stable IDs: `lm_sa_*`, `region_sa_makkah`, `city_sa_*`
- Checkpoints: `checkpoints/`
- Reports: `reports/`
- Rollback: not applicable until first real write generates a manifest
