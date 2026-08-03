# PHASE 6 RESULTS — Login errors & password reset

**Date:** 2026-07-28  
**Deploy:** None

## Goal

Map Firebase Auth exceptions to clear i18n messages; password reset without leaking account existence.

## Implementation

Already present / hardened in Phase 5:

- `DriverAuthErrors` covers: user-not-found, wrong-password, invalid-credential, network, disabled, too-many-requests, email-already-in-use, phone, quota, captcha, etc.
- Login catches `FirebaseAuthException` and shows `DriverAuthErrors.localized` (never raw stack)
- Forgot password: always shows generic success after attempt; logs failures safely
- Network errors mapped to `No internet connection.` — not wrong password

## Tests

`driver_auth_flow_test.dart` — code → message key mapping.

## Phase success

**YES**

## Next

Phase 7 — `regdrever` OTP + deprecate Wasl routes (docs already in DEPRECATED_ROUTES.md).
