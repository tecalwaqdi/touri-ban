# Currency Migration Dry Run

**Executed in this session:** **No** (no production credentials / no write).

**Script:** `admin/ara_oatan_app/firebase/scripts/currency_migration_dry_run.js`

When run with a service account it will:

- Scan up to 500 `order` docs
- Classify `alreadyOk` / `proposed` / `needsManualReview`
- Write `currency_migration_dry_run_report.json` beside the script
- **Never** update Firestore

## Expected for Kyrgyzstan QA orders

Orders created before the client fix may have `currency: "SAR"` while `Rev_dolh` points at Kyrgyzstan → dry-run should propose `KGS` via `country_ref`.

## Manual approval required before any apply script
