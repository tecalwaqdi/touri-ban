# Payment Migration — Status Report

**Branch:** `feature/vercel-ngenius-payment-backend`  
**Final status:** `READY_FOR_SANDBOX_CONFIGURATION`

## 1. Executive Summary

Gap closure complete for code paths required before sandbox configuration. Webhook/finalize now create a **production-compatible** `order` from a validated booking draft (CF `finalizeNGeniusBooking` parity). Refund calls N-Genius when credentials exist, otherwise returns `REFUND_NOT_CONFIGURED`. Wallet and extra-hours remain on Firebase by explicit decision. Flutter regression suites were executed and documented. No Firebase/Vercel deploy; no production N-Genius.

## 2. Active Flow Confirmed

| Flow | Path |
|------|------|
| Card (Vercel flag) | Checkout66 → payment-api create → WebView → status/webhook → complete order |
| Card (rollback) | Existing CF create / get / finalize |
| Cash | `createCashBooking` / client fallback — independent of Vercel |
| Driver | Sees only `order` with `pending_driver` + `ALLNOW` |
| Admin refund | Finance UI → payment-api `/api/payments/refund` |

## 3. Backend tests (executed)

```bash
cd services/payment-api
npm ci
npm run lint        # No ESLint warnings or errors
npm run typecheck   # passed
npm test            # 37 passed (4 files)
npm run build       # passed
```

Coverage includes: draft validation, status machine, pricing/currency, webhook secret/outlet/amount/currency guards, cancel-paid rejection, refundable amounts, wallet/extra-hours gate, auth header shape, refund link extraction.

Full Firebase-mocked HTTP integration for every auth/webhook race is still deferred to sandbox (requires Admin credentials).

## 4. Flutter regression (executed)

See `FLUTTER_REGRESSION_RESULTS.md`.

| App | Analyze | Test |
|-----|---------|------|
| Customer | No issues | 78 pass / 1 pre-existing fail |
| Driver | 0 errors (warnings only) | 137 pass |
| Admin | 0 errors after HttpHeaders fix (33 info/warn) | 3 pass / 1 pre-existing Firebase seed fail |

## 5. Wallet / extra-hours

**Keep temporarily on Firebase** — documented in `IMPLEMENTATION_GAP_CLOSURE.md`. Vercel create rejects non-booking purposes.

## 6. Refund

Implemented with finance auth + N-Genius `cnp:refund`. Live provider call needs sandbox secrets → otherwise `REFUND_NOT_CONFIGURED`.

## 7. Remaining manual steps

See `SANDBOX_READINESS_CHECKLIST.md` (Vercel env, webhook, dart-defines, device QA).

## 8. Rollback

```bash
--dart-define=PAYMENT_BACKEND=firebase_functions
# or cash_only / disable ENABLE_ONLINE_PAYMENT
```

## 9. Final Status

**`READY_FOR_SANDBOX_CONFIGURATION`**

Not advanced to `SANDBOX_TESTED_NOT_PRODUCTION_READY` (no device sandbox run).
