# Firestore Payment Schema (Current + Target)

## Current collections

### `payment_sessions/{sessionId}`

**Writers:** Cloud Functions Admin SDK only (`write: false` for clients).  
**Readers:** Owner (`user_id`) or finance/admin.

Observed / intended fields (from `ngenius_payments.js`):

| Field | Notes |
|-------|-------|
| `user_id` | Owner UID |
| `purpose` | `booking` \| `wallet` \| `extra_hours` \| … |
| `provider` | `ngenius` |
| `idempotency_key_hash` | Hash of client idempotency key |
| `amount_halalas` | Integer minor units (today SAR-oriented naming) |
| `currency` | e.g. `SAR` |
| `status` | creating / pending / paid / failed / cancelled / expired / refunded / … |
| `gateway_state` | Raw N-Genius state |
| `provider_order_ref` | N-Genius order reference |
| `payment_url` | Hosted pay URL |
| Quote fields | `carPath`, `countryPath`, `bookingHours`, `additionalHours`, fees, vat |
| Finalize flags | booking created markers, wallet/extra markers |
| Refund fields | amount, actor, timestamps |
| Security | `security_review`, `security_error` on mismatch |

### `webhook_events/{eventId}`

| Field | Notes |
|-------|-------|
| `provider` | `ngenius` |
| `providerEventId` / order id | Dedup |
| `payloadHash` | Dedup |
| `processed` / `processing` | Idempotency |
| `receivedAt` | Timestamp |
| `ignored` / `error` / `sessionId` | Optional |

**Access:** `read, write: false` for all clients.

### `order/{orderId}`

| Path | ID | Payment fields |
|------|-----|----------------|
| Card | Often `sessionId` | `PaymentMethod=OnlinePayment`, `payment_status=paid`, `ngeniusOrderId`, `payment_session_id` |
| Cash CF/fallback | `sha256(uid:cash:key)` | `PaymentMethod=Cash`, `payment_status=pending_cash`, `cash_collection_status` |

Clients **must not** set paid / gateway refs (enforced in rules for cash create).

### Wallet / extra

- `settings/wallet_topup_packages` — package catalog
- `wallets`, `transactions` — top-up results
- `ExtraHours`, `Paymenthistory` — extra hours

## Target additions (Vercel migration)

Compatible extension — prefer additive fields:

| Field | Purpose |
|-------|---------|
| `backend_source` | `firebase_functions` \| `vercel_api` |
| `environment` | `sandbox` \| `production` |
| `amount_minor` | Alias/normalize beside `amount_halalas` |
| `booking_draft_id` | If draft model introduced |
| `booking_created` | Boolean transactional flag |
| `booking_id` | Final order id |
| `normalized_status` | Explicit state machine value |
| `idempotency_key` | Store hash + truncated key metadata |
| `last_verified_at` | Status poll / webhook |
| `failure_code` / `failure_message_key` | Stable localization keys |

## Rules posture (do not deploy in this phase)

- Keep `payment_sessions` / `webhook_events` client-write denied.
- Keep paid order creation server-only.
- Any rule change must ship with emulator tests + manual deploy notes only.

## Indexes

Audit `firestore.indexes.json` for queries on `payment_sessions` by `user_id` + `status` / `idempotency` as needed when Vercel queries grow. Add indexes in repo; do not deploy automatically.
