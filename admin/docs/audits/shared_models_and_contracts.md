# Shared models and contracts

## Status codes

Mirrored in:
- Customer: `ara_oatan_app/lib/core/toury_booking_status_localizer.dart`
- Driver: `mndob-main/lib/core/toury_system_status_codes.dart`
- Admin: `Admi/lib/core/toury_system_status_codes.dart`

Booking `status_code` and payment `payment_status` must be written by services — never compared via translated UI labels.

## Driver trip contract

`DriverTripService` is the only writer for:
- accept (Firestore **transaction**)
- arrived
- start
- complete (+ cash_collected fields)

## Admin finance

`OrderStatusHelper` + `FinancialEngine` interpret codes without Mojibake corrupt strings.

## Remaining unification debt

- Duplicate const files across apps (prefer shared package later)
- Legacy Arabic `halh_text` still written for backward-compatible lists
- N-Genius Functions deploy still blocked by Cloud Billing
