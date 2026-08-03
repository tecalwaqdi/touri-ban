# Touri Taxi Data Migration

## Safety

Take an export before migration. Use Application Default Credentials or a
temporary credential outside the repository. Do not restore the deleted
service-account JSON to this project. Test against an emulator or cloned
project first.

## Required migrations

1. Revoke the exposed Firebase Admin service-account key in IAM / Firebase
   Console and create no replacement file in Git.
2. Delete legacy sensitive fields from every payment-method document, including
   `numpercard`, `ccv`, `cvc`, full card number, or equivalent aliases. Preserve
   only provider token/reference, brand, expiry when permitted, and `last4`.
3. Review logs/backups/exports for historical card data and follow the merchant
   PCI incident process if any real PAN/CVV existed.
4. Backfill `preferred_locale` for users where known; use `en` only as a safe
   fallback when no preference exists.
5. Backfill canonical booking fields (`status_code`, `payment_status`, trusted
   amount/currency/payment session ids) without changing historical financial
   values.
6. Backfill country/region/city identifiers and map bounds for old content.
7. Validate wallet balances against immutable ledger transactions before
   enabling withdrawals.

## Content replacement

The user approved replacing legacy content data. Execute the seed/expand scripts
only after exporting production and reviewing record counts. The prepared
content target is 19 countries with flags, Saudi Arabia 13/260, and Kyrgyzstan
7/70. Do not delete users, orders, payments, wallets, refunds, or audit records.

## Verification

- Compare document counts and sampled references before/after.
- Verify no orphan country/region/city/landmark references.
- Search exported payment data for sensitive field names and realistic PAN
  patterns; store no findings in the repository.
- Reconcile paid/refunded orders with N-Genius before enabling production.
- Record migration timestamp, operator, script revision, counts, and rollback
  export id.

No production migration or deletion was executed by this audit.
