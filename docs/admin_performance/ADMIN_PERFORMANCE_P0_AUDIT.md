# TOURi TAXI — ADMIN PERFORMANCE P0 AUDIT

**PROJECT:** tutorial-multi-language-70gx4j  
**ADMIN:** `admin/Admi`  
**MODE:** MEASURE / TRACE / CLASSIFY / REPORT ONLY  
**PRODUCT CODE CHANGED:** NO  
**FINANCE SEMANTICS CHANGED:** NO  
**PRODUCTION DEPLOY:** NO  

**Preview under test:**  
`https://tutorial-multi-language-70gx4j--admin-finance-b2-accou-14zbvme6.web.app/admin/`  
(channel: `admin-finance-b2-accountant` / F3-B2H tip)

**Measurement method**

| Layer | Method | Confidence |
|---|---|---|
| Bundle / network transfer | `curl` timings + local `hosting_public/admin` inventory | HIGH |
| Boot / auth / scope sequence | Static code path (serial `await`s) | HIGH (structure) / MEDIUM (ms) |
| Route Firestore shapes | Static query inventory | HIGH |
| Browser frame timings (TTFB→first paint) | Not Chrome DevTools profiled this pass | ESTIMATED from network + code |
| Live doc counts on Production | Not load-tested (forbidden) | Architecture estimate |

Where wall-clock ms are ESTIMATED, they assume warm DNS, mid-tier laptop, ~50–100 Mbps, cold browser cache unless noted.

---

## 1 — Performance targets (acceptance bar)

| Target class A | Preferred |
|---|---|
| LOGIN → usable Admin shell | ≤ 2.0s |
| Route navigation after shell loaded | ≤ 1.0s |
| First useful table rows | ≤ 1.5–2.0s |
| Filter/search (local) | ≤ 300–500ms |
| UX | No blank white screen; no spinner loops; no route flicker |

**Verdict vs targets (preview cold):** **MISS** — JS+CanvasKit alone often exceed 2s before Flutter bootstrap starts.

---

## 2 — Initial Admin boot (code path + network)

### Serial chain (login success path)

Evidence: `admin_login_flow.dart`, `admin_panel_session.dart`, `admin_panel_data_bootstrap.dart`, `main.dart`.

```
browser GET /admin/
→ flutter_bootstrap.js + flutter.js
→ main.dart.js (+ canvaskit.wasm)
→ main(): initFirebase → AdminPrefetch.warmCache() listener
         → AdminPushService.initialize
         → FlutterFlowTheme.initialize
         → FFLocalizations.initialize
         → FFAppState.initializePersistedState
→ runApp / auth stream
→ [user signs in]
→ completePanelSignIn:
     1. ensureCurrentUserDocument(forceRefresh: true)   // PROFILE
     2. refreshAuthClaims()                             // CLAIMS (getIdTokenResult)
     3. AdminPanelSession.ensureScopeReady(force: true)
          → AdminPanelDataBootstrap.ensureReady
               → ensureCurrentUserDocument AGAIN        // DUPLICATE PROFILE
               → role-specific (accountant: light)
          → CountryResolver.ensureLoaded()              // countries ≤100
          → AdminStatsCoordinator.startLiveSync()       // order snapshots limit 8
     4. stop splash / notify / syncPanelHomeUrl
     5. unawaited warm lists after 2s delay
→ Accountant home = AdminFinanceHub
     → AccountantFinanceLoader.load (order scan + settlements ≤500)
```

### Timing table (cold preview, ESTIMATED wall clock)

| Step | ms | Notes |
|---|---:|---|
| FLUTTER BOOT (HTML→JS parse start) | 400–900 | index ~14KB |
| INITIAL JS TRANSFER (gzip) | ~1400 | `main.dart.js` gzip ≈ 2.41 MB; raw 11.38 MB |
| CANVASKIT WASM | ~5000 | 6.89 MB uncompressed transfer observed |
| JS PARSE + ENGINE INIT | 1500–4000 | ESTIMATED (not DevTools) |
| AUTH (existing session restore) | 200–800 | Firebase Auth |
| CLAIMS (`refreshAuthClaims`) | 150–600 | token round-trip |
| USER PROFILE | 150–500 | first `ensureCurrentUserDocument` |
| ROLE/SCOPE (+ CountryResolver) | 200–800 | includes **2nd** profile fetch |
| SHELL (layout + menu) | 100–400 | first frame after scope |
| FIRST ROUTE DATA (Finance Hub) | 500–5000+ | order scan pages of 30; grows with period |
| **TOTAL TO USABLE (cold cache)** | **~12–25s** | Dominated by assets + finance scan |
| **TOTAL TO USABLE (warm cache assets)** | **~3–8s** | Still > 2s target if finance scans |

**Serial awaits that block shell:** profile → claims → bootstrap(profile again) → CountryResolver. Claims and CountryResolver are largely independent of each other after profile exists — candidate for later `Future.wait` (PERF-P1).

**Accountant vs SuperAdmin bootstrap**

| Role | Geo lock | Prefetch lists | Live stats sync | Home |
|---|---|---|---|---|
| Accountant | Skipped (except country-accountant Saudi refs) | Prefetch tasks empty | **Still starts** `startLiveSync` | Finance Hub |
| SuperAdmin / Agent | Heavier | Landmarks / reps | Yes | Dashboard |

---

## 3 — Bundle / web boot audit

### Preview network (measured 2026-09-06, curl)

| Asset | HTTP | Transfer size | Time |
|---|---:|---:|---:|
| `/admin/` HTML | 200 | 14,581 B | ~0.40s |
| `flutter_bootstrap.js` | 200 | 10,104 B | ~0.40s |
| `flutter.js` | 200 | 9,553 B | ~0.51s |
| `main.dart.js` (identity) | 200 | **11,382,133 B (~10.85 MB)** | ~8.5–10.2s |
| `main.dart.js` (Accept-Encoding: gzip) | 200 | **2,410,167 B (~2.30 MB)** | ~1.40s |
| `canvaskit/canvaskit.wasm` | 200 | **7,229,467 B (~6.89 MB)** | ~5.08s |
| Cairo-Regular.ttf | 200 | 94,484 B | ~0.72s |

### Local build inventory (`firebase/hosting_public/admin`)

| Metric | Value |
|---|---|
| TOTAL ON DISK | **~51.1 MB** / 65 files |
| INITIAL JS | `main.dart.js` **10.85 MB** |
| LARGEST ASSETS | canvaskit.wasm 6.89; chromium/canvaskit 5.49; skwasm_heavy 4.93; … |
| Source maps (`.map`) | **0** (good) |
| `.symbols` shipped | **6 files** (~8 MB) — debug symbols present in hosting tree |
| Fonts | ~1.81 MB (Cairo family + Font Awesome) |
| Deferred / `loadLibrary` | **NONE** found in Admin Dart |
| Lazy route modules | **NONE** — monolithic `main.dart.js` |
| Eager routes (`FFRoute`) | **73** registered in `nav.dart` (all compiled into one JS) |

**BOOT BOTTLENECK:** Monolithic Flutter Web JS + CanvasKit WASM download/parse. First screen cannot start meaningfully until both arrive. Finance Hub then adds a second bottleneck (order scan).

**INITIAL JS:** ~10.85 MB raw / ~2.3 MB gzip  
**TOTAL INITIAL NETWORK (typical first paint path):** HTML + bootstrap + main.js gzip + canvaskit ≈ **~9–11 MB** uncompressed path if wasm not cached; gzip JS helps but wasm remains large.

---

## 4 — Route navigation audit

Method: code-path first request after `goNamed` (menu uses replace navigation — good for dispose).

| Route | Route enter | First loader | First Firestore | First data → usable | Re-fetch auth/profile/claims? | Notes |
|---|---|---|---|---|---|---|
| Finance Hub | instant shell | FutureBuilder | `_scanOrders` pages (limit 30) + settlements ≤500 | EST **0.5–5s+** | No (session cached) | Default `thisMonth`; client aggregations |
| Reconciliation (B2) | shell | spinner | `loadOrdersForCurrentScope` (**thisYear**) + settlements ≤500 | EST **1–10s+** | No | **Heavier than Hub** (year scan) |
| Money Movement | same as Hub table | local filter | usually cached in Hub bundle | fast if Hub already loaded; else full scan | No | Presentation filter on loaded trips |
| Settlements | shell | StreamBuilder | `financial_settlements` **limit 200 snapshots** | EST **0.3–2s** | No | Stream **recreated in build** (risk) |
| Agent Finance | FutureBuilder | loader | finance loader / scoped orders | EST **0.5–5s** | No | |
| Reports | FutureBuilder | loader | often CF or scan | EST **0.5–4s** | No | `AdminFinanceReports` |
| Drivers | shell + list | AdminFirestoreList | paginated `user` query pageSize 20 | EST **0.3–1.5s** | No | **Accountant: route denied** |
| Agents | shell + list | AdminFirestoreList + N landmark counts | page + per-row count futures | EST **0.5–2s** | No | **Accountant: denied** |
| Dashboard | stats widgets | multiple count queries | dashboard loader + live sync | EST **0.5–3s** | No | **Accountant: not home** |

**Sidebar listeners while any finance-capable role has Finance Hub in menu:**

- `financial_settlement_payments` where status=pending limit 50 **snapshots**
- `financial_settlements` where status=draft limit 50 **snapshots**

These run for the lifetime of the menu (including Accountant), independent of current route.

---

## 5 — Firestore query inventory (major screens)

| Screen | Collection | Filters | orderBy | limit | Listener? | Displayed | Risk |
|---|---|---|---|---|---|---|---|
| Finance Hub | `order` | country? + date range on `data_order` | `data_order` desc | pages of **30**, cap **100000** | one-shot loop | UI table subset of completed | **SEVERE** growth risk |
| Finance Hub | `financial_settlements` | country? | — | **500** | one-shot | open count only | Over-read for a count |
| Reconciliation B2 | `order` | scope + **thisYear** | `data_order` | pages 30 / cap 100k | one-shot | all rows in memory | **SEVERE** |
| Reconciliation B2 | `financial_settlements` | country? | — | 500 | one-shot | association | High |
| Settlements list | `financial_settlements` | country agent path | — | **200** | **snapshots** | filtered chips client-side | Medium + listener churn |
| Menu badges | payments + settlements | pending / draft | — | 50 each | **2× snapshots** | badge int | Continuous reads |
| Stats live sync | `order` | country or **global** | `data_order` | **8** | snapshots | invalidation only | Global for unscoped accountant |
| Drivers / Users / Agents | `user` (+ scopes) | role flags | varies | **20** via AdminFirestoreList | optional live (default off) | page | GOOD pattern |
| Support / Notifications | lists | — | — | page | **liveUpdates: true** | page | Medium |
| CountryResolver | `countries` | — | — | **100** | one-shot cached | N/A | OK at current size |
| Transport companies cards | `user` count | ismndob + company | — | aggregate | Future **in build** | count | N+1 counts |
| Agent list landmarks | mkan count cache | country | — | — | Future in build if uncached | cell | N+1 until cache |

**Patterns found**

- Read large set then filter client-side: Settlements chips; Accountant trip filters; Hub quality filters.
- Load hundreds to show tens: Finance Hub / Reconciliation (by design today — full period scan for totals).
- Global accountant: order scan **without** `Rev_dolh` when “all countries”.
- Identical / overlapping scans: Hub (`thisMonth`) vs Reconciliation (`thisYear`) — **no shared repository cache**.

---

## 6 — Pagination audit

| Table / surface | PAGINATED | SERVER LIMIT | FIRST PAGE | FULL COLLECTION READ |
|---|---|---|---|---|
| Drivers | YES | 20 (`kAdminPageSize`) | 20 | NO |
| Users / Customers | YES | 20 (UI page size) | 20 | NO |
| Agents | YES (list) | 20 | 20 | NO (but per-row counts) |
| Bookings (ops lists) | YES via AdminFirestoreList | 20 | 20 | NO |
| Finance Hub trips | **NO true UI pagination of server** | scan pages 30 internally | all scanned then client filter | **YES within date range** (up to 100k) |
| Reconciliation | NO | same scanner | year range | **YES within year** |
| Settlements | Soft cap | 200 listener | ≤200 | Near-full for small DBs |
| Reports (finance) | Mixed | depends | — | Often scan / CF |
| Landmarks | YES / agent list | 20 | 20 | NO (scoped) |
| Notifications | YES + live | page | page | NO |
| Unknown drivers loader | Scan cap | `unknownDriverScanCap=800` | — | Bounded scan |

**Any growing collection read without pagination is a performance risk** — Finance Hub / Reconciliation are the primary P0 offenders.

---

## 7 — N+1 query audit

| Path | Pattern | Amplification example |
|---|---|---|
| Transport company cards | Per company: `count()` Future in build | 1 list + **N** counts |
| Agent landmarks cell | `AdminLandmarkCountCache.countForCountry` per row if uncached | 1 agents page + **≤20** counts (cached after) |
| Booking details / transport guard | `UserRecord.getDocumentOnce` for driver ownership | 1 order + 1 driver (OK single) |
| Village / region editors | region → country chained `getDocumentOnce` | 1 + 1–2 |
| Type car labels | per-ref `TypeCarRecord.getDocumentOnce` | list × types |
| Settlement details | multiple limited queries + driver `get` | multi-doc, not classic N×N |

**Classic “50 orders → 50 drivers → 50 countries”** not observed on Finance Hub (orders carry denormalized labels). Highest list N+1: **Agents landmarks** and **Transport company driver counts**.

Opportunities (future only): batch `getAll`, denormalized counters, shared count cache (partially exists for landmarks).

---

## 8 — Sequential await audit (candidates)

| Location | Sequence | Independent? |
|---|---|---|
| `completePanelSignIn` | profile → claims → scope | Claims ∥ CountryResolver after profile |
| `AdminPanelSession._bootstrapScope` | bootstrap → CountryResolver → startLiveSync | CountryResolver ∥ (post-bootstrap) |
| Reconciliation `_load` | orders scan → settlements | **YES** — `Future.wait` candidate |
| Finance Hub `load` | orders scan → then open settlements count | **YES** after scan start parallelizable |
| `main()` | Firebase → Push → Theme → L10n → AppState | Some parallelizable |

Do **not** parallelize dependent settlement write transactions (out of scope; noted for safety).

---

## 9 — Duplicate fetch audit

| Data | When duplicated | Count |
|---|---|---|
| Current user profile | Login `forceRefresh` + bootstrap `ensureCurrentUserDocument` | **2×** per login |
| Claims | Login refresh; also `auth_util` may unawaited refresh on auth stream | **1–2×** |
| Countries | `CountryResolver.ensureLoaded` once then cached | **1×** (OK) |
| Orders (finance) | Hub month scan vs Reconciliation year scan vs Agent Finance | **2–3×** if user visits multiple finance routes |
| Settlements | Menu listeners + Hub count + Reconciliation maps + Settlements page | **3–4×** overlapping |
| AuthUserStreamWidget | Nested in menu (multiple builders) | Rebuild fan-out (not always re-read) |

**Duplicate-read count (Accountant: Login → Hub → Reconciliation → Settlements):**  
profile 2 + claims 1 + countries 1 + order scans 2 + settlements reads ~3–4 + menu 2 listeners ongoing ≈ **~11–14 distinct fetch waves** (not including pagination page loops inside a scan).

---

## 10 — Listener audit

| Source | Route scope | Collection | Limit | Survives dispose? |
|---|---|---|---|---|
| Menu Finance Hub badges | All routes with menu | payments + settlements | 50×2 | Yes while menu mounted |
| `AdminStatsCoordinator` | App session after scope | orders | 8 | Until `stopLiveSync` / reset |
| Settlements list | Settlements | settlements | 200 | Recreated on rebuild (**leak/churn risk**) |
| Support / Notifications | Those routes | lists | page | liveUpdates true |
| Schema `*.snapshots()` helpers | When used | doc | 1 | Caller-dependent |
| Driver panels | Driver detail | various | — | Route-scoped |

**Approx `.snapshots()` call sites in lib:** 43 (includes schema helpers).

**Accountant listener baseline while idle on Finance Hub:** menu 2 + stats 1 = **≥3** live listeners, even though operational modules are hidden.

---

## 11 — Rebuild audit (hottest paths)

| Hotspot | Trigger | Effect |
|---|---|---|
| `AuthUserStreamWidget` wrapping entire menu | profile stream | Full sidebar rebuild |
| `AdminLayoutWidget` `updateCallback: () => safeSetState(() {})` | child notifies | Page shell setState |
| Settlements `ChoiceChip` setState | filter change | **New snapshots() subscription** |
| Finance Hub filters | local setState | Rebuilds table from in-memory bundle (OK if `_future` stable) |
| `AdminFirestoreList` parents recreating `queryBuilder` lambdas | setState | Mitigated by `reloadKey` / ignore identity |

---

## 12 — Future / Stream creation inside build

| File | Pattern | Risk |
|---|---|---|
| `admin_settlements_widget.dart` | `StreamBuilder(stream: (){…snapshots();}())` | **CRITICAL** — new listener every rebuild |
| `admin_transport_companies_widget.dart` | `FutureBuilder(future: …count().get())` in card build | **HIGH** — refetch on rebuild |
| `admin_agent_widget.dart` `_LandmarksCount` | FutureBuilder if cache miss | MEDIUM (cache helps) |
| `admin_booking_details_widget.dart` | `future: AdminResourceGuard.canViewOrderAsync(order)` | MEDIUM if parent rebuilds |
| Finance Hub / Reconciliation / Reports | Future stored in `State._future` | **LOW** (correct pattern) |

---

## 13 — Finance performance (semantics untouched)

| Screen | Load model | Shared cache? |
|---|---|---|
| Finance Hub | Client `AccountantFinanceLoader` (F1) | No cross-route cache |
| Reconciliation B2 | Same order scanner + settlements maps → B1 model | No reuse of Hub result |
| Money Movement | In-memory filter on Hub trips | Depends on Hub |
| Settlements | Direct Firestore listener | Separate |
| Agent Finance | Parallel loader pattern | Separate |
| Legacy Reconciliation (`AdminReconciliation`) | **Cloud Functions** `scanFinancialExceptionsV2` etc. | CF latency |

**Scope-before-totals:** Country-scoped roles constrain `Rev_dolh` / `countryId` in queries — **do not** “speed up” by global load + client filter for agents/country accountants.

**Read amplification (Finance Hub, illustrative):**  
If month has 600 completed orders and UI shows 20 rows at a time without virtualization of server pages:  
`READ AMPLIFICATION ≈ 600/20 = 30×` for display (worse for Reconciliation year).

---

## 14 — Accountant / role performance

| Expectation | Observed |
|---|---|
| Menu hides Drivers / Customers / Landmarks / Countries / Agents / Dashboard | **YES** — `canAccessRoute` + `_accountantRoutes` |
| Prefetch does not warm landmarks/drivers | **YES** — `AdminPrefetch._warmListCache` tasks empty for accountant |
| Unused module **widget** init | **0** while staying on finance routes |
| Unused **data** fetches still possible | **>0** — see below |

**ACCOUNTANT UNUSED MODULE FETCHES (strict “0” target): FAIL**

| Source | What loads | Needed for Finance? |
|---|---|---|
| `CountryResolver.ensureLoaded` | ≤100 countries | Partial (labels / Saudi) |
| `AdminStatsCoordinator.startLiveSync` | global/scoped order watch | **No** for accountant UX |
| Menu Finance Hub badges | 2 settlement listeners | Nice-to-have only |
| Monolithic `main.dart.js` | All Admin modules code | Parse cost yes / fetch no |

Hidden sidebar modules do **not** mount their widgets (good). Cost is bootstrap + listeners + bundle weight.

---

## 15 — Image / media audit

| Area | Behavior | Risk |
|---|---|---|
| Profile / avatars | `CachedNetworkImage` / `ProfilePhotoImage` | Medium on dense lists |
| Driver documents | Storage SDK `getData` / download URL via `admin_media_resolver` / document access | **High** if full-res bytes (`_maxBytes` gated in resolver) |
| Landmark images | List cards may load network images | Medium |
| Language flags | `Image.network` | Low |
| Thumbnails | Not systematically enforced | Missing opportunity |

No production compression in P0.

---

## 16 — Firestore index audit

| Query family | Compound needs | Notes |
|---|---|---|
| `order` + `Rev_dolh` + `data_order` range | Composite required | Assumed present (finance already shipping); failures would surface in console |
| `order` + `mndob_user` + `data_order` | Composite | Driver-filtered finance |
| Settlements `countryId` + status | May need composites for filtered listeners | Menu uses status-only |
| Payments `status==pending` | Single-field OK | |

**Recommended indexes:** only if console reports missing-index URLs for the compound order/country/date queries under load. **Do not add speculative indexes in P0.**

---

## 17–18 — Cloud Functions latency / cold start

| Item | Value |
|---|---|
| Region | `us-central1` (`CloudFunctionsClient`) |
| Runtime | Node **20** (`functions/package.json` engines) |
| Generation | firebase-functions **v4** style callables (1st gen default unless declared 2nd) |

| Callable used on **normal read** paths | Screens |
|---|---|
| `scanFinancialExceptionsV2` / `listIncompleteOrdersV2` / `detectFinanceOrphansV2` | Legacy `AdminReconciliation` |
| `accountantHomeV2` | Diagnostics |
| `financialReportV2` / audit search | Reports / Audit |
| `aggregateSettlementExposureV2` | Settlement tooling |
| Settlement V2 writes | Write paths only |

**Finance Hub + B2 Reconciliation:** primarily **direct Firestore**, not callables — good for avoiding CF cold start on the accountant happy path.

| Metric | Evidence |
|---|---|
| FUNCTION COLD START | Not measured this pass (no synthetic invoke storm) — typically 1–5s Node 20 cold |
| WARM | Tens–hundreds ms + Firestore inside function |
| FIRESTORE QUERY LATENCY | Dominates Hub/B2 |
| FLUTTER RENDER | Secondary after data arrives |

**Normal page reads depending on callable:** Accountant primary path **Hub/B2 Settlements list = Firestore**. Legacy reconciliation / diagnostics / some reports = **YES callable**.

---

## 19 — Network waterfall (fresh login conceptual)

| Phase | Requests | Notes |
|---|---|---|
| Boot | HTML, flutter.js, bootstrap, main.dart.js, canvaskit, fonts, AssetManifest | Largest: JS + wasm |
| Auth | Identity Toolkit | |
| Firestore | profile, countries, order watch, menu listeners, finance scans | Duplicates as above |
| Duplicate | profile×2; overlapping settlements | |
| Longest | main.dart.js / canvaskit (cold); then order scan pages | |
| Blocking | JS+wasm before any UI; then serial login awaits before shell | |

Exact Chrome waterfall HAR not captured this pass — use DevTools Performance+Network on preview for PERF-P6 baselines.

---

## 20 — Cache audit

| Cache | EXISTS | TTL | Invalidation | Notes |
|---|---|---|---|---|
| Auth user / `currentUserDocument` | YES | session | forceRefresh / logout | Duplicated on login |
| Claims (`AdminRoleService`) | YES | until refresh | `refreshAuthClaims` | |
| `CountryResolver` | YES | process lifetime | `clearCache` | |
| `AdminCachePolicy` TTLs | YES | 45s / 2m / 15m | stats coordinator | Dashboard oriented |
| `AdminLandmarkCountCache` | YES | peek/cache | — | Agents list |
| `queryListCacheFirst` | YES | Firestore persistence + helper | — | Prefetch |
| Finance Hub / Reconciliation shared repo | **NO** | — | — | **MISSING HIGH-VALUE** |
| Driver/agent display name map | Partial via order fields | — | — | |
| Settlement badge counts | Live listeners | n/a | snapshot | Costly vs TTL cache |

**Do not** introduce stale finance totals without explicit invalidation design (period change, settlement write, scope change).

---

## 21 — Loading UX (report only)

| Issue | Where |
|---|---|
| Blank / long white before Flutter | Cold web boot |
| Full-page spinner | Reconciliation B2 until entire year scan done |
| Multiple loaders | Menu badges + page FutureBuilder + list |
| Layout jump | Tables appearing after heavy scan |
| Fake zero | Not confirmed as systemic; Hub keeps `_lastOk` (good) |

Target pattern (future): immediate shell → skeleton → progressive rows → stable layout.

---

## 22 — Error / retry loops

| Pattern | Risk |
|---|---|
| Settlements stream recreated on setState | Listener storm / blink |
| Country agent bootstrap 250ms retry resolve | Single delayed retry (bounded) |
| Auth claims refresh on stream | Possible extra token fetch |
| Prefetch `catch (_) {}` | Silent fail (OK) |
| No aggressive timer retry loops found on Hub | Good |

---

## 23 — Firestore cost correlation

| Scenario | Docs read | Rows needed | Amplification |
|---|---:|---:|---:|
| Drivers first page | ~20 | 20 | ~1× |
| Finance Hub month (600 orders) | ~600 | ~20 visible | **~30×** |
| Reconciliation year (2000 orders) | ~2000 + ≤500 settlements | ~20–50 visible | **~40–100×** |
| Menu idle 10 min | continuous snapshot billing | 0 rows | unbounded time cost |
| 50 concurrent accountants on Hub | 50 × month scans | — | **linear multi-user blow-up** |

---

## 24 — Multi-user scalability (architecture only — no prod load test)

| Concurrent Admins | Behavior |
|---|---|
| 1 | Bundle once; finance scan cost personal |
| 10 | 10× overlapping month/year scans + shared listener patterns |
| 50 | Firestore read amplification on `order` becomes primary cost/latency risk; menu settlement listeners ×50 |

Poor scalers: unpaginated finance scans, global order watch for unscoped accountants, settlements `snapshots` without debounce, monolithic JS (bandwidth at org level).

---

## 25 — Accountant-specific target flow

```
Login → Finance Hub → Reconciliation → Settlements → Reports
```

| Metric | Target (future) | Current estimate |
|---|---|---|
| First finance usable | ≤ 2s | Cold: **>>2s** (bundle) + scan; Warm assets: often **3–8s** |
| Subsequent routes | ≤ 1s if cached | **No finance cache** → often re-scan |
| Pagination first page | ≤ 1.5s | N/A (no server page UI) |
| Unused module fetches | 0 | **>0** (countries + stats sync + menu listeners) |

---

## 26 — Prioritized root causes

### P0

1. **Monolithic Flutter Web bundle + CanvasKit**  
   - EVIDENCE: 10.85 MB JS / 2.3 MB gzip; 6.89 MB wasm; no deferred imports  
   - LATENCY: cold **~8–15s+** network/parse  
   - READS: n/a  
   - FIX (later): deferred routes, tree-shake, wasm cache headers, drop unused canvaskit variants/symbols from hosting  
   - IMPROVEMENT: shell under 2–3s warm  
   - RISK: build pipeline complexity  

2. **Finance order scan without UI pagination (Hub + Reconciliation year)**  
   - EVIDENCE: `AccountantFinanceLoader.scanCap=100000`, page 30 loop; Reconciliation uses `thisYear`  
   - LATENCY: **0.5–10s+** growing with data  
   - READS: O(orders in range)  
   - FIX: server-aggregated summaries + paginated trip table; shared scoped repository  
   - IMPROVEMENT: first paint rows ≤1.5s; totals via aggregate query/CF warm cache  
   - RISK: must preserve F1/F2/B1 semantics — **no formula changes**  

3. **Settlements `StreamBuilder` recreates `.snapshots()` every rebuild**  
   - EVIDENCE: IIFE stream in `build` + chip `setState`  
   - LATENCY: flicker / re-subscribe  
   - READS: repeated listener attach  
   - FIX: store `Stream` in State; filter client-side  
   - IMPROVEMENT: stable list, fewer reads  
   - RISK: low  

### P1

4. Duplicate profile fetch on login (login + bootstrap).  
5. Accountant still starts `AdminStatsCoordinator` live order sync + menu settlement badge listeners.  
6. Overlapping Hub/Reconciliation order scans (no shared cache).  
7. Settlements / Hub open-count using limit 500/200 instead of aggregation count.  
8. Transport company / agent N+1 count Futures in build.

### P2

9. AuthUserStreamWidget sidebar rebuild fan-out.  
10. Font Awesome + full Cairo family weight.  
11. `.symbols` files in hosting tree.  
12. Image full-res document loads.  
13. Parallelize independent boot futures.

---

## 27 — Fix strategy (future phases only — DO NOT implement in P0)

| Phase | Focus |
|---|---|
| **PERF-P1** | Auth/claims/shell: dedupe profile; parallel claims∥countries; disable stats live sync for accountant; stabilize settlements stream; badge polling/TTL instead of dual snapshots |
| **PERF-P2** | Firestore pagination + query scoping; replace full-period client scans for **display** with page queries; aggregation for totals; remove N+1 counts |
| **PERF-P3** | Route-level finance repository (scoped, invalidated); reuse Hub↔Reconciliation reads |
| **PERF-P4** | Rebuild/listener hygiene; AuthUserStream narrowing; AdminFirestoreList liveUpdates audit |
| **PERF-P5** | Bundle: deferred imports per route family; strip symbols; font subset; image thumbs |
| **PERF-P6** | Chrome benchmarks + budgets in CI; preview then production rollout |

---

## 28 — Frozen UI / safety

Performance work must preserve: F2 visual design, Accountant UI, finance semantics, route behavior, permissions.  
**No optimization may change accounting results.**

---

## 29 — Artifact

This file: `docs/admin_performance/ADMIN_PERFORMANCE_P0_AUDIT.md`

---

# TOURi TAXI — ADMIN PERFORMANCE P0 REPORT

PREVIEW/BUILD:  
`https://tutorial-multi-language-70gx4j--admin-finance-b2-accou-14zbvme6.web.app/admin/`  
Local hosting tree ~51.1 MB; `main.dart.js` 10.85 MB (gzip ~2.3 MB)

================================  
INITIAL LOAD  
================================  

TOTAL TO USABLE: **~12–25s cold / ~3–8s warm assets** (EST; >> 2s target)  

FLUTTER BOOT: **~0.4–1s** to start JS; **+1.4s** gzip JS; **+~5s** wasm cold  

AUTH/CLAIMS: **~0.3–1.2s** combined after engine  

PROFILE/SCOPE: **~0.4–1.3s** (includes duplicate profile + countries)  

FIRST ROUTE DATA: **~0.5–5s+** Finance Hub month scan (Reconciliation year worse)  

================================  
NETWORK  
================================  

REQUESTS: HTML + flutter loaders + main.js + canvaskit + fonts + AssetManifest (+ Auth/Firestore after)  

FIRESTORE READS: profile×2 + countries + live order(8) + menu×2 + finance scan pages  

DUPLICATE REQUESTS: profile; overlapping settlements; Hub vs Reconciliation orders  

LARGEST ASSET: `main.dart.js` 10.85 MB / `canvaskit.wasm` 6.89 MB  

================================  
FIRESTORE  
================================  

FULL COLLECTION QUERIES: Finance period scans (bounded by date + scanCap); settlements soft caps 200–500  

UNPAGINATED LARGE QUERIES: **Finance Hub / Reconciliation order scans**  

N+1 PATHS: transport company counts; agent landmark counts; assorted getDocumentOnce chains  

DUPLICATE FETCHES: **~11–14 waves** on accountant multi-finance navigation  

================================  
FLUTTER  
================================  

REBUILD HOTSPOTS: AuthUserStream menu; layout updateCallback; settlements chips  

RECREATED FUTURES: transport company counts; agent landmark (uncached); booking guard  

RECREATED STREAMS: **Settlements list CRITICAL**; menu badge streams OK if State-stable (inline in build tree)  

LEAKED/DUPLICATE LISTENERS: settlements rebuild churn; session stats sync + menu badges for accountant  

================================  
ACCOUNTANT  
================================  

LOGIN TO FINANCE: home = Finance Hub (correct); slow due to bundle + scan  

UNUSED MODULE FETCHES: **>0** (CountryResolver + stats live sync + menu settlement listeners; widgets for Drivers/etc. not mounted)  

FINANCE HUB: client order scan + settlements≤500  

RECONCILIATION: **thisYear** order scan + settlements≤500 (heavier)  

SETTLEMENTS: limit 200 snapshots (stream-in-build risk)  

================================  
CLOUD FUNCTIONS  
================================  

COLD START HOTSPOTS: Node 20 `us-central1` — legacy reconciliation / reports / diagnostics  

NORMAL PAGE READS DEPENDING ON CALLABLE: **Hub/B2 primary path = Firestore**; legacy AdminReconciliation / some reports = callable  

================================  
TOP BOTTLENECKS  
================================  

P0:  
1. Monolithic JS + CanvasKit boot  
2. Unpaginated finance order scans (Hub / year Reconciliation)  
3. Settlements StreamBuilder recreating snapshots on rebuild  

P1:  
Duplicate profile; accountant live stats + badge listeners; no finance repo cache; N+1 counts  

================================  
RECOMMENDED FIX PHASES  
================================  

PERF-P1: Auth/shell caching + duplicate fetch removal + accountant listener trim + settlements stream fix  

PERF-P2: Firestore pagination / scoping / N+1 removal (preserve finance semantics)  

PERF-P3: Route-level finance repository  

PERF-P4: Rebuild / listener optimization  

PERF-P5: Bundle / images / lazy loading  

PERF-P6: Runtime benchmark + controlled rollout  

================================  
SAFETY  
================================  

PRODUCT CODE CHANGED: **NO**  

FINANCE SEMANTICS CHANGED: **NO**  

PRODUCTION DEPLOY: **NO**  

================================  
FINAL  
================================  

PERFORMANCE STATUS: **SEVERE** (cold boot + finance scan architecture)  

FIRST FIX RECOMMENDED: **PERF-P1** — dedupe login profile/claims∥scope, disable accountant stats live sync + replace menu badge snapshots with cheap TTL/count, fix Settlements stream-in-State — then **PERF-P2** finance pagination/aggregates without changing F1/F2/B1 math.  

STOP.
