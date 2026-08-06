# Payment Call Graph

```
CUSTOMER CHECKOUT (Checkout66Widget /checkout66)
│
├─ CASH (default when ENABLE_ONLINE_PAYMENT=false)
│    touryCreateCashBookingFromCurrentState
│      ├─ cashOnlyMode && allowClientCashFallback
│      │     → touryCreateCashBookingViaFirestoreFallback
│      │        order/{sha256} payment_status=pending_cash
│      └─ else
│            makeCloudCall('createCashBooking')
│              → verifiedBookingAmount()
│              → order/{sha256} PaymentMethod=Cash, pending_cash
│
└─ CARD (ENABLE_ONLINE_PAYMENT=true)
     touryExecuteCardPayment
       → NGeniusPaymentCall / TouryNGeniusService.createPayment
         → createNGeniusPayment
              verifiedBookingAmount()  // ignores client amount for booking
              payment_sessions/{sha256(uid:idempotency)}
              N-Genius POST /orders → payment_url
       → touryNavigateAfterCardPayment
            ├─ 3DS URL → WebviewWidget (/webview)
            │     poll touryVerifyGatewayPayment → getNGeniusPayment
            │     on paid → PaymentConfirm (fromWebView=false)
            └─ paid / no URL → PaymentConfirm (fromWebView=false)
                 verify → finalizeNGeniusBooking
                   ownedPaidSession() + gateway re-fetch
                   order/{sessionId} payment_status=paid

WALLET TOP-UP
  touryStartWalletTopUp(packageId)
    → createNGeniusPayment(purpose=wallet)  // amount from settings/wallet_topup_packages
    → WebView / PaymentConfirm
    → finalizeNGeniusWalletTopUp → wallets + transactions

EXTRA HOURS
  AddExtraHours2Widget
    → createNGeniusPayment(purpose=extra_hours)
    → finalizeNGeniusExtraHours → ExtraHours + Paymenthistory + order.total_taim

WEBHOOK (HTTP)
  ngeniusWebhook
    header token (x-toury-webhook-token by default)
    webhook_events idempotency
    syncSessionFromGateway(payment_sessions)
    // does NOT create order documents today

REFUND
  refundNGeniusPayment ← requireFinanceRole
  (Admin UI: none today; customer cancel may attempt refund call)
```

## Callable / HTTP map

| Name | Type | Auth |
|------|------|------|
| `createNGeniusPayment` | onCall | Firebase Auth (+ optional App Check) |
| `getNGeniusPayment` | onCall | Owner |
| `finalizeNGeniusBooking` | onCall | Owner + paid |
| `createCashBooking` | onCall | Auth |
| `finalizeNGeniusWalletTopUp` | onCall | Owner + paid |
| `createWalletWithdrawalRequest` | onCall | Auth |
| `finalizeNGeniusExtraHours` | onCall | Owner + paid |
| `refundNGeniusPayment` | onCall | Finance / admin |
| `ngeniusWebhook` | onRequest POST | Shared secret header |
