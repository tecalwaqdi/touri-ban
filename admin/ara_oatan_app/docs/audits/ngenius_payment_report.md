# N-Genius payment report

## Status: NOT STORE-READY for card until billing + deploy

| Item | Value |
|------|-------|
| Provider | Network International / N-Genius only (no Moyasar) |
| Functions | `createNGeniusPayment`, `getNGeniusPayment`, `finalizeNGeniusBooking`, extras/wallet/refund/webhook |
| Region | `us-central1` |
| Client | `lib/core/toury_ngenius_service.dart` |
| Published on Firebase | **No** (billing block) |

## After external unblock

1. Enable billing.
2. Set `NGENIUS_*` env/secrets; Sandbox: `NGENIUS_PRODUCTION=false`.
3. Deploy functions (commands in `manual_external_requirements.md`).
4. Sandbox E2E: create order → hosted pay → S2S finalize → single booking.

## Safety

- No PAN/CVV storage in app.
- Idempotency keys for payment sessions.
- Booking finalized only after server verification when CF path is used.
