# Touri Taxi Full Fix Report

Date: 2026-07-18

## Scope and architecture

The accepted customer, admin, and driver sources share Firebase project
`tutorial-multi-language-70gx4j`. The customer Functions folder is the canonical
source for the secure payment and integration callables. One canonical
Firestore ruleset and one canonical Storage ruleset are copied to all three
applications to prevent a later deployment from weakening the shared project.

## Payment and booking

- Replaced all direct card forms and direct card payloads with N-Genius Hosted
  Payment. Touri code no longer accepts or transmits PAN/CVV.
- Removed the credit-card package, saved-card session/state, Braintree helper,
  card data struct, and direct live-card test script.
- Added server-side quote recalculation, payment-session idempotency, trusted
  paid-booking finalization, webhook/reconciliation, refunds, wallet top-ups,
  withdrawal requests, extra hours, and cash booking creation.
- Wallet withdrawals reserve a pending amount and require finance review.
- Added N-Genius state and idempotency unit tests plus a source-level PCI ban.

Primary files: `firebase/functions/ngenius_payments.js`,
`lib/core/toury_ngenius_service.dart`, `lib/core/toury_payment_flow.dart`,
`lib/components/payment_methods2_widget.dart`,
`lib/components/add_extra_hours2_widget.dart`, checkout/wallet compatibility
screens, payment schema/state, and Firestore rules.

## Security and integrations

- Added App Check and authorization gates to payment and integration callables.
- Moved WhatsApp, OpenCage, Google Directions, and WASL credentials behind
  `firebase/functions/secure_integrations.js`.
- Removed the Firebase Admin private-key JSON from source and protected matching
  files in `.gitignore`.
- Hardened user/order/wallet/payment/refund access and immutable financial fields.
- Hardened Storage writes by role, owner, content type, and size; public access
  is limited to explicit content-image folders.
- Added `wallet_withdrawals` owner/finance rules.

## Maps, location, and tracking

- Customer and driver route services call server-side Google Directions.
- Corrected driver route region to Saudi Arabia.
- Added pickup/stops/destination route composition, live driver position,
  distance/ETA writes, throttling, route-change detection, dark map styling,
  and a Google Maps navigation action.
- Added canonical ASCII status codes (`driver_assigned`, `driver_arrived`,
  `completed`) while preserving legacy status compatibility.
- Content seeding includes 19 countries with flags, Saudi Arabia (13 regions,
  260 landmarks), and Kyrgyzstan (7 regions, 70 landmarks), including map bounds.

## Localization and UX

- All 11 locale assets contain exactly 749 keys: `ar`, `az`, `en`, `fr`, `id`,
  `ka`, `ky`, `ru`, `tr`, `ur`, and `zh-Hans`.
- Translated active English fallbacks and migrated remaining static `Text`
  literals to centralized localization keys.
- Localized dynamic map, rating, order, support, and city messages with named
  placeholders.
- Added strict missing/extra/empty/corrupt/placeholder checks and a hardcoded UI
  string checker.
- Added persisted `preferred_locale` and per-recipient localized payment,
  booking, wallet, driver, and chat notifications.
- Reworked the booking list into theme-aware status cards with route access,
  responsive spacing, empty state, and readable dark-mode surfaces.
- Added theme contrast and RTL/LTR tests.

## Files and generated groups

Significant new or rewritten files include:

- `firebase/functions/ngenius_payments.js`
- `firebase/functions/secure_integrations.js`
- `firebase/functions/test/ngenius_payments_unit.test.js`
- `firebase/functions/api_manager.js`
- `lib/core/toury_notification_localizer.dart`
- customer/driver route, tracking, payment, booking, wallet, and navigation files
- all `assets/langs/*.json`
- all three `firebase/firestore.rules` and `firebase/storage.rules`
- `tool/check_localizations.js` and `tool/check_hardcoded_ui_strings.js`
- `test/core/toury_localization_theme_test.dart`

Deleted card/security files are recorded in `CHANGELOG_FULL_FIX.md`.

## Verification and effect

Automated source analysis and tests pass. The changes reduce PCI exposure,
prevent client-side payment/price forgery, make route calculations consistent,
and remove the observed language mixing. They are not active in production
until Firebase deployment and post-deployment acceptance tests are completed.
