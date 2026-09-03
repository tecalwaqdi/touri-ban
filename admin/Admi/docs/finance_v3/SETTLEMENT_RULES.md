# Settlement Rules (V3 / current V2 ledger)

- Party types: driver (current), agent (planned expansion).
- Status: draft → locked → partially_paid / settled / voided.
- Idempotency keys required on create/lock/pay/confirm.
- Same order cannot appear in two open settlements for same party.
- Payment confirm cannot exceed absolute due.
- Settlement writes never touch wallets / order / company_payments.
- Feature flags gate writes.
