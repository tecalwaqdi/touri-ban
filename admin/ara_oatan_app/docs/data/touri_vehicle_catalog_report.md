# Touri Vehicle Catalog Report

**Status:** Deferred until Makkah geo pilot is approved.

Existing production path:

- Collection: `type_car`
- Admin create: `names_i18n` ar/en/ru/ky
- Customer display: `touryTypeCarName` + built-in catalog fallback
- Backfill tool: Admin Settings i18n backfill now includes `type_car`

Next phase will add verified make/model catalog with country availability — no brand logos without permission.
