# Currency Migration Plan

**Status:** Plan only — **do not run against production** without explicit approval.

## Goals

1. Every `order` has `currency_code` (ISO 4217) and preferably `currency_symbol`.
2. Country docs have required `currency_code` + `CurrencySymbol`.
3. Never mix SAR/KGS/RUB/UZS in a single wallet balance without per-currency ledgers.
4. No automatic FX conversion in this phase.

## Source of truth

| Collection | Fields |
|------------|--------|
| `countries/{id}` | `currency_code`, `CurrencySymbol`, optional `currency_decimal_digits` |
| `order/{id}` | `currency` (legacy), add `currency_code`, `currency_symbol` |
| Future `currencies/{code}` | catalog for admin picker (optional phase 2) |

Official currencies for active markets: **SAR, KGS, RUB, UZS**.

## Inference rules (dry-run)

For orders missing `currency_code`:

1. If `currency` is already `SAR|KGS|RUB|UZS` → copy to `currency_code`.
2. Else resolve `Rev_dolh` → country `currency_code`.
3. Else resolve country `iso_code` → map SA→SAR, KG→KGS, RU→RUB, UZ→UZS.
4. Else mark **needs_manual_review**.

## Safety

- Dry-run writes **report JSON only**.
- Ambiguous docs are listed, not patched.
- Keep legacy `currency` field until all readers migrate.
- Wallet: do not merge multi-currency balances; separate `balances.{CODE}` in a later change.

## Script

See `admin/ara_oatan_app/firebase/scripts/currency_migration_dry_run.js`  
Run: `node currency_migration_dry_run.js --project=…` (requires credentials; not executed here).

## Rollback

Revert client to previous display helpers; leave Firestore fields additive (no destructive deletes).
