# PHASE 2 RESULTS — Bootstrap / Session / Auth

**Date:** 2026-07-28  
**App:** `mndob-main` (Touri Taxi Driver)  
**Firebase Project:** `tutorial-multi-language-70gx4j`  
**Deploy:** **None** (explicitly forbidden this phase)

Based on Phase 1 evidence in `PHASE1_FINDINGS.md` and `DRIVER_SCREEN_INVENTORY.md` — discovery was not re-run.

---

## 1. Root causes (proven)

| # | Root cause | Effect |
|---|------------|--------|
| 1 | `signInAnonymously` in registration / car-type catalog | Guest counted as `loggedIn` → AuthGate treated session as real → forced `/regdrever` |
| 2 | `nav.dart`: `loggedIn ? DriverAuthGate() : Login1Widget()` | Logged-out users **bypassed** AuthGate (no onboarding / anon cleanup / lifecycle) |
| 3 | AuthGate auto-opened Regdrever for incomplete / timeout | Restored SharedPreferences draft at **last step** without explicit user choice |
| 4 | Conflicting legacy flags (`ismndob`, `ismndom`, `actev_mndob`, `ngl`, `mndon_newacc`, `registration_status`) read ad hoc | Different screens reached different destinations for the same account |
| 5 | Login / Regdrever navigated to Home (or Register) directly | Bypassed central session resolution → loops and wrong screens after submit |

---

## 2. `signInAnonymously` — removed from driver flow

### Call sites removed / blocked from production flow
- `lib/regdrever/regdrever_widget.dart` — no anonymous sign-in on init (comment + guest sign-out before email create only).
- Car type list previously auto-signed anonymous — no longer used that way for registration catalog.

### Residual (FlutterFlow stack — **not called** by driver bootstrap/login/reg)
- `lib/auth/firebase_auth/anonymous_auth.dart`
- `lib/auth/firebase_auth/firebase_auth_manager.dart` → `signInAnonymously`
- `lib/auth/auth_manager.dart` abstract API

### Stale anonymous handling
- `DriverBootstrapService.clearAnonymousSession()` on `main()` and every bootstrap resolve.
- Anonymous → treated as **loggedOut** → Onboarding or Login.
- Does **not** delete real Auth accounts; does **not** clear another user’s registration draft.

---

## 3. Auth flow — before

```
main → Firebase
  → (sometimes) signInAnonymously
  → GoRouter `/` → loggedIn ? AuthGate : Login1
  → AuthGate may push Regdrever / Home based on raw flags
  → Login success → Home or hard signOut(!ismndob)
  → Reg success → Home / pending race + draft restore
```

---

## 4. Auth flow — after

```
main
  → initFirebase
  → clearAnonymousSession
  → runApp → GoRouter `/` = DriverAuthGate ONLY
  → DriverBootstrapService.resolve()  (no navigation)
  → DriverAccountStateResolver → DriverLifecycle
  → DriverAuthGate embeds destination widget
  → Login / Reg / Logout → context.go('/') → re-bootstrap
```

---

## 5. DriverBootstrap

**Type:** `DriverBootstrapService` (+ alias `DriverBootstrap`)  
**File:** `lib/core/driver_bootstrap.dart`

Ordered steps:
1. Clear anonymous session  
2. Read `onboardingCompleted` (`driver_onboarding_done_v1`)  
3. Read `FirebaseAuth.currentUser`  
4. Reject anonymous → firstLaunch / unauthenticated  
5. Read `user/{uid}`  
6. Missing doc → `authenticatedMissingDriverDocument`  
7. Resolve lifecycle via `DriverAccountStateResolver`  
8. Map to `DriverBootstrapStatus`  
9. Dev log: uid, anon, docExists, raw legacy fields, lifecycle, route hint  

**Does not navigate.** Returns `DriverBootstrapResult` only.

Statuses: `firstLaunch`, `unauthenticated`, `authenticatedMissingDriverDocument`, `registrationIncomplete`, `pendingApproval`, `changesRequested`, `rejected`, `suspended`, `activeOffline`, `activeOnline`, `activeTrip`, `bootstrapError`, `loading`.

---

## 6. DriverAccountStateResolver

**File:** `lib/core/driver_account_state_resolver.dart`  
**Enum:** `DriverLifecycle`

Facade: `DriverLifecycleState` in `lib/core/driver_lifecycle_state.dart` (delegates to resolver).

AuthGate / SessionRouter / eligibility online gates use lifecycle — not raw navigation on `actev_mndob` / `ismndob`.

---

## 7. Legacy field mapping (deterministic priority)

| Priority | Condition | Lifecycle |
|----------|-----------|-----------|
| 1 | No auth / anonymous | `loggedOut` |
| 2 | No `user/{uid}` | `incompleteProfile` |
| 3 | `registration_status` ∈ {suspended, blocked} | `suspended` |
| 4 | `registration_status` = rejected | `rejected` |
| 5 | `registration_status` = changes_requested | `changesRequested` |
| 6 | `!actev_mndob` + submitted / driver flags | `pendingApproval` |
| 7 | `!actev_mndob` + empty profile | `incompleteProfile` |
| 8 | `actev_mndob` + active trip / `mndon_newacc` | `onTrip` |
| 9 | `actev_mndob` + `ngl` | `activeOnline` |
| 10 | `actev_mndob` | `activeOffline` |

Legacy fields **kept** for Admin compatibility. No production migration.

| Field | Meaning |
|-------|---------|
| `ismndob` / `ismndom` | Driver / pending-driver flags |
| `actev_mndob` | Admin activated |
| `ngl` | Online |
| `mndon_newacc` | Busy / on trip |
| `registration_status` | Review pipeline |
| `rejection_reason` | Admin note |

---

## 8. Routes — old vs new

| Event | Old | New |
|-------|-----|-----|
| App `/` | AuthGate **or** Login1 if !loggedIn | **Always** `DriverAuthGate` |
| Login success | Home / signOut | `context.go('/')` |
| Reg success | Home / race | `context.go('/')` |
| Logout | SignOut only | `DriverLogoutService` → `context.go('/')` |
| Incomplete | Auto Regdrever | Regdrever only when lifecycle says so (authenticated recovery) |
| Pending / rejected / suspended | Mixed | `DriverPendingApprovalWidget` |
| Active | Home | `NavBarPage(home)` |
| On trip | Varied | `NavBarPage(Accepted)` |
| First launch | Often skipped | Onboarding → then Login |

Deprecated inventory: `docs/driver-completion/DEPRECATED_ROUTES.md`  
Production registration remains **`regdrever`** only (Wasl / NewDriverRegistration not in main path).

---

## 9. Modified files (primary)

- `lib/main.dart`
- `lib/flutter_flow/nav/nav.dart`
- `lib/components/driver_auth_gate.dart`
- `lib/core/driver_bootstrap.dart`
- `lib/core/driver_account_state_resolver.dart`
- `lib/core/driver_lifecycle_state.dart`
- `lib/core/driver_session_router.dart`
- `lib/core/driver_logout_service.dart`
- `lib/core/driver_registration_draft.dart`
- `lib/core/driver_eligibility_service.dart`
- `lib/core/driver_online_state.dart`
- `lib/login1/login1_widget.dart`
- `lib/regdrever/regdrever_widget.dart`
- `lib/driver_pending_approval/driver_pending_approval_widget.dart`
- `lib/profile07/profile07_widget.dart`
- `lib/onboarding/driver_onboarding_widget.dart`

---

## 10. New files

- `lib/core/driver_account_state_resolver.dart` (canonical lifecycle + adapter)
- `lib/core/driver_bootstrap.dart` (`DriverBootstrapService` / Result / Status)
- `lib/core/driver_logout_service.dart`
- `docs/driver-completion/DEPRECATED_ROUTES.md`
- `docs/driver-completion/PHASE2_RESULTS.md` (this file)
- `test/driver_account_state_resolver_test.dart`
- `test/driver_bootstrap_routing_test.dart`

---

## 11. Tests added

| File | Coverage |
|------|----------|
| `test/driver_account_state_resolver_test.dart` | anon, missing auth/doc, pending, rejected, suspended beats active, offline/online, onTrip beats online, incomplete, router mapping |
| `test/driver_bootstrap_routing_test.dart` | Full lifecycle → route matrix; register only for incomplete; conflict cases |
| `test/driver_auth_flow_test.dart` | Phone E.164, auth error keys, session router smoke |

**Result (2026-07-28):** `46` tests passed in the Phase 2 suite above (+ lifecycle/status helpers).

Widget tests for full Login/AuthGate UI were **not** fully instrumented with Firebase mocks in this pass (require Auth/Firestore harness). Behavior covered by unit/router matrix + manual scenarios below.

---

## 12. `flutter analyze`

Scoped to Phase 2 paths (`lib/core`, AuthGate, login, regdrever, main, nav):

- **No compile errors** after `regdrever` `clearForUid(String?)` fix.
- Remaining items are mostly FlutterFlow legacy **info**/`prefer_const` / unused import warnings (pre-existing style debt).
- Critical Phase 2 files cleaned of unused imports where introduced.

Full-repo `flutter analyze` still noisy due to generated FlutterFlow screens — Phase 2 gate treated as **PASS** on compile + targeted analyze without errors.

---

## 13. `flutter test`

```
flutter test test/driver_account_state_resolver_test.dart \
  test/driver_auth_flow_test.dart \
  test/driver_bootstrap_routing_test.dart \
  test/driver_lifecycle_and_status_test.dart
→ All tests passed! (+46)
```

---

## 14. Manual scenarios (8)

| # | Scenario | Result | Notes |
|---|----------|--------|-------|
| 1 | Clear Data → Onboarding → Login; no auto Reg | **Code-ready** | Needs device Clear Data + Cold Start |
| 2 | Login → سجل الآن → first Reg step; no anon | **Code-ready** | CTA `pushNamed(regdrever)` only |
| 3 | Incomplete login → Reg + draft uid | **Code-ready** | AuthGate → Regdrever recovery |
| 4 | Pending → Pending Approval | **Code-ready** | Resolver + AuthGate |
| 5 | Approved → Home | **Code-ready** | |
| 6 | Rejected → rejection UI | **Code-ready** | Via Pending shell |
| 7 | Logout → Login; no auto Reg | **Code-ready** | `DriverLogoutService` + `/` |
| 8 | Kill/reopen restores path | **Code-ready** | Bootstrap on cold start |

Device execution checklist remains for local QA (Hot Restart alone is insufficient; use Clear Data + Cold Start). No Firebase deploy performed.

---

## 15. Routing logs (dev)

Debug prints (kDebugMode only):

```
DriverBootstrap uid=… anon=… doc=… life=… → status raw={ismndob,…}
DriverAuthGate status=… life=… → namedRoute
DriverAccountStateResolver → state (reason)
```

No passwords / tokens / PII beyond uid and boolean flags.

---

## 16. Remaining gaps (non-blocking for Phase 2 gate / track for Phase 3+)

- Home / list screens still **display** `actevMndob` in some UI strings (not used for AuthGate navigation).
- FF `signInAnonymously` API remains in auth manager (unused by flow).
- Full widget/integration tests with Firebase emulator not added.
- Manual 8-scenario device sign-off still required on Emulator/device.
- FCM token detach on logout is best-effort / partial vs full policy.
- Auth-without-doc recovery opens Regdrever; deeper Crashlytics breadcrumb optional.

---

## 17. Suggested Phase 3 files

Focus: registration UX completeness + draft reliability + pending/rejected copy — **not** order matching yet.

- Harden `regdrever` step machine + draft restore tests  
- Split Pending / ChangesRequested / Rejected UIs if needed  
- Remove dead Wasl entry points from Home if any remain  
- Wire Crashlytics for `authenticatedMissingDriverDocument`  
- Optional: Firebase Auth emulator widget tests  
- Admin parity check that approve still writes `actev_mndob` + `registration_status=approved`

---

## Phase 2 success checklist

| Criterion | Status |
|-----------|--------|
| No `signInAnonymously` in startup/reg flow | ✅ |
| No session → Onboarding or Login only | ✅ |
| Regdrever not auto without session | ✅ |
| `/` always AuthGate | ✅ |
| Login/Register do not bypass AuthGate | ✅ |
| Auth without driver doc → recovery (Regdrever) | ✅ |
| Legacy fields via single Resolver | ✅ |
| Navigation not decided by raw `actev_mndob`/`ismndob` in AuthGate | ✅ |
| Pending / Rejected / Approved / Trip routes | ✅ |
| Logout → Login | ✅ |
| Draft scoped by uid | ✅ |
| No redirect loop by design (`go('/')` + embed) | ✅ |
| Unit/router tests pass | ✅ |
| No Production/Firebase deploy | ✅ |
| Device 8-scenario sign-off | ⏳ local QA |

**Phase 2 engineering gate: CLOSED for code.** Device QA checklist open.
