# Step 1 — Staging Import Result

**Date:** 2026-07-22  
**Production writes:** blocked

## What ran

| Target | Status | Docs |
|---|---|---|
| Local staging (`staging/firestore/`) | **OK** | **886** |
| Firestore Emulator (`127.0.0.1:8080`) | Blocked — Java runtime not available on PATH | — |

## Staging contents

| Collection | Count |
|---|---|
| countries | 4 |
| cities (regions) | 39 |
| villages (city hubs) | 39 |
| mkan (landmarks) | 780 |
| type_car (vehicles) | 24 |
| **Total** | **886** |

Verified: `present=886 missing=0`

## Commands

```bash
# Local staging (works without Java)
npm run geo:import:staging
npm run geo:staging:verify

# Emulator (requires JDK on PATH)
# set JAVA_HOME then:
firebase emulators:start --only firestore --project touri-geo-emulator
# in another shell:
set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
npm run geo:import:emulator
```

## Safety

- `--target=production` is refused
- Emulator import requires `FIRESTORE_EMULATOR_HOST`
- Staging files are local only under `firebase/tools/geo_import/staging/`
