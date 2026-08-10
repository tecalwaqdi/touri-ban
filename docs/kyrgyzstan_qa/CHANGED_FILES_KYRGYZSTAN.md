# Changed Files — Kyrgyzstan QA

## Customer (`admin/ara_oatan_app`)

- `lib/core/toury_customer_order_actions.dart` — single cancel write; error keys
- `lib/core/toury_currency.dart` — **new** country-driven currency helpers
- `lib/core/toury_booking_service.dart` — store country currency; map permission errors
- `lib/order/tfasel_order/tfasel_order_widget.dart` — currency display; Cancel `.tr()`; localized errors
- `lib/flutter_flow/internationalization.dart` — ru/ky Cancel Order
- `assets/langs/{ar,en,ru,ky}.json` — booking/cancel keys
- `test/core/toury_currency_cancel_test.dart` — **new**
- `firebase/firestore.rules` — accept `cancelled_by_customer` as well as `cancelled`
- `firebase/functions/ngenius_payments.js` — cash booking currency from country quote
- `firebase/scripts/currency_migration_dry_run.js` — **new** dry-run only

## Docs (`docs/kyrgyzstan_qa/`)

- `KYRGYZSTAN_QA_INITIAL_AUDIT.md`
- `KYRGYZSTAN_QA_FINAL_REPORT.md`
- `DRIVER_IOS_APP_STORE_AUDIT.md`
- `CURRENCY_MIGRATION_PLAN.md`
- `CURRENCY_MIGRATION_DRY_RUN.md`
- `DRIVER_AUTH_NOTES.md`
- `CHANGED_FILES_KYRGYZSTAN.md` (this file)

## Not changed (deferred / external)

- Full admin `currencies` collection UI
- Multi-currency wallet ledger schema
- Driver App Store Connect metadata
- Firebase deploy / App Store publish
