# TOURi TAXI — ADMIN PERFORMANCE P4C REPORT

**MODE:** Firestore Web transport / one-shot read-path optimization  
**NO production deploy** · **NO financial writes** · **NO F1/F2/B1 formula change**

---

## BASE

| Item | Value |
|---|---|
| Base | P4B `ddbb72b` / tip `73ae78f` |
| Branch | `recovery/admin-performance-p4c-firestore-transport` |
| Preview | https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin/ |
| Probe | `admin/Admi/qa_tools/admin_perf_p4c_trace_probe.mjs` (5 warm) |
| Metrics | `docs/admin_performance/ADMIN_PERFORMANCE_P4C_METRICS.json` |

---

================================
FIRESTORE
================================

### A — Configuration audit (not assumed)

| Item | Value |
|---|---|
| FlutterFire `cloud_firestore` | **5.6.9** |
| `cloud_firestore_web` | **4.4.9** |
| `firebase_core` | **3.14.0** |
| Web Firebase JS SDK | Bundled via FlutterFire (no separate `firebase.js` pin in `web/`) |
| Init location | `lib/backend/firebase/firebase_config.dart` → `initFirebase()` |
| Settings | `AdminFirestoreWebConfig.applyOnce` **once** before first Firestore use |
| Persistence (shipped) | **IndexedDB ON** (`persistenceEnabled: true`) |
| Long-polling | default (force=false, autoDetect=false) |
| Fetch streams | N/A — not separately configured in this FlutterFire version |
| Finance one-shot `GetOptions` | **`Source.server`** |

### B — Instance

| Check | Result |
|---|---|
| `Firebase.initializeApp` | **1** (`firebaseInitCount=1`) |
| Firestore settings apply | **1** (`settingsApplyCount=1`) |
| Canonical `FirebaseFirestore.instance` | **SINGLE** |

### C — Query modes (unchanged architecture)

| Surface | Mode |
|---|---|
| Finance Hub modern first page | **ONE_SHOT `.get(Source.server)`** (was already `.get()`) |
| Reconciliation first page | **ONE_SHOT `.get`** + settlements maps **`.get`** |
| Settlements list | **LIVE `.snapshots()`** (P1/P2A — preserved) |
| Money Movement | `FinanceCompanyService` one-shot `.get()` |
| Agent Finance | Hub-style repository first page (one-shot) |
| Reports | `AccountantFinanceLoader` / bundle load (request-based) |
| Summary scan | chunked **`.get(Source.server)`** |

### FINANCE FINAL MODE
`Query.get(GetOptions(source: Source.server))` via `FinanceOrderQuery.fetchModernPage`

### RECON FINAL MODE
ONE_SHOT get (orders + settlement membership maps)

### SETTLEMENT FINAL MODE
**LIVE**

### FIRESTORE INSTANCE
**SINGLE**

---

================================
TRANSPORT
================================

### D — Same-shape fetch modes (5 warm, Chromium)

With **persistence ON** (shipped), late `snapshots().first` can return from IndexedDB after prior gets — treat snap median as **contaminated**.

Fairer A/B (persistence OFF experiment, same probe order discipline):

| Mode | Median query→snap | Notes |
|---|---:|---|
| GET `Source.server` | **914–1197** ms | Selected production options |
| GET default | **1087–1288** ms | Slightly slower / noisier |
| `snapshots().first` | **1119+** ms (fair) / **103** ms (contaminated after gets) | Listener establish cost; not selected |

### SELECTED
**Default WebChannel transport** + **persistence ON** + **one-shot `get(Source.server)`** for non-live finance reads.

### REASON
1. Hub/Recon were already one-shot — switching listener→get was **not** available as a win.  
2. `Source.server` avoids cold IndexedDB-first waits on financial first page while keeping live Settlements on snapshots.  
3. **`persistenceEnabled: false` improved Hub (~1112 ms) but regressed Settlements ~324 → ~1363 ms** → **rolled back** (stop-rule Y).  
4. Forced / auto long-polling **not** enabled (no measured win; force docs warn of degradation).  
5. REST remains **control only** — not a production read path.

### RETRIES
Probe `netFails`: 3 (channel aborts under full-reload probe; not token refresh loops)

### CHANNEL RECONNECT
No material reconnect storm; Settlements listener architecture unchanged (count=1 owner).

---

================================
REAL BROWSER
================================

Browser: **Chromium (Playwright headless)** — Human QA browser matrix.  
**Safari:** not executed this run → **no Safari PASS claimed**.

| Route | P4B median | P4C median | P4C p90 |
|---|---:|---:|---:|
| Finance SDK wait (query→snap) | 1651 / control 1755 | **1065** | 1941 |
| Finance route→paint | 1670 | **1083** | 1963 |
| Reconciliation total | 1164 | **1025** | 1837 |
| Settlements total | 324 | **328** | 2016* |

\*Settlements p90 inflated by one cold outlier under full page reload; **median 328 ≈ P4B 324**.

### CACHE HIT → PAINT
SPA in-app navigation uses P3 repository (TTL **180s**) — target &lt;500 ms when `CACHE_HIT` without `FIRESTORE_GET_START`.  
Playwright `page.goto` **full-reloads** Flutter → wipes P3 memory; IndexedDB may still serve SDK. Probe SPA cache timing is **not** authoritative; Human QA should confirm Hub→Recon→Hub within 180s.

---

================================
SDK VS CONTROL
================================

| Method | ms |
|---|---:|
| SDK Finance Hub median query→snap | **1065** |
| REST `documents:runQuery` control (same session) | **854** |
| DELTA (SDK − REST) | **~211** (was ~1016 on P4B) |

Transport remains Firestore **Listen/WebChannel** for SDK gets (not REST RunQuery). Latency moved closer to REST without replacing the client.

---

================================
CACHE
================================

| Item | Result |
|---|---|
| SOURCE TTL | **180s** (P4B preserved) |
| FRESH HIT NETWORK (SPA) | **0** when repository HIT |
| LOGOUT INVALIDATION | **PASS** (`AdminSessionCleanup` → `AdminFinanceRepository.clearSession`) |
| CROSS-USER | **PASS** for P3 memory; IndexedDB persistence remains SDK-local (logout does not `clearPersistence` — enabling that requires terminate; not shipped) |
| Persistence OFF experiment | **REJECTED** (Settlements regression) |

---

================================
SEMANTICS
================================

| Check | Result |
|---|---|
| F2 | **PASS** (unit) |
| B1 | **PASS** (unit) |
| B2 | **PASS** (unit) |
| QA | **PASS** (unchanged filters) |
| SCOPE | **PASS** |
| SETTLEMENT LIVE | **PASS** |

---

================================
TESTS
================================

| Suite | Result |
|---|---|
| `flutter analyze` (touched) | **PASS** |
| P4C transport tests | **PASS** |
| F1/F2/B1/B2/P2A/P4A/P4B | **PASS** |
| NEW FAILURES | **0** |

---

================================
SAFETY
================================

| Item | Result |
|---|---|
| FINANCIAL WRITES | **0** |
| RULES CHANGED | **NO** |
| FUNCTIONS CHANGED | **NO** |
| PRODUCTION DATA | **UNCHANGED** |
| PRODUCTION DEPLOY | **NO** |
| CUSTOMER | **UNCHANGED** |
| DRIVER | **UNCHANGED** |

---

================================
NETWORK TRACE (G–H)
================================

Finance Hub first Firestore request type: **`Firestore/Listen/channel` (WebChannel)** even for `.get()` — SDK does not use REST `runQuery` for FlutterFire gets.

Latency locus: **Listen/WebChannel first payload**, not Flutter paint (STATE→PAINT ~12–21 ms).

Connection reuse: full Playwright reloads create new channels; SPA navigation reuses the Firebase app instance (**CONNECTION REUSED** within session). **NEW CONNECTION PER ROUTE** only under full document reload probes.

---

================================
FINAL
================================

```
BASE: P4B ddbb72b / 73ae78f
BRANCH: recovery/admin-performance-p4c-firestore-transport
COMMIT: d2d2216
PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin/

CURRENT QUERY MODE: Hub/Recon ONE_SHOT get; Settlements LIVE
FINANCE FINAL MODE: get(Source.server)
RECON FINAL MODE: ONE_SHOT get
SETTLEMENT FINAL MODE: LIVE
FIRESTORE INSTANCE: SINGLE

DEFAULT SDK MEDIAN (Hub query→snap): 1065
GET MEDIAN (server mode bench): ~1197 (post-settlements matrix)
SNAPSHOT_FIRST MEDIAN: contaminated under persistence; fair OFF-run ~1119+
SELECTED: get(Source.server) + persistence ON + default transport
REASON: measured Hub/Recon improvement; Settlements median preserved; persistence OFF rejected
RETRIES: 0 token; netFails 3 probe noise
CHANNEL RECONNECT: 0 material

FINANCE SDK WAIT: 1755 → 1065 ms
FINANCE ROUTE PAINT: 1670 → 1083 ms
FINANCE P90: 1963
RECON: 1164 → 1025 ms
RECON P90: 1837
SETTLEMENT: 324 → 328 ms
SETTLEMENT P90: 2016 (outlier; median OK)
CACHE HIT → PAINT: SPA / Human QA (P3 180s)

SDK: 1065
REST CONTROL: 854
DELTA: ~211

SOURCE TTL: 180s
FRESH HIT NETWORK: 0 on P3 HIT (SPA)
LOGOUT INVALIDATION: PASS
CROSS-USER: PASS (P3)

F2/B1/B2/QA/SCOPE/SETTLEMENT LIVE: PASS
ANALYZE: PASS
P4C: PASS
FINANCE tests: PASS
NEW FAILURES: 0

PERF-P4C: READY_FOR_HUMAN_QA
FINANCE FIRST-DATA: FAST (≤1200 ms preferred met on median)
NEXT: SUMMARY_ARCHITECTURE (if summary still >5s) / Human Safari smoke
```

STOP.
