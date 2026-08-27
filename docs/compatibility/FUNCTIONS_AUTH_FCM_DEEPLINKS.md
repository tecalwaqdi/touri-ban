# Cloud Functions / API / Auth / FCM / Deep Links

## Primary callables (customer codebase `functions`, region `us-central1`)

| Name | Auth | Notes |
|---|---|---|
| `createCashBooking` | signed-in customer | Canonical cash create; Admin SDK lock |
| `normalizeCashBookingCompatibility` | trigger onWrite `order/{id}` | Additive cash field repair |
| `createNGeniusPayment` / `getNGeniusPayment` / `finalizeNGeniusBooking` | customer | **CURRENT** electronic path — do not remove |
| `ngeniusWebhook` | HTTP | Payment lifecycle |
| `refundNGeniusPayment` | admin/ops | |
| `submitDriverApplicationV2` / `reviewDriverApplicationV2` | driver/admin | Dual-write with legacy fields |
| `approveDriverRegistration` / `rejectDriverRegistration` / `requestDriverChanges` / `autoActivateDriver` | admin | Legacy + V2 bridges |
| `acceptDriverOrder` | driver | Wallet / eligibility gates |
| `payCompanyFromWallet` | driver | |
| `requestEmailVerificationOtp` / `verifyEmailVerificationOtp` / … | user | |
| `addFcmToken` | user | Multi-token friendly |
| FCM triggers | system | Preserve existing data keys |

Payment API (Render): cancel/create/status — old-client compat tests exist (`old-client-compat.test.ts`).

## Auth / claims (high level)

- Email/password (+ OTP verification flows in apps)
- Admin roles via user fields / claims (`isAdminRule`, transport company, country agent)
- Driver gating: `actev_mndob`, registration_status / submission_status (dual-read)
- **Do not** enforce 2FA lockout without migration (`PREPARED_NOT_DEPLOYED`)

## FCM

- Prefer additive optional keys; never rename existing `data` keys used by published apps
- Deep links must keep legacy schemes below

## Deep links (published)

| App | iOS scheme / host | Android |
|---|---|---|
| Customer | `araoatanapp` / `araoatanapp.com` (+ Braintree scheme legacy) | `araoatanapp://araoatanapp.com` |
| Driver | `mndob` / `mndob.com` | `mndob://mndob.com` |

Payment return: Firebase Hosting / `payment-return.html` paths — keep HTTPS return URLs valid.

## Rules matrix (summary)

| Operation | Customer published | Driver published | Admin |
|---|---|---|---|
| Cash order create (client fallback) | allow if valid cash helper | deny | allow |
| Card→Cash unpaid switch | allow constrained fields | deny | allow |
| Order list own USER | allow | — | allow scoped |
| Driver accept / trip updates | deny (prefer callable) | allow constrained | allow |
| Wallet financial writes | deny client | deny / callable | SuperAdmin / flags |

Exact allow/deny: see `admin/ara_oatan_app/firebase/firestore.rules` (+ synced copies). Rules tests: `npm run test:rules` (emulator; may be `NOT_RUN` without Java/emulator).
