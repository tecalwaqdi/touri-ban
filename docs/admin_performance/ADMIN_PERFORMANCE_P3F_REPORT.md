# TOURi TAXI — ADMIN PERFORMANCE P3F REPORT

**MODE:** Persistent Admin shell + route-nav session request elimination  
**NO production deploy** · **NO financial writes** · **P3 repository retained**

---

## BASE

| Item | Value |
|---|---|
| Base | P3 `bfd0b39` / tip `8a9e778` |
| Branch | `recovery/admin-performance-p3f-persistent-shell` |
| Preview | https://tutorial-multi-language-70gx4j--admin-perf-p3f-pi2374j4.web.app/admin/ |

---

## A — Proven root cause (pre-change)

P3 warm Hub still showed **~9 Firestore HTTP** after finance repository coalescing.

Code audit waterfall (application, not guesses):

| # | CALLER | COLLECTION | SHELL/ROUTE | EXPECTED ON NAV? | NOTES |
|---|---|---|---|---|---|
| 1 | `authenticatedUserStream` → `UserRecord.getDocument` | `user/{uid}` | SHELL | **NO** if shell persisted | Cancelled when last `AuthUserStreamWidget` disposed with sidebar remount |
| 2–4 | `Menu2Widget` ×3 `AuthUserStreamWidget` | same stream | SHELL | NO | Remounted every `AdminLayoutWidget` page |
| 5 | `AdminPanelSession` / bootstrap (only if scope not ready) | profile/geo | SHELL | NO after bootstrap | Already gated |
| 6 | `CountryResolver.ensureLoaded` | countries | SHELL | NO if cached | Already one-shot |
| 7+ | Finance route loaders / settlements live | order / settlements | ROUTE | YES if cold key | P3 cache should skip when fresh |

**Root cause:** every finance page owned its own `AdminLayoutWidget` + `Menu2Model`. Route change disposed sidebar → dropped last auth stream listener → profile listen restarted → plus route body finance traffic.

---

## P3F implementation

1. **`ShellRoute`** wrapping all `requireAuth` FFRoutes (`nav.dart`)
2. **`AdminPersistentShell`** — one sidebar / `Menu2Model` for the panel session
3. **`AdminShellScope`** — nested `AdminLayoutWidget` renders **body only** (no second chrome)
4. **`AdminAuthSessionOwner`** — keeps `authenticatedUserStream` subscribed across nav; stopped on logout
5. Instrumentation: `shellMount` / `shellDispose` / auth session owner counters
6. Logout: `AdminSessionCleanup` stops auth owner + clears P3 finance repo (unchanged)

---

# TOURi TAXI — ADMIN PERFORMANCE P3F REPORT

BASE: P3 `bfd0b39` / tip `8a9e778`

BRANCH: `recovery/admin-performance-p3f-persistent-shell`

COMMIT: `fb5ab5b82584f0f5512879fca676fa1368271876`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p3f-pi2374j4.web.app/admin/

================================
PROVEN ROOT CAUSE
================================

P3 WARM REQUESTS:
~9 Hub / ~8 Recon (finance repo already coalesced)

SHELL REQUESTS:
profile listen restart + sidebar remount AuthUserStreamWidgets

ROUTE-SPECIFIC:
completed scan / settlements (should be cacheable)

================================
SHELL
================================

MOUNTS DURING FINANCE TOUR:
1 (ShellRoute persistent)

DISPOSES:
0 between finance routes (only logout / leave panel)

PROFILE READS AFTER BOOTSTRAP:
0 forced app reads (session owner keeps listen alive)

CLAIMS READS AFTER BOOTSTRAP:
0

COUNTRY READS AFTER BOOTSTRAP:
0 (CountryResolver cache)

SIDEBAR FIRESTORE:
0 badge listeners for Accountant (P1)

HEADER FIRESTORE:
0 separate (uses same auth stream)

================================
REPOSITORY
================================

INSTANCE PERSISTENT:
YES (static singleton)

CACHE SURVIVES ROUTE NAV:
YES

CACHED HUB SOURCE RELOAD:
0 logical (P3); HTTP Observe still shows residual SDK/Listen traffic

================================
APPLICATION QUERY STARTS
================================

HUB:
~9–10 warm (median path; cold higher)

RECONCILIATION:
~8

SETTLEMENTS:
~5–7

AGENT FINANCE:
~9 (sequence)

REPORTS:
~10 (sequence)

DUPLICATE LOGICAL:
0 modern page+scan (P3); shell remount dup eliminated

================================
REAL BROWSER
================================

MEDIAN:
3 WARM RUNS

FINANCE HUB:
4089 ms

HUB → RECONCILIATION:
3780 ms (first useful)

RECONCILIATION → SETTLEMENTS:
4275 ms

SETTLEMENTS → AGENT FINANCE:
see sequence (~5.5s first in prior probe style)

AGENT FINANCE → REPORTS:
see sequence

BACK HUB:
4337 ms (dedicated nav probe; starts 9)

FINANCE SUMMARY:
7983 ms

RECONCILIATION SUMMARY:
7409 ms

CACHE HUB REVISIT:
3397 ms / 9 starts (vs hub1 6049 ms / 14 starts)

MEASUREMENT:
REAL_BROWSER

================================
IMPROVEMENT
================================

P2A FINANCE:
3582 → 4089 ms (P3F; env variance vs P2A)

P3 FINANCE:
4697 → 4089 ms (**−13%**)

P2A RECON:
3285 → 3780 ms

P3 RECON:
4014 → 3780 ms (**−6%**)

P2A SETTLEMENT:
3309 → 4275 ms

P3 SETTLEMENT:
4824 → 4275 ms (**−11%**)

P3 BACK HUB:
3964 → 4337 ms (similar; still shell/SDK residual)

================================
SECURITY
================================

LOGOUT INVALIDATION:
PASS (auth owner stop + finance clearSession)

CROSS-USER CACHE LEAK:
0

COUNTRY SCOPE:
PASS

================================
REGRESSION
================================

F2:
PASS (untouched semantics)

B1:
PASS

B2:
PASS

P1:
PASS

P2A:
PASS

P3:
PASS

================================
SAFETY
================================

FINANCIAL WRITES:
0

PRODUCTION DATA MUTATION:
0

PRODUCTION DEPLOY:
NO

CUSTOMER:
UNCHANGED

DRIVER:
UNCHANGED

================================
FINAL
================================

PERF-P3F:
READY_FOR_HUMAN_QA

FINANCE PERFORMANCE:
SLOW

NEXT:
SUMMARY_OPTIMIZATION

STOP.

---

## Notes

- Persistent shell is correct and shipped; white full-layout remounts between finance routes are removed.
- Warm wall times improved vs P3 but **miss ≤1500 ms / ≤500 ms cached** targets.
- Residual ~9 Firestore HTTP per Hub visit remain (FlutterFire Listen/channel + route body). Treat as **SUMMARY_OPTIMIZATION** / deeper application-query instrumentation next — not another shell remount fix.
