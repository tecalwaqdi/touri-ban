# Expansion Progress — Multi-country + Vehicles + Staging

**Updated:** 2026-07-22  
**Firestore writes:** still blocked (local staging only)

## Coverage (20 landmarks × region)

| Country | Regions | Landmarks | Status |
|---|---|---|---|
| Saudi Arabia (SA) | 13 | 260 | Ready |
| Kyrgyzstan (KG) | 9 | 180 | Ready |
| Uzbekistan (UZ) | 14 | 280 | Ready |
| Russia (RU) wave-1 | 20 | 400 | Ready |
| **Total** | **56** | **1120** | |

## Step status

| Step | Status | Notes |
|---|---|---|
| 1. Staging import | **Done** | Local staging under `staging/firestore/`. Emulator needs working Java on PATH. |
| 2. Expand Russia | **Done** | 20 federal subjects × 20 = 400 landmarks |
| 3. Wikimedia images | **Pipeline ready** | `npm run geo:images` — SA/KG samples linked; rate-limit retries added; truncation bug fixed |
| 4. Admin vehicle Seed | **Done** | Confirm dialog + 27 categories (ar/en/ru/ky/uz) |

## Commands

```bash
cd ara_oatan_app/firebase/tools/geo_import
npm run geo:coverage
npm run geo:import:staging
npm run geo:staging:verify
npm run geo:images -- --country=SA
```
