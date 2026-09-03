# Migration Plan (Safe)

## Default

`DRY_RUN=true` always unless explicitly overridden after backup proof.

## Stages

1. Scan historical `order` docs.
2. Classify confidence + currency + geo + driver + payment + collection.
3. Detect agent attribution status (`attributed|unattributed|ambiguous|legacy_unprovable|missing_rate`).
4. Emit candidate snapshot JSON **to report only**.
5. Diff vs V2 recognition.
6. Human review.
7. Apply only with backup + flag + SuperAdmin approval.

## Forbidden

- Invent rates from today’s config onto old trips.
- Delete/rename production fields.
- Reset wallets.
- Rewrite completed order money fields.
- Apply without Firestore backup strategy.

## Status

Foundation dry-run scanner: `firebase/functions/scripts/finance_v3_historical_scan_dry_run.js`  
**Apply path: NOT implemented / NOT to be run without approval.**
