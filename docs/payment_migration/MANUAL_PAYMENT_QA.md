# Manual Payment QA Matrix

**Status:** Not executed on devices in this migration phase.  
Mark cases only after real device/sandbox runs.  
Code readiness: see `SANDBOX_READINESS_CHECKLIST.md` and `IMPLEMENTATION_GAP_CLOSURE.md`.

| ID | Case | Android | iOS | ar | en | ru | ky | Result |
|----|------|---------|-----|----|----|----|----|--------|
| M01 | Cash booking create (Vercel unavailable) | | | | | | | |
| M02 | Card create session (sandbox Vercel) | | | | | | | |
| M03 | Visa 3DS success → **one complete order** | | | | | | | |
| M04 | Mastercard 3DS success | | | | | | | |
| M05 | Mada (if outlet supports) | | | | | | | |
| M06 | 3DS failure — no order | | | | | | | |
| M07 | User cancel pending | | | | | | | |
| M08 | Kill app mid-payment | | | | | | | |
| M09 | Network loss | | | | | | | |
| M10 | Double tap create (idempotent session) | | | | | | | |
| M11 | Delayed webhook after polling finalize | | | | | | | |
| M12 | Duplicate webhook — no second order | | | | | | | |
| M13 | Return URL ok but unpaid | | | | | | | |
| M14 | Paid but return URL fails — webhook still books | | | | | | | |
| M15 | Driver sees paid online only | | | | | | | |
| M16 | Driver sees cash | | | | | | | |
| M17 | Admin status visible | | | | | | | |
| M18 | Refund (admin finance) — full/partial | | | | | | | |
| M19 | Customer refund rejected | | | | | | | |
| M20 | Wallet / extra-hours still via Firebase | | | | | | | |
| M21 | Rollback `PAYMENT_BACKEND=firebase_functions` | | | | | | | |
| M22 | SA / KG / RU / UZ currency | | | | | | | |

Countries/currencies must match live Firestore country documents.

## Order completeness check (after M03)

Compare paid online `order/{sessionId}` to a known-good cash order:

- [ ] Customer history shows trip
- [ ] Driver pool offer appears once
- [ ] Admin booking details show payment + amounts
- [ ] `payment_session_id` / `ngeniusOrderId` present
- [ ] `status_code=pending_driver`, `ALLNOW=true`, `PaymentMethod=OnlinePayment`
