# Payment Migration — Baseline Audit (Phase 0)

**Generated:** 2026-08-06  
**Branch:** `feature/vercel-ngenius-payment-backend`  
**Base commit:** `e8826bad3c90c43c4013d930592e970c6df7ae99`  
**Parent branch:** `main` (clean working tree at branch creation)

## Gap-closure checkpoint (2026-08-06)

| Item | Value |
|------|--------|
| Status | `READY_FOR_SANDBOX_CONFIGURATION` |
| Detail | `IMPLEMENTATION_GAP_CLOSURE.md`, `FLUTTER_REGRESSION_RESULTS.md`, `SANDBOX_READINESS_CHECKLIST.md` |
| Commits on branch (high level) | Audit docs → payment-api + Flutter switch → gap-closure (booking/refund/tests/docs; may be uncommitted — check `git status`) |

## Git checkpoint

| Item | Value |
|------|--------|
| Current branch | `feature/vercel-ngenius-payment-backend` |
| HEAD | `e8826ba` — Ship enterprise admin rebuild, full AR/EN/RU/KY i18n, and related app updates |
| Dirty files at branch create | **0** (clean) |
| Uncommitted user work preserved | N/A — none present |
| Remote | `origin` → `https://github.com/tecalwaqdi/touri-ban.git` |
| Firebase project (apps) | `tutorial-multi-language-70gx4j` |

## Toolchain

| Tool | Version |
|------|---------|
| Flutter | 3.44.8 (stable) |
| Dart | 3.12.2 |
| Node.js | v26.6.0 |
| npm | 11.18.0 |

## Existing payment-related files (primary)

### Firebase Functions
- `admin/ara_oatan_app/firebase/functions/ngenius_payments.js` — full N-Genius + cash + wallet + extra hours + refund + webhook
- `admin/ara_oatan_app/firebase/functions/index.js` — re-exports
- `admin/ara_oatan_app/firebase/functions/test/ngenius_payments_unit.test.js`
- `admin/ara_oatan_app/firebase/functions/.runtimeconfig.example.json`

### Customer Flutter
- `lib/core/toury_ngenius_service.dart` — Cloud Functions client
- `lib/core/toury_payment_flow.dart` — card orchestration
- `lib/core/toury_payment_verify.dart`
- `lib/core/toury_payment_flags.dart` — `ENABLE_ONLINE_PAYMENT` (default **false** = cash-only)
- `lib/core/toury_booking_service.dart` — cash booking
- `lib/core/toury_wallet_ngenius.dart`
- `lib/core/toury_ngenius_config.dart` — outlet/chain IDs only (unused at runtime)
- `lib/order/checkout66/checkout66_widget.dart` — **active checkout**
- `lib/payment_confirm/payment_confirm_widget.dart`
- `lib/webview/webview_widget.dart`
- `lib/paymet_hostre/paymet_hostre_widget.dart`

### Rules / docs
- `admin/ara_oatan_app/firebase/firestore.rules` — `payment_sessions`, `webhook_events`, cash create
- `admin/ara_oatan_app/docs/audits/ngenius_payment_report.md`
- `admin/ara_oatan_app/docs/payments/touri_ngenius_verification.md`

## Firebase Functions payment exports

```
createNGeniusPayment
getNGeniusPayment
finalizeNGeniusBooking
createCashBooking
finalizeNGeniusWalletTopUp
createWalletWithdrawalRequest
finalizeNGeniusExtraHours
refundNGeniusPayment
ngeniusWebhook
```

## Payment / booking collections (current)

| Collection | Role |
|------------|------|
| `payment_sessions` | Card/wallet/extra-hours session ledger (Admin SDK write only) |
| `webhook_events` | Webhook idempotency (no client access) |
| `order` | Bookings (card after finalize; cash via CF or constrained client fallback) |
| `wallets` / `transactions` | Wallet top-up |
| `wallet_withdrawals` | Withdrawal requests |
| `ExtraHours` / `Paymenthistory` | Extra hours |
| `settings/wallet_topup_packages` | Server wallet packages |

## Baseline tests / analyze

**Not re-run at Phase 0** (time / environment). Status at migration start:

| Suite | Status |
|-------|--------|
| Customer `flutter analyze` / `flutter test` | Deferred — document in later phase; classify pre-existing vs introduced |
| Driver / Admin Flutter | Deferred |
| Functions unit tests (`ngenius_payments_unit.test.js`) | Present; not executed in Phase 0 |

## Safety constraints recorded

- Do **not** deploy Firebase during this migration.
- Do **not** enable production N-Genius automatically.
- Do **not** delete existing Firebase payment functions until Vercel path is verified + rollback exists.
- Do **not** commit secrets.
- Do **not** modify `google-services.json` / `GoogleService-Info.plist` / package IDs / signing.

## Next

See Phase 1 docs in this folder:
- `CURRENT_PAYMENT_ARCHITECTURE.md`
- `PAYMENT_CALL_GRAPH.md`
- `RISK_REGISTER.md`
- `FIRESTORE_PAYMENT_SCHEMA.md`
