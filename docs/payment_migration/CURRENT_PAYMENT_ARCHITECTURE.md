# Current Payment Architecture

## Summary

Card payments go through **Firebase Cloud Functions** → **Network International N-Genius**.  
Cash bookings are independent of N-Genius.  
**Default customer build is cash-only** (`ENABLE_ONLINE_PAYMENT` defaults to `false`).

Authoritative pricing for card (and CF cash) is computed server-side in `verifiedBookingAmount` inside `ngenius_payments.js`. Flutter-supplied amounts are not charged for booking/extra_hours; wallet uses server packages only.

## Active customer booking flow

1. User builds trip in customer app and navigates to **Checkout66** (`/checkout66`).
2. **Cash (default):** `touryCreateCashBookingFromCurrentState` → preferably `createCashBooking` CF; in cash-only mode may use constrained **client Firestore fallback** when `TOURY_CLIENT_CASH_FALLBACK` is true (default).
3. **Card (when online enabled):** `touryExecuteCardPayment` → `createNGeniusPayment` → hosted payment URL / 3DS WebView → verify via `getNGeniusPayment` → `finalizeNGeniusBooking` creates `order/{sessionId}` with `payment_status=paid`.

## Active screens & routes

| Concern | File | Route |
|---------|------|-------|
| Checkout | `admin/ara_oatan_app/lib/order/checkout66/checkout66_widget.dart` | `/checkout66` |
| Legacy checkout copies | `checkout66_copy*`, `checkout66_copy2*` | Redirect builders → `Checkout66Widget` |
| 3DS WebView | `lib/webview/webview_widget.dart` | `/webview` |
| Payment confirm | `lib/payment_confirm/payment_confirm_widget.dart` | `/paymentConfirm` (+ alias `payMoyserOK`) |
| Payment history | `lib/paymet_hostre/paymet_hostre_widget.dart` | `/paymetHostre` |

## Active card-payment service

- Flutter: `TouryNGeniusService` → `makeCloudCall(...)`.
- Backend: `createNGeniusPayment`, `getNGeniusPayment`, `finalizeNGeniusBooking`, `ngeniusWebhook`, `refundNGeniusPayment`.

## When documents are created

| Event | Document | Timing |
|-------|----------|--------|
| Card session | `payment_sessions/{hash}` | On `createNGeniusPayment` |
| Card booking | `order/{sessionId}` | Only after paid + `finalizeNGeniusBooking` |
| Cash booking | `order/{sha256(uid:cash:key)}` | On `createCashBooking` or client fallback |
| Webhook | Updates `payment_sessions`; writes `webhook_events` | **Does not** create bookings today |

## Driver visibility

- Driver app does **not** call N-Genius.
- Open pool queries `status_code == pending_driver` (+ `ALLNOW`).
- Unpaid online bookings never enter the pool because card `order` docs are written only after verified payment.

## Admin

- Shows payment status labels via finance helpers.
- **No admin refund UI** today; CF `refundNGeniusPayment` requires finance/super-admin role claims or Firestore admin flags.

## Currencies / country

- Pricing currently uses country + vehicle docs; gateway amounts historically use SAR minor units (halalas) in CF.
- Multi-currency must be hardened in the Vercel pricing module (validate country currency + minor units).

## Feature flags (customer)

| Flag | Dart-define | Default |
|------|-------------|---------|
| Online card | `ENABLE_ONLINE_PAYMENT` | `false` |
| Client cash fallback | `TOURY_CLIENT_CASH_FALLBACK` | `true` |

## Side effects after successful card payment

1. `payment_sessions.status` → `paid` (verify/webhook sync).
2. `finalizeNGeniusBooking` writes `order` with OnlinePayment + paid fields + `pending_driver`.
3. Push / matching side effects follow existing order creation paths (not webhook).
4. Wallet / extra-hours have separate finalize callables.

## Legacy / unused

- `TouryNGeniusConfig` outlet UUID + `useProduction=true` in Flutter — **not used** by runtime payment calls (misleading).
- Checkout copy widget files remain but routes redirect to active checkout.
- Old Mojib/Moyser naming (`idMoyser`, `payMoyserOK`).
