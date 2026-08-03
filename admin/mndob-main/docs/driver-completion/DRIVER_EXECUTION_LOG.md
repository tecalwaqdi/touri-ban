# DRIVER_EXECUTION_LOG

## 2026-07-28 — Final workstreams M→R (no Deploy / no Push)

### What
- Checkpoint: `checkpoints/PRE_FINAL_WORKSTREAMS_*`
- M: `DriverAppLifecycleCoordinator`, connectivity, offline queue (reconcile-before-replay), backend recovery
- N: Performance audit; cancel auth/JWT stream leaks; listener dedupe
- O: `DriverA11y` + responsive/a11y audits
- P: Extra unit tests; FINAL_TEST_MATRIX (widget/device TBD)
- Q: Screen/button matrix; traceability update
- R: Release APK + AAB local; readiness report
- Firebase deploy package docs only

### Tests
**117 passed**

### Builds
- APK ~98MB SHA-256 `3C29E92B…5147`
- AAB ~77MB SHA-256 `9C6A65E9…5B3B`

### Judgment
Code Complete (M–R): **YES** · Production Ready: **NO**

### Deploy
None.

---

## 2026-07-28 — Phase 4 closeout (Country/Region/City + fields)

### What
- Wired Country→Region→City using existing `countries` / `cities` / `villages` (no new collection, no Deploy)
- `DriverRegLocationCascade` + `DriverLocationCatalogService`
- Draft: regionPath/villagePath restore; submit writes `mndob_vill` (was null)
- Validators: Location/Phone/Email/Vehicle wrappers; Completeness includes region/city/phone ISO
- Document requirements gate on step 2; MIME check on upload
- Preserved AuthGate/Draft/Resubmit; no Anonymous Auth; no orders/redesign
- Docs: PHASE4_RESULTS, inventory, matrix, QA updated

### Tests
**76 passed** (Phase 2–4 suites)

### Analyze
Phase 4 paths: **0 errors**

### Manual
Device Phase 2–4: **TBD**

### Deploy
None.

### Phase 5
Not started.

---

### What
- Fixed LocationStep compile/UI (country label, city controller, no TextFormField type args)
- Fixed birth date display on Account + Review (`yyyy-MM-dd`)
- Removed unused color/city state; city via `cityController` only
- Central validators + Phone Persian digits + Draft extended + upload flush after UID
- Docs: PHASE4_FIELDS_INVENTORY, PHASE4_RESULTS (full sections), matrix/QA/screen inventory updated
- Preserved: DriverBootstrapService, AuthGate, AccountStateResolver, Draft+migrateGuestToUid, Resubmit, `context.go('/')`, no Anonymous Auth
- **No Firebase Deploy**

### Tests
`flutter test` (7 suites): **70 passed**

### Analyze
Phase 4 paths: **0 errors** (infos/warnings only)

### Manual
Device Phase 2–4: **TBD** (not marked Passed)

### Deploy
None.

### Phase 5
Not started — awaiting Phase 4 results review.

---

## 2026-07-28 — Phase 4 registration fields / vehicle / documents

### What
- Central validators (name Unicode, birth, identity, plate, year, seats, docs, completeness)
- Phone Persian digits; Plate normalizer; Draft extended
- regdrever: 4 steps + birth/color/seats/uploads/review; flush uploads after UID
- Document upload service (users/{uid}/uploads); requirements repo
- PHASE4_FIELDS_INVENTORY.md + PHASE4_RESULTS.md
- No Firebase Deploy; AuthGate/Draft architecture preserved

### Tests
validators + prior Phase2/3 suites (see PHASE4_RESULTS)

### Manual
Device Phase2–4 still **TBD**

### Deploy
None.

---

## 2026-07-28 — Phase 3 (registration / draft / pending) re-scope

### Goal (user)
Complete registration + DriverRegistrationDraft + Pending/Changes/Rejected without touching orders/trips/full redesign; no Firebase deploy.

### What
- Draft: migrateGuestToUid, hasContinuableDraft, step>0 load, unit tests
- Regdrever: Save and exit, continue banner, resubmit without new Auth, OTP skip when logged-in, clear status on submit
- Pending: distinct changes/rejected/suspended/incomplete; leave via `go('/')`; no Login embed
- PHASE3_RESULTS.md rewritten; Traceability Matrix updated
- Manual Phase 2+3 marked honestly (device not run)

### Deploy
None.

### Result
Code + unit: PASS. Device QA: open.

---

## 2026-07-28 — Phase 7 Register OTP

### What
- `DriverPhoneOtpService` (send + credential without sign-in)
- Regdrever: OTP gate after step 0; link phone after email create
- PHASE7_RESULTS.md
- i18n OTP dialog keys

### Blocker note
SMS delivery needs Firebase Phone Auth + SHA fingerprints on device.

### Deploy
None.

### Next
Phase 8–9 Auth/Firestore + Draft UX continue.

---

## 2026-07-28 — Phases 5–6 Login + Auth errors

### What
- `DriverAuthValidationService` + Login wired to it
- FirebaseAuthException → localized alerts
- Password reset generic success message
- PHASE5_RESULTS.md / PHASE6_RESULTS.md

### Tests
`driver_auth_validation_test` + auth_flow — pass

### Deploy
None.

### Next
Phase 7 — Register / OTP on `regdrever`

---

## 2026-07-28 — Phase 3 + 4 (legacy unify + splash/onboarding)

### Branch
`driver-production-completion`

### Phase 3
- `DriverLegacyFieldCompat` + LEGACY_FIELD_MAPPING.md
- Home / Accepted / Cansel / Completed use `DriverOnlineState` (not raw `actevMndob`)
- Eligibility no longer re-reads `actev_mndob`
- Online/receive-orders from lifecycle
- Tests: +42 passed (compat + resolver + routing + auth_flow)

### Phase 4
- AuthGate loading documented as Splash + Retry
- Onboarding: Back button; no Auth/Draft; mark done → re-bootstrap

### Deploy
None.

### Result
Phase 2 (prior) + Phase 3 + Phase 4 code gates **PASS**. Continue Phase 5 Login.

---

## 2026-07-28 — Phase 2 CLOSED (code gate)

### What
- Unified `DriverBootstrapService` + `DriverBootstrapResult` (no navigation inside service)
- `DriverAccountStateResolver` sole adapter for legacy fields → `DriverLifecycle`
- `DriverAuthGate` embeds destinations from bootstrap status; Retry on error
- `/` always AuthGate; Login/Reg/Logout → `context.go('/')`
- Anonymous cleared on main + bootstrap; no anon in reg flow
- `DriverLogoutService` offline + location stop + uid-scoped draft clear
- Unit/router tests: resolver, route matrix, conflicts (46 passed)
- Docs: `PHASE2_RESULTS.md`, `DEPRECATED_ROUTES.md`

### Why
Phase 1 proved anon + AuthGate bypass + conflicting flags caused Regdrever loops.

### Files (core)
- `lib/core/driver_bootstrap.dart`
- `lib/core/driver_account_state_resolver.dart`
- `lib/core/driver_session_router.dart`
- `lib/core/driver_logout_service.dart`
- `lib/components/driver_auth_gate.dart`
- `lib/flutter_flow/nav/nav.dart`
- `lib/login1/login1_widget.dart`
- `lib/regdrever/regdrever_widget.dart`
- `test/driver_account_state_resolver_test.dart`
- `test/driver_bootstrap_routing_test.dart`
- `docs/driver-completion/PHASE2_RESULTS.md`

### Tests
```
flutter test test/driver_account_state_resolver_test.dart \
  test/driver_auth_flow_test.dart \
  test/driver_bootstrap_routing_test.dart \
  test/driver_lifecycle_and_status_test.dart
→ All tests passed (+46)
```

### Deploy
**None.**

### Result
**PASS** Phase 2 code criteria. Device Clear-Data / Cold-Start QA still required locally.

### Next
Phase 3 — registration completeness (not orders/design polish).

---

## 2026-07-28 — Phase 2 root fix: `/` always DriverAuthGate

### Root cause proven
`nav.dart` used:
`loggedIn ? DriverAuthGate() : Login1Widget()`
So logged-out users **bypassed AuthGate** (no onboarding/anonymous policy), and anonymous `loggedIn` hit AuthGate inconsistently with draft restore paths.

### Fix
- `/` and `errorBuilder` → always `const DriverAuthGate()`
- Login + Regdrever success → `context.go('/')`
- Login init clears anonymous via `DriverBootstrap`

### Files
- `lib/flutter_flow/nav/nav.dart`
- `lib/login1/login1_widget.dart`
- `lib/regdrever/regdrever_widget.dart`

### Deploy
None.

### Tests
Device Hot Restart required next.


### What
- Re-read build.gradle, google-services.json, .firebaserc, nav.dart, user_record, customer locale
- Wrote `PHASE1_FINDINGS.md` with the 13 mandatory answers
- Refreshed `DRIVER_CURRENT_STATE.md`
- Starting Phase 2 file list from §13 without Production deploy

### Result
**PASS** Phase 1 evidence pack ready.


### What
- Identified production driver app = `mndob-main` only
- Firebase Project ID = `tutorial-multi-language-70gx4j` (all three apps)
- Packages: driver Android `com.mycompany.mndob2`, iOS `com.mycompany.mndob3`; customer `com.mycompany.araoatanapp`; admin `com.mycompany.tutorialmultilanguageapp`
- Created `docs/driver-completion/*` mandatory files
- Mapped screens, legacy routes, root failure causes from prior passes

### Why
Prior passes edited routing/auth repeatedly without a durable inventory or gate discipline, causing registration loops.

### Files
- `docs/driver-completion/DRIVER_CURRENT_STATE.md` (new)
- `docs/driver-completion/DRIVER_SCREEN_INVENTORY.md` (new)
- `docs/driver-completion/DRIVER_TRACEABILITY_MATRIX.md` (new)
- `docs/driver-completion/DRIVER_EXECUTION_LOG.md` (this)
- `docs/driver-completion/DRIVER_FINAL_QA.md` (new)

### Tests
- Discovery cross-check: pubspecs, google-services.json, .firebaserc, routeName grep
- Flutter 3.44.4 confirmed

### Result
**PASS** Phase 1 gate — proceed Phase 2.

### Remaining
Device confirmation of cold start → Login after Hot Restart.

---

## 2026-07-27 — Phase 2 Bootstrap (started)

### What (code already in tree + hardening this session)
- `DriverAuthGate`: never auto-open Regdrever; anonymous → Login; submitted drivers → Home
- `DriverLifecycleState`: submitted/isDriver → pendingApproval (not incomplete)
- `DriverSessionRouter`: incomplete → Login route; pending → Home shell
- Registration success → `HomeWidget` not pending↔reg loop
- Draft restore aborted if account already submitted

### Why
User reproduced: Pending shown then forced back to registration last step.

### Files
- `lib/components/driver_auth_gate.dart`
- `lib/core/driver_lifecycle_state.dart`
- `lib/core/driver_session_router.dart`
- `lib/regdrever/regdrever_widget.dart`
- `lib/driver_pending_approval/driver_pending_approval_widget.dart`
- `lib/backend/backend.dart` (no anonymous maybeCreateUser)

### Tests
- `flutter test test/driver_auth_flow_test.dart` — PASS (prior run)
- Device Hot Restart — **REQUIRED from operator**

### Result
Code gate ready; **device PASS pending**.

## 2026-07-27 — Phase 2 Bootstrap (continued)

### What
- `DriverBootstrap.clearAnonymousSession()` on `main()` after Firebase init
- First-launch `DriverOnboardingWidget` (once via SharedPreferences)
- AuthGate: Onboarding → Login → Home shell; never auto Regdrever

### Files
- `lib/core/driver_bootstrap.dart` (new)
- `lib/onboarding/driver_onboarding_widget.dart` (new)
- `lib/components/driver_auth_gate.dart`
- `lib/main.dart`
- `assets/langs/{ar,en,ru,ky}.json`

### Tests
- Device Hot Restart required for cold-start proof
- Unit auth tests already green

### Result
Phase 2 code complete pending device confirmation of:
1) First open / logged-out → Onboarding or Login  
2) After register → Home (not last reg step)  
3) Pending account reopen → Home shell not Regdrever

### Remaining
- Splash dedicated error screen
- Full button QA matrix execution
