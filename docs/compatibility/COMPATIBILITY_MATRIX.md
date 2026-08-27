# Compatibility Matrix (published contracts)

Legend: R=read W=write C=callable — absence must not break published builds.

| CONTRACT | CUSTOMER_CURRENT | DRIVER_CURRENT | ADMIN |
|---|---|---|---|
| `user` profile / `Rev_dolh` | R/W | R/W | R/W |
| `order.USER` | R/W create | R | R |
| `order.data_order` | R + orderBy | R + orderBy | R + orderBy |
| `order.status_code` | R | R/W trip | R/W |
| `order.ALLNOW` | R | R/W | R/W |
| `order.ActiveOrder` | R (legacy lock) | R/W | R |
| `order.halh` / `halh_order` | R | R/W | R |
| `order.PaymentMethod` / `payment_method` / `payth` | R/W cash | R | R |
| `order.payment_status` | R/W | R | R |
| `order.ElectronicPayment` | R/W | R | R |
| `order.mndob_user` | R | R/W accept | R/W |
| `type_car` pricing fields | R | R | R/W |
| `countries` / `cities` / `villages` | R | R | R/W |
| `transport_company` | — | R | R/W |
| `wallets` / `transactions` | limited | R (+ callables) | R/W (flagged) |
| `Paymenthistory` / payment_sessions | R | — | R |
| `support` | R/W own | — | R/W |
| N-Genius payment callables | C | — | ops |
| `createCashBooking` | C | — | — |
| FCM token add | C | C | — |
| Deep link schemes | keep | keep | n/a |

## COMPATIBILITY_BASELINE

`COMPATIBILITY_BASELINE=PASS` (static inventory + unit tests)

Runtime device proof for full Customer/Driver E2E: `NOT_RUNTIME_PROVEN` except cash field probe on sample order (see FINAL report).

## Report conflict classifications

| Topic | Class |
|---|---|
| Cash-only marketplace | `TARGET_ONLY` / `CONFLICTING` vs live N-Genius |
| Replace `type_car` with vehicle_classes | `TARGET_ONLY` — additive only |
| Sudden 2FA Super Admin enforcement | `PREPARED_NOT_DEPLOYED` |
| Mass geo merge/delete | `PREPARED_NOT_DEPLOYED` |
| Mass financial balance correction | `PREPARED_NOT_DEPLOYED` |
