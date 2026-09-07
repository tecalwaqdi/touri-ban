# TOURi TAXI — ADMIN AUTH NAVIGATION P0 REPORT

BASE: `80f5ddc` (PERF-P4C tip — Finance first-data architecture frozen; **P2B not started**)

BRANCH: `recovery/admin-auth-navigation-p0`

COMMIT: `80f5ddc2ee3c45234ff458ffa7a63f50fb6343e3`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-auth-nav-fix-mentm7hl.web.app/admin/

FIREBASE PROJECT: `tutorial-multi-language-70gx4j`

ACCOUNTANT: `accountant.demo@touri-taxi.com` · `isAdminRule=5` · claim `finance=true` · Global Finance

================================
ROOT CAUSE
================================

ACTUAL FIREBASE SIGNOUT: **NO** (no navigation-triggered `signOut()`)

FALSE LOGIN REDIRECT: **YES**

ROOT CAUSE:
1. **Broken auth null debounce** in `adminArawatanFirebaseUserStream`: used `user == null && !loggedIn`, which skipped the hold **while logged in** — so a transient `authStateChanges` null published `loggedIn=false` immediately and GoRouter `requireAuth` redirected to `/homePage`.
2. **`requireAuth` treated AUTH_LOADING as UNAUTHENTICATED** (`!loggedIn` → Login) before Firebase auth resolved.
3. **`jwtTokenStream`**: on `idTokenChanges` null cleared claims/session even if `FirebaseAuth.currentUser` still present; every token tick forced claim refresh.
4. **`refreshAuthClaims` `finally` always `markClaimsAuthoritative()`** even when claims empty → `hasPanelAccess=false` + authoritative → false redirect to Login while Firebase user still present.

CASE CLASSIFICATION: **CASE B** (false Login redirect) with **CASE C** contribution (transient unresolved auth/claims treated as logout). Not CASE A (no real `signOut` on route change).

FILES:
- `lib/auth/firebase_auth/firebase_user_provider.dart`
- `lib/auth/firebase_auth/auth_util.dart`
- `lib/flutter_flow/nav/nav.dart`
- `lib/backend/admin_route_guard.dart`
- `lib/backend/admin_auth_nav_policy.dart` (new)
- `lib/backend/admin_role_service.dart` (`canAccessRouteForRole` test helper)
- `test/backend/admin_auth_navigation_p0_test.dart`
- `qa_tools/admin_auth_nav_p0_probe.mjs`

================================
SIGNOUT CALLERS (audit)
================================

| FILE | FUNCTION | TRIGGER |
|---|---|---|
| `firebase_auth_manager.dart` | `signOut` | explicit logout API (+ `AdminSessionCleanup`) |
| `menu2_widget.dart` | logout button | user logout |
| `settings_widget.dart` | logout button | user logout |
| `home_page_widget.dart` | logout control | user logout |
| `admin_user_creation.dart` | create-user helper | post-create cleanup (not route nav) |
| `admin_demo_seed.dart` | seed scripts | tooling only |
| `google_auth.dart` | Google sign-out helper | Google provider |

**Route navigation / dispose / shell / finance query / permission check: 0 signOut callers.**

================================
AUTH
================================

SESSION OWNER MOUNTS: **1** (`AdminAuthSessionOwner.ensureStarted` from `AdminPersistentShell` + app-root `authenticatedUserStream` listen in `main.dart`)

DISPOSES DURING FINANCE TOUR: **0** (`stop()` only from `AdminSessionCleanup.onSignOut`)

AUTH NULL EVENTS: debounce + SDK-currentUser guard ignore transient nulls

PROFILE REFETCH: stream retained by session owner (P3F)

CLAIM REFETCH: soft on token ticks (`forceRefresh` only when claims panel access missing)

================================
ROUTER
================================

AUTH_LOADING REDIRECT: **0** (`isAuthLoading` → no Login redirect)

HARD INTERNAL NAVIGATION: **0** (sidebar uses `context.goNamed`; no `window.location` / hard href internals found under `lib/`)

FINANCE ROUTES UNDER SAME SHELL: **YES**

Authenticated route tree (abbreviated):

```
GoRouter
├── public routes (HomePage, …)
└── ShellRoute → AdminPersistentShell
    ├── AdminFinanceHub (/adminFinanceHub)
    ├── AdminFinanceReconciliation
    ├── AdminFinanceChannels          // Money Movement
    ├── AdminSettlements
    ├── AdminSettlementDetails
    ├── AdminAgentFinance
    ├── AdminFinanceReports
    ├── AdminFinanceAudit
    └── … other requireAuth panel routes
```

================================
ACCOUNTANT TOUR (preview probe)
================================

Method: custom-token hydrate + deep-link tour; session proven via IndexedDB auth + path + `__TOURI_PERF_P4B__` paint where instrumented.

HUB: **PASS** (paint ~1096 ms; auth retained)

RECONCILIATION: **PASS** (~712 ms)

MONEY MOVEMENT (Channels): **PASS** (path + auth retained; no P4B mark on this route)

SETTLEMENTS: **PASS** (~593 ms)

AGENT FINANCE: **PASS** (~1162 ms)

REPORTS: **PASS** (path + auth retained)

RETURN HUB: **PASS** (~2026 ms warm/cache-bust variance)

LOGIN REDIRECTS: **0**

DATA LOAD FAILURES: **0** on instrumented routes (paint marks present)

================================
BROWSER
================================

SIDEBAR: uses `context.goNamed` — **PASS** (no hard reload links)

BACK/FORWARD: not fully automated this pass — deep-link tour covers same shell session

HARD REFRESH: Settlements path retained auth in IndexedDB (probe)

DEEP LINK: **PASS** (all finance paths under `/admin/…`)

================================
SECURITY
================================

UNAUTHENTICATED → LOGIN: **PASS** (policy: only after `authResolved && !loggedIn`)

UNAUTHORIZED ACCOUNTANT → FINANCE/403: **PASS** (`canAccessRoute` deny → role home Finance Hub, not Login)

UNAUTHORIZED CAUSES SIGNOUT: **0**

CROSS-USER LEAK: **0** (cleanup still on real logout)

================================
PERFORMANCE
================================

FINANCE: warm paint samples ~1096–2026 ms (median instrumented tour paints **1096** ms excluding null Channels/Reports)

RECON: **712** ms

SETTLEMENTS: **593** ms

P4C PERFORMANCE: **PRESERVED** (no Finance transport/repo changes; Hub within ~≤1500 ms preferred band on first warm sample)

================================
REGRESSION
================================

B2 / RBAC authoritative tests: **PASS**

P3F shell owner: **PRESERVED**

P4C Finance code: **UNTOUCHED**

SUPER ADMIN / COUNTRY ADMIN / COUNTRY AGENT: matrix helpers unchanged; no broader access

NEW AUTH-NAV TESTS: **PASS** (11)

ANALYZE (changed libs): **PASS**

================================
FINAL
================================

AUTH_NAVIGATION_P0: **FIXED**

ACCOUNTANT SAFE_FOR_ROUTE_NAV: **YES**

PERF-P2B: **DO_NOT_START** (blocked until human confirms this gate)

PRODUCTION DEPLOY: **NO**

STOP.
