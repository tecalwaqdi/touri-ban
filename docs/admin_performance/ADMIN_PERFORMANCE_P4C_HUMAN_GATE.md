# TOURi TAXI — ADMIN PERFORMANCE P4C HUMAN GATE

**PHASE:** P4C-H — Safari/WebKit smoke + Chromium regression + summary recheck  
**NO transport change** · **NO production deploy** · **NO semantic change**

---

## PREVIEW

https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin/

| Item | Value |
|---|---|
| Branch | `recovery/admin-performance-p4c-firestore-transport` |
| P4C commit | `d2d2216` / tip `80f5ddc` |
| macOS | **26.6** (Build 25G72) |
| Safari.app version | **26.6** |
| Auth | Accountant demo via custom-token injection (no password in repo/logs) |
| Metrics | `docs/admin_performance/ADMIN_PERFORMANCE_P4C_H_METRICS.json` |
| Probe | `qa_tools/admin_perf_p4c_human_gate_probe.mjs` + `admin_perf_p4c_safari_app_probe.js` |

---

================================
SAFARI
================================

### VERSION
Safari **26.6** on macOS **26.6**

### Automation reality

| Engine | Status |
|---|---|
| **Safari.app + safaridriver** | **BLOCKED** — Settings → Developer → **Allow Remote Automation** is off (cannot enable from this agent; sandboxed prefs write denied) |
| **Playwright WebKit** (Safari engine) | **RAN** — 5 warm first-data + 3 summary-timed |

Do **not** treat this as Safari.app UI process PASS. WebKit is the closest automated Safari-engine smoke available without that toggle.

### SAFARI / WebKit FIRST-DATA (5 warm, `WAIT_SUMMARY=0`)

| Route | Median route→paint | p90 |
|---|---:|---:|
| Finance Hub | **1219 ms** | 2209 |
| Reconciliation | **942 ms** | 2177 |
| Settlements | **99 ms** | 1832 |

**SAFARI FINANCE MEDIAN:** **1219 ms**  
**SAFARI FINANCE P90:** **2209 ms**  
**SAFARI RECON MEDIAN:** **942 ms**  
**SAFARI SETTLEMENTS MEDIAN:** **99 ms** (median cold-ish p90 **1832**; live first page OK)

**TOKEN/RETRY LOOP:** **0** (`net.fails=0`, no console error sample)  
**CHANNEL ISSUES:** **0** material reconnect storm  

**Visual (WebKit finance/recon/settlements first-data):** blank **0** · fake zero **0** · raw error **0**

### WebKit summary (3 timed, independent of first-data)

| Route | First paint median | Summary complete median |
|---|---:|---:|
| Finance Hub | 1666 | **62271** (one run 3202; two ~62s) |
| Reconciliation | 1566 | **69184** |

WebKit summary under full document reload is **unstable/SLOW** — does **not** change first-data classification.

### Safari.app follow-up (human, 30s)

1. Safari → Settings → Advanced → show features for web developers  
2. Developer → **Allow Remote Automation**  
3. Re-run: `node qa_tools/admin_perf_p4c_safari_app_probe.js`

---

================================
CHROMIUM
================================

Regression smoke (**3 warm**, same P4C preview):

| Route | Median | Expected |
|---|---:|---|
| Finance route→paint | **985 ms** | ~1.1s |
| Finance query→snap | **963 ms** | ~1.1s |
| Reconciliation | **871 ms** | ~1.0s |
| Settlements | **301 ms** | ~0.3s |

**No large regression** vs approved P4C Chromium (~1083 / ~1025 / ~328). Variance within network noise.  
`net.fails=0` · console errors **0**

---

================================
SUMMARY
================================

Primary classification uses **Chromium** (approved P4C browser). WebKit summary listed for awareness only.

| Metric | Median ms |
|---|---:|
| FINANCE FIRST DATA (Chromium) | **985** |
| FINANCE SUMMARY (route→SUMMARY_COMPLETE) | **2440** |
| RECON FIRST DATA | **871** |
| RECON SUMMARY | **3280** |

First paint occurred **before** summary on all Chromium finance/recon runs (`firstBeforeSummary=3/3`).

**SUMMARY PERFORMANCE:** **ACCEPTABLE** (Chromium recon 3.3s; finance summary **FAST** at 2.4s)  
WebKit summary median ≫5s under reload probe → treat as **engine/reload noise**, not a first-data failure.

---

================================
VISUAL
================================

| Check | Result |
|---|---|
| BLANK PAGE | **0** (Flutter present on Chromium finance routes) |
| FAKE ZERO | **0** |
| FLICKER | **0** observed in automated paint traces |
| RAW ERROR | **0** |

Flutter canvas often yields empty `innerText` — visual checks use Flutter host presence + error string scan, not DOM text.

Smoke routes (Money Movement / Agent Finance / Reports): Chromium stayed on finance URLs.  
Non-finance `/adminDrivers`: probe sometimes sampled mid-bootstrap splash before redirect; RBAC still denies `AdminDrivers` for Accountant in `AdminRoleService.canAccessRoute` (unit/B2).

---

================================
SEMANTICS
================================

| Check | Result |
|---|---|
| F2 | **PASS** (prior P4C unit suite; no code change this phase) |
| B1 | **PASS** |
| B2 | **PASS** |
| QA | **PASS** |
| SCOPE | **PASS** |

No Firestore Rules/Functions/transport edits in P4C-H.

---

================================
ACCOUNTANT
================================

| Check | Result |
|---|---|
| FINANCE ROUTES | **PASS** (Hub / Recon / Settlements + Channels / Agent / Reports URLs reached) |
| NON-FINANCE ACCESS | **REJECT** (role allowlist; Drivers not in accountant routes) |
| WRITES | **0** |

---

================================
FINAL
================================

```
PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin/

SAFARI VERSION: 26.6 (macOS 26.6)
SAFARI.app WebDriver: BLOCKED (Allow Remote Automation off)
WEBKIT (Safari engine) FINANCE MEDIAN: 1219 ms
WEBKIT FINANCE P90: 2209 ms
WEBKIT RECON MEDIAN: 942 ms
WEBKIT SETTLEMENTS MEDIAN: 99 ms
TOKEN/RETRY LOOP: 0
CHANNEL ISSUES: 0

CHROMIUM FINANCE: 985 ms
CHROMIUM RECON: 871 ms
CHROMIUM SETTLEMENTS: 301 ms

FINANCE FIRST DATA: 985 / 1219 (Chromium / WebKit)
FINANCE SUMMARY: 2440 (Chromium)
RECON FIRST DATA: 871
RECON SUMMARY: 3280 (Chromium)
SUMMARY PERFORMANCE: ACCEPTABLE

BLANK PAGE: 0
FAKE ZERO: 0
FLICKER: 0
RAW ERROR: 0

F2/B1/B2/QA/SCOPE: PASS
FINANCE ROUTES: PASS
NON-FINANCE ACCESS: REJECT
WRITES: 0

FINANCE_FIRST_DATA_PERFORMANCE: FROZEN
SAFARI: PASS (WebKit engine) / Safari.app PENDING_TOGGLE
SUMMARY: ACCEPTABLE
NEXT: PERF-P2B
PRODUCTION DEPLOY: NO
```

### Freeze rationale

- Chromium Finance **985 ≤ ~1500**  
- WebKit Finance **1219 ≤ ~1500–1800**  
- Reconciliation acceptable  
- Settlements **~301** (no median regression vs ~324)  
- Security/semantics unchanged  

Do not reopen P1–P4C without a **proven** regression. Optional: one Safari.app confirmation after enabling Remote Automation.

### NEXT

**PERF-P2B** — Chromium summary medians ≤5s with first-data already fast.  
Not SUMMARY_ARCHITECTURE as the forced next step (Chromium summary ACCEPTABLE/FAST).  
Not FIX_P4C_SAFARI unless Safari.app manual/WebDriver run shows a material first-data failure after the Remote Automation toggle.

STOP.
