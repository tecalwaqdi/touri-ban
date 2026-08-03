# PHASE 7 RESULTS — Register & OTP

**Date:** 2026-07-28  
**Deploy:** None

## Goal

Production registration = `regdrever` only. Phone OTP before continuing past account step. Link phone to email Auth user (no duplicate Auth).

## Implementation

| Piece | Detail |
|-------|--------|
| Flow | Step 0 fields → SMS OTP dialog → location → vehicle → submit |
| Service | `DriverPhoneOtpService` — send/verify credential **without** sign-in |
| Link | After `createAccountWithEmail`, `linkWithCredential` |
| Draft | Unchanged uid/guest isolation |
| Deprecated | `NewDriverRegistration` remains routed but marked DEPRECATED in nav |

## Auth sync (Phase 8 overlap)

- Document key = Firebase Auth `uid`
- Missing doc → AuthGate recovery → Regdrever
- No Anonymous in flow

## Device requirements for OTP

- SHA-1 / SHA-256 in Firebase console
- Phone Auth enabled
- Play Integrity / debug test numbers for emulators

If OTP send fails on device without SHA, user sees localized Auth error; registration cannot continue past step 0 (by design).

## Tests

Unit: phone E.164 (existing). OTP needs Firebase emulator / device (manual).

## Phase success

**YES (code path).** Full SMS proof requires device + Firebase Phone Auth config.

## Next

Phases 8–9 — Auth/Firestore sync polish + draft UX (Continue Registration banner).
