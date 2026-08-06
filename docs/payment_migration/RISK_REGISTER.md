# Payment Migration — Risk Register

| ID | Risk | Severity | Evidence | Mitigation in Vercel migration |
|----|------|----------|----------|--------------------------------|
| R1 | Client cash fallback creates client-priced orders | High | Default cash-only + `allowClientCashFallback` | Prefer CF/Vercel cash endpoint; keep fallback behind explicit flag; document |
| R2 | Webhook does not create bookings — paid session without order if client never finalizes | High | `ngeniusWebhook` only syncs sessions | Vercel webhook **must** create/activate booking once when paid (idempotent) |
| R3 | Customer cancel calls refund without finance role | Medium | Customer cancel → `refundNGeniusPayment` | Separate customer cancel vs admin refund; clear error codes |
| R4 | No admin refund UI | Medium | Admi has status only | Add protected refund via Vercel + admin UI later |
| R5 | Flutter `TouryNGeniusConfig.useProduction=true` unused but misleading | Low | Unused class | Do not rely on Flutter for env; keep secrets server-side |
| R6 | App Check off by default | Medium | `NGENIUS_REQUIRE_APP_CHECK` false | Keep optional; document rollout |
| R7 | Dual backends creating duplicate payments | High | Migration period | Feature flag `firebase_functions` \| `vercel_api` \| `cash_only`; one backend per attempt |
| R8 | Amount/currency mismatch if client trusted | Critical | Spec requires server authority | Port `verifiedBookingAmount`; reject mismatches |
| R9 | Secrets in git / Flutter | Critical | Must not happen | Env on Vercel only; secret scan |
| R10 | Production N-Genius enabled by mistake | Critical | Existing dual flag | Require `NGENIUS_ENV=production` (+ keep allow gate) |
| R11 | Driver sees unpaid online if legacy bad data | Medium | Pool does not filter payment_status | Filter `payment_status` / method; keep write-after-pay |
| R12 | Multi-currency incomplete (SAR-centric) | High | Halalas / SAR in CF | Currency module with minor units per country |
| R13 | Firebase billing / CF deploy friction (original migration driver) | Ops | Historical docs | Vercel removes CF deploy dependency for cards only |

## Open decisions (non-blocking for scaffold)

- Whether cash stays on Firebase callable while cards move to Vercel (recommended initially).
- Whether webhook auto-finalize should also credit wallet / extra hours (today separate finalize callables).
