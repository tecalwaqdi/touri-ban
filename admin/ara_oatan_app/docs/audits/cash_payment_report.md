# Cash payment report

## Previous failure

`createCashBooking` was never published → Firebase callable `not-found` → checkout aborted → **no booking**.

Firestore Rules: `match /order { allow create: if false }` blocked any client recovery.

## Fix

1. Deployed Rules allowing **cash-only** authenticated creates with fixed payment fields.
2. Client: call CF first; on missing function write order via transaction + idempotent SHA-256 id.
3. Cash path never calls `createNGeniusPayment`.

## Order fields (fallback)

`PaymentMethod=Cash`, `payment_status=cash_pending`, `status_code=pending_driver`, `created_by_client_cash_fallback=true`, amounts from `touryRecalculateCheckoutPrice`.

## Status

| Check | Result |
|-------|--------|
| Cash without N-Genius | Yes |
| Creates Firestore order without CF | Yes (after Rules deploy) |
| Idempotent retries | Same doc id |
| Preferred CF path | Ready; publish after billing |

## Residual risk

Client-calculated totals until CF verifies server-side rates. Prefer publishing `createCashBooking` ASAP.
