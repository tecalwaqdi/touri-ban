# Sandbox Readiness Checklist

**Current status:** `READY_FOR_SANDBOX_CONFIGURATION`

Do **not** mark `SANDBOX_TESTED_NOT_PRODUCTION_READY` until real sandbox device tests pass.

---

## Code readiness (done)

- [x] Audit docs exist under `docs/payment_migration/`
- [x] `admin/services/payment-api` create / status / cancel / finalize / refund / webhook
- [x] Server-side booking pricing (minor units)
- [x] Booking draft stored on session; complete order builder matching CF finalize
- [x] Idempotent booking (webhook ↔ finalize race-safe)
- [x] Driver visibility rules documented + unit test
- [x] Feature flags: `cash_only` / `firebase_functions` / `vercel_api`
- [x] Flutter clients do not embed N-Genius secrets
- [x] Release builds reject localhost payment API URL
- [x] Wallet / extra-hours decision documented (remain on Firebase)
- [x] Refund route calls N-Genius refund link when configured; else `REFUND_NOT_CONFIGURED`
- [x] Admin finance refund UI (server still authorizes)
- [x] Backend `npm test` / typecheck / build (see STATUS / gap closure)
- [x] Flutter analyze/test executed and documented

## External configuration (manual — not done in this environment)

- [ ] Create Vercel project with root `admin/services/payment-api`
- [ ] Set env from `.env.example` (names only in git):
  - [ ] `NGENIUS_ENV=sandbox`
  - [ ] `NGENIUS_API_KEY` (sandbox)
  - [ ] `NGENIUS_OUTLET_REF` (sandbox)
  - [ ] `NGENIUS_WEBHOOK_SECRET` + header name
  - [ ] Firebase Admin credentials for token verify + Firestore
  - [ ] `PAYMENT_RETURN_BASE_URL` / cancel URL
- [ ] Deploy Vercel (manual)
- [ ] Configure N-Genius webhook → `https://<host>/api/webhooks/ngenius`
- [ ] Build customer with:
  ```
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=vercel_api
  --dart-define=PAYMENT_API_BASE_URL=https://<host>
  ```
- [ ] Build admin with same `PAYMENT_API_BASE_URL` for refund UI
- [ ] Keep Firebase Functions available for wallet / extra-hours / rollback

## Manual sandbox QA (after config)

Follow `MANUAL_PAYMENT_QA.md`:

- [ ] Cash booking still works with Vercel down
- [ ] Card create → hosted page → paid → one complete order
- [ ] Duplicate webhook does not duplicate order
- [ ] Polling before/after webhook still one order
- [ ] Driver sees paid order; does not see unpaid session
- [ ] Cancel pending works; cancel paid rejected
- [ ] Admin refund (if gateway refund link present)
- [ ] Customer refund rejected
- [ ] Localization of payment errors (ar/en/ru/ky)

## Hard stops

- Do **not** set `NGENIUS_ENV=production`
- Do **not** deploy Firebase from this migration
- Do **not** claim production readiness

## If blocked

Set status to **`BLOCKED`** only if a code defect prevents sandbox configuration (e.g. booking builder incomplete). Credential absence alone keeps status **`READY_FOR_SANDBOX_CONFIGURATION`**.
