# Active trip extra hours — local verification

## Cause

The customer action depended on legacy `halhOrderMndob == Accepted` and was
inside a legacy driver-card section. Canonical active statuses could therefore
lose the action. The existing extra-hours finalizer updated `total_taim` but
left `endTime` and the order's financial totals unchanged. Extra-hours creation
used Firebase N-Genius while default payment verification used the external API.

## Implementation

- Reuse the existing sheet, N-Genius checkout, `payment_sessions`, `ExtraHours`
  receipts and `Paymenthistory`. No new order or wallet transaction is created.
- Server-validated ownership, assigned driver and active status. Terminal,
  unpaid-online and frozen/settlement-claimed orders cannot be extended.
- Quote uses the order's booked `SrSAAH`; legacy orders fall back to the active
  vehicle's price with market validation. Client amounts are ignored. Currency
  precision follows the market currency.
- Show current/additional/new hours, incremental price and new total. Require
  explicit confirmation. The same request key survives uncertain retries.
- Cash updates the original order and receipt atomically, retaining cash due.
  Online increments use the existing Firebase extra-hours N-Genius flow through
  creation, verification and finalization. Authorization alone is insufficient;
  provider capture/purchase, amount and currency must verify before application.
- Preserve the recorded discount and commission/VAT allocation basis. Update
  the existing financial amount fields; attributed agent amounts use the existing
  FIN-9 helper and recorded rate. Settlement code is unchanged.
- Transactions update `total_taim`, `endTime`, pricing duration and order totals.
  Receipts provide idempotency; one pending session per order prevents concurrent
  online charges. The existing customer/driver/admin order listeners receive the
  same update, including amount and end time.
- Driver start/completion re-read the order transactionally. Countdown/completion
  use the later of stored end time and start plus total duration. Rules prevent
  older clients shortening an extended trip or completing before its new end.

## Tests

42 feature tests passed:

- 22 Node unit tests: eligibility, price, currency precision, financial basis,
  quote fingerprint, duration and end-time calculation.
- 15 Firestore emulator tests: atomic updates, three authenticated live readers,
  duplicate/concurrent cash requests, single-flight online reservations,
  verified payment application, callback retries, amount/currency mismatch,
  late payment on terminal orders, settlement locks, agent amount preservation,
  security rules, and actual callable creation with a stubbed gateway.
- 2 customer Flutter tests: canonical eligibility and sheet interaction including
  authoritative price, hour selection, confirmation/cancellation and double-click.
- 3 driver Flutter tests: extended countdown and completion deadline.

Other checks:

- Existing N-Genius unit suite passed.
- 16 existing customer duration/payment helper tests passed.
- Customer analysis for changed files and tests: no issues.
- Driver analysis: no errors/warnings; four existing interpolation style infos.
- ESLint for changed payment implementation and tests passed.
- General Firestore rules suite: 57/58 passed. The failure is
  `country admin can update type_car per current rules` at
  `firebase/functions/test/firestore_rules.test.js:480`. It also fails against
  `git show HEAD:admin/ara_oatan_app/firebase/firestore.rules`; the existing rules
  limit catalog writes to super admins. This unrelated policy/test was preserved.
- Three application copies of Firestore rules remain identical.

### Commands

From `firebase/functions`:

```sh
node --test test/extra_hours.test.js
FIRESTORE_EMULATOR_HOST=127.0.0.1:8187 node --test test/extra_hours_emulator.test.js
npm run test:unit
./node_modules/.bin/eslint extra_hours.js ngenius_payments.js test/extra_hours.test.js test/extra_hours_emulator.test.js
```

The integration test requires an isolated local Firestore emulator and uses
`demo-extra-hours`; it clears that emulator test project's data. Java must use
`-Duser.language=en -Duser.country=US` on this machine to avoid an emulator regex
initialization failure caused by locale-formatted digits.

From the customer and driver app directories respectively:

```sh
flutter test --no-pub test/core/toury_extra_hours_test.dart
flutter test --no-pub test/core/driver_extra_hours_test.dart
```

## Release status and limits

Implementation is local; nothing was deployed and no live card was charged.
Release requires the customer/driver changes, synchronized Firestore rules and
these customer Firebase function exports:
`getExtraHoursQuote`, `addCashExtraHours`, `createNGeniusPayment`,
`getNGeniusPayment`, `finalizeNGeniusExtraHours`, `ngeniusWebhook`.

Before release, exercise the existing configured N-Genius environment, checkout
return and webhook on devices. Ambiguous gateway creation timeouts remain locked
against another charge. A payment captured after a trip becomes terminal is kept
as actually paid and flagged for review; it never reopens the trip. Pre-change
payment sessions without the required trusted extension quote fail safely.

```text
ADD_HOURS_BUTTON=PASS_LOCAL
ELIGIBILITY=PASS_LOCAL
PRICE_CALCULATION=PASS_LOCAL
CONFIRMATION=PASS_LOCAL
ORDER_DURATION_UPDATED=PASS_LOCAL_SAME_ORDER
NEW_END_TIME=PASS_LOCAL
PAYMENT_FLOW=EXISTING_FLOW_TESTED_WITH_STUBBED_GATEWAY; LIVE_NOT_TESTED
DRIVER_SYNC=PASS_EMULATOR
CUSTOMER_SYNC=PASS_EMULATOR
ADMIN_SYNC=PASS_EMULATOR
DUPLICATE_PROTECTION=PASS_LOCAL
TRIP_COMPLETION_USES_EXTENDED_TIME=PASS_LOCAL
TESTS=42_FEATURE_PASS; GENERAL_RULES_57_OF_58_WITH_CONFIRMED_BASELINE_FAILURE
FINAL_STATUS=IMPLEMENTED_LOCALLY; NOT_DEPLOYED
```
