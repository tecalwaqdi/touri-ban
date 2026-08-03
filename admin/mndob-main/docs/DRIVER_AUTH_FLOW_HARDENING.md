# Driver Auth / Registration / Activation — Production Hardening

## App identity
| Item | Value |
|------|--------|
| Driver app path | `mndob-main` |
| Package (Android) | `com.mycompany.mndob2` |
| Bundle (iOS) | `com.mycompany.mndob3` |
| Firebase project | `tutorial-multi-language-70gx4j` |
| Auth method (production) | Email + password (`Login1` / `regdrever`) |
| Admin app | `Admi` (activation writes `actev_mndob` + `registration_status`) |

## Auth flow (before)
Splash → loggedIn ? NavBar(Home) : Login  
Login gated only on `ismndob` (not `actev_mndob`)  
Register → Auth user + Firestore → **signOut → Login**  
Pending drivers could open Home and see “Account Activation” → wrong Wasl screen  

## Auth flow (after)
Splash → `DriverAuthGate`  
→ Login / Register / **PendingApproval** / Home based on `DriverLifecycle`  
Register stays signed in → Pending screen (Firestore stream on `actev_mndob`)  
Admin approve → stream navigates to Home  
Go Online requires `DriverEligibilityService` + `actev_mndob`  

## State machine
`registration_status`: `pending_review` | `approved` | `rejected` | `suspended`  
`account`: `actev_mndob` + `ismndob`  
`ops`: `ngl` online flag  

## Key new modules
- `lib/core/driver_auth_errors.dart`
- `lib/core/driver_phone_number_service.dart`
- `lib/core/driver_eligibility_service.dart`
- `lib/core/driver_registration_draft.dart`
- `lib/core/driver_session_router.dart`
- `lib/components/driver_auth_gate.dart`
- `lib/driver_pending_approval/driver_pending_approval_widget.dart`

## Manual Firebase / Console steps (if needed)
1. Ensure Email/Password provider enabled.
2. Confirm SHA-1/256 for Phone Auth if OTP is enabled later (not used by production Login1).
3. Admin: activate drivers from pending list — app listens live.
4. To reject with reason: set `registration_status=rejected` and `rejection_reason=...` on `user/{uid}`.

## Not claimed complete without device QA
End-to-end OTP, Storage document upload gallery, and production AAB install still need device verification after `flutter build`.
