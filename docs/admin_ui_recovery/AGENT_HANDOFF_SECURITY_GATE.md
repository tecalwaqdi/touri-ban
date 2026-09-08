# TOURi TAXI — AGENT HANDOFF SECURITY GATE

**Project:** `tutorial-multi-language-70gx4j`  
**Admin:** `admin/Admi`  
**Scope:** F03 + F07 ONLY  
**Date:** 2026-09-08  
**Rules / Functions deployed:** **NO** (STOP for approval)  
**Data mutations:** **0**  
**Real Agent handoff:** **NO**

---

## SOURCE

| Item | Value |
|------|--------|
| Prior reviewed source (cited) | `d50d620ad97132a958351c0a6f2c44783bf6b6fb` |
| Worktree HEAD at gate | `95e373a5331502be4f4d071f99b40a920e1c4eeb` |
| Relation | `d50d620` is an ancestor of HEAD |
| Branch | `feature/admin-finance-demo-mode` |

Production Rules/Functions were **not** pulled for live drift comparison in this gate. Repo changes below are **local only** until an explicit deploy approval.

---

## VERDICT

| Gate | Status |
|------|--------|
| **F03 AGENT RATE SELF-WRITE** | **FIXED** (repo; not deployed) |
| **F07 COUNTRY ISOLATION** | **FIXED** (repo; not deployed) on required surfaces |
| **AGENT_HANDOFF_SECURITY** | **READY_FOR_DEPLOY_GATE** |
| **REAL_AGENT_HANDOFF** | **NO** |

---

## F03 — Agent commission rate (`Agent_total`)

### Proven hole (prior)
Country Agent could client-update own `Agent_total` (e.g. 5 → 150).

### Fix
1. **Firestore rules** (`firestore.rules`):
   - `agentCommercialRatesUnchanged()` — blocks create/update/**delete** of `Agent_total`, `agent_total`, `vat_percent`, `app_commission_percent` via `diff().affectedKeys()` (avoids get-default bypass on `FieldValue.delete()`).
   - Wired into `privilegedUserFieldsUnchanged()` and `agentAssignmentFieldsUnchanged()` so **all** applicable `user/{uid}` update branches (self, country admin, Super Admin **client**) cannot mutate rates.
   - Country Admin create: `notSettingAgentRates`.
   - Own-profile create: rates fields forbidden.
2. **Server mutation path** (`agent_country_assignment.js` → `updateCountryAgentAssignment`):
   - **Super Admin only** (unchanged).
   - `validateCommissionRatePercent`: finite, not NaN, **[0, 100]**.
3. **`createPanelUser`** (`index.js`): same validation before write.
4. **Historical order snapshots** locked in `financialOrderFieldsUnchanged()`:
   `agent_rate`, `agent_rate_type`, `agent_amount`, `agent_amount_minor`, `agent_snapshot_at`, `agent_id`, `agent_display_name`, `agent_attribution_status`, `agent_currency`, `agent_scope`, `agent_snapshot_version`.

Country Admin **cannot** arbitrarily alter `Agent_total` via client; Super Admin / Admin SDK CF remains the authorized path.

---

## F07 — Country isolation

### Settlement children
`financial_settlements/{id}/lines|events` now use `canReadSettlementChild(id)` — parent settlement `countryId` / `countryRef` must match `claimCountryPath()`. Bare `isCountryAdmin()` no longer grants global child reads.

### Driver financial summary
`getDriverFinancialSummaryV2` / `assertDriverSummaryCountryScope`:
- Caller country from claims (`country_id`, normalized).
- Driver country from **server** `user/{driverId}` (`Rev_dolh` / `Rev_dloh_agent`).
- Mismatch → `permission-denied`.
- Super Admin + global Accountant (`finance` without `country_admin`/`agent`) unchanged.

### Payment API
`requireFinanceOrAdmin` no longer treats `isAdminRule === 2` as global.
- `resolveFinanceAccess` → `{ global | country | denied }`.
- `assertResourceCountryAccess` on session load (status + refund).

### type_car policy (documented before change)
**Policy: GLOBAL CAR CATALOG** (docs have no country field).  
**Write:** Super Admin only. Country Admin write removed.

### Residual (out of this matrix; not claimed FIXED)
Some other finance collections still use broad `isCountryAdmin()` list reads (e.g. periods/adjustments). Not in the required F07 matrix; track as follow-up if needed.

---

## PERMISSION MATRIX (claims / scope)

| Role | Typical claims | Finance / settlement | Agent_total write | type_car write |
|------|----------------|----------------------|-------------------|----------------|
| Super Admin | `super_admin` (+ often `finance`) | Global | CF / Admin SDK only (validated 0–100) | Yes |
| Accountant | `finance` (no country hybrid) | Global read; writes DENY (unchanged policy) | No | No |
| Country Admin | `country_admin`, `country_id`, often `support` | **Country-scoped** | Client DENY | No (global catalog) |
| Country Agent | `agent`, `country_admin`, `support`, `country_id` | **Country-scoped** (same claim today) | Client DENY | No |
| Support | `support`, `country_id` | Country-scoped where rules already scope | No | No |

### Pure Agent vs `country_admin`
Existing Agents receive `agent` + `country_admin` + `support` + `country_id`.  
**Decision this gate:** do **not** strip `country_admin` from Agent claims. Resource-level scoping was fixed first so `country_admin` is no longer treated as global on the F07 surfaces above.

### Saudi dual role
`info@touri-taxi.com` (Country Agent + Super Admin): **UNCHANGED**. Excluded from pure-Agent handoff approval. No claim stripping.

---

## SCOPE TESTS

| Case | Result |
|------|--------|
| OWN COUNTRY (summary / payment helpers) | **PASS** |
| OTHER COUNTRY | **DENY** |
| SETTLEMENT LINES CROSS-COUNTRY | **DENY** (rules: parent scope) |
| SETTLEMENT EVENTS CROSS-COUNTRY | **DENY** (rules: parent scope) |
| DRIVER FINANCIAL SUMMARY CROSS-COUNTRY | **DENY** |
| PAYMENT API CROSS-COUNTRY | **DENY** |
| TYPE_CAR POLICY | **GLOBAL** |

### Commission

| Case | Result |
|------|--------|
| AGENT SELF UPDATE | **DENY** (rules) |
| AGENT SELF DELETE | **DENY** (diff-based) |
| >100 | **DENY** (CF validator) |
| NEGATIVE / NaN / Infinity | **DENY** |
| Super Admin authorized rate in range | **PASS** (validator unit) |
| HISTORICAL SNAPSHOT | **UNCHANGED** / mutation **DENY** in rules |

### Automated runs (local)

```
node --test test/agent_handoff_security_f03_f07.test.js   → 11/11 PASS
npx tsx --test src/lib/auth/verify.f07.node.test.ts       → 5/5 PASS
node --test test/agent_country_assignment.test.js         → 23/23 PASS (C3)
node --test test/agent_order_snapshot.test.js             → 4/4 PASS
```

Full Firestore emulator suite was not required for this gate; matrix covered by rules static asserts + CF/Payment unit tests.

### Runtime QA (live Agents)

**Not executed** in this gate (no password changes; no login probes against production). Prefer existing trial Agents (e.g. India / other login-ready from `EXISTING_AGENT_ACCOUNTS_AUDIT.md`) **after** Rules/Functions deploy approval.

---

## REGRESSION

| Item | Status |
|------|--------|
| C3 one-country-one-active-agent | **PASS** (unit suite) |
| Accountant finance read | **PASS** (global finance path preserved) |
| Auth Navigation P0 | **PASS** (untouched) |
| Admin UI V2.1 / P4C / Demo mode | **PASS** (no Agent UI redesign) |
| Finance formulas / semantics | **UNCHANGED** |
| Saudi dual role | **UNCHANGED** |

---

## EXACT DIFF (security surfaces)

```
admin/Admi/firebase/firestore.rules
admin/Admi/firebase/functions/agent_country_assignment.js
admin/Admi/firebase/functions/driver_financial_summary_v2.js
admin/Admi/firebase/functions/index.js  (createPanelUser rate validation)
admin/services/payment-api/src/lib/auth/verify.ts
admin/services/payment-api/src/lib/payments/status-handler.ts
admin/services/payment-api/src/app/api/payments/refund/route.ts
```

Tests added:
- `admin/Admi/firebase/functions/test/agent_handoff_security_f03_f07.test.js`
- `admin/services/payment-api/src/lib/auth/verify.f07.test.ts`
- `admin/services/payment-api/src/lib/auth/verify.f07.node.test.ts`

Approx: **+323 / −33** on the seven implementation files (pre-report).

---

## DEPLOYMENT

| Item | Status |
|------|--------|
| RULES DEPLOYED | **NO** |
| FUNCTIONS DEPLOYED | **NO** |
| PAYMENT-API DEPLOYED | **NO** |
| DATA MUTATIONS | **0** |

### Recommended deploy sequence (after approval)
1. Deploy `firestore.rules`
2. Deploy Functions (`agent_country_assignment`, `driver_financial_summary_v2`, `createPanelUser` path in `index`)
3. Deploy Payment API (status + refund auth)
4. Staging / preview smoke: two-country Agent READ matrix
5. Only then consider real Agent handoff (still exclude Saudi dual-role)

---

## FINAL

```
# TOURi TAXI — AGENT HANDOFF SECURITY GATE

SOURCE:
d50d620 (reviewed ancestor) @ worktree HEAD 95e373a
feature/admin-finance-demo-mode
admin/Admi

F03 AGENT RATE SELF-WRITE:
FIXED

F07 COUNTRY ISOLATION:
FIXED

================================
SCOPE TESTS
================================

OWN COUNTRY:
PASS

OTHER COUNTRY:
DENY

SETTLEMENT LINES CROSS-COUNTRY:
DENY

SETTLEMENT EVENTS CROSS-COUNTRY:
DENY

DRIVER FINANCIAL SUMMARY CROSS-COUNTRY:
DENY

PAYMENT API CROSS-COUNTRY:
DENY

TYPE_CAR POLICY:
GLOBAL

================================
COMMISSION
================================

AGENT SELF UPDATE:
DENY

AGENT SELF DELETE:
DENY

>100:
DENY

NEGATIVE:
DENY

HISTORICAL SNAPSHOT:
UNCHANGED

================================
ROLES
================================

PURE AGENT CLAIMS:
agent + country_admin + support + country_id
(country_admin retained; resource scoping fixed)

COUNTRY ADMIN CLAIMS:
country_admin + country_id (+ support as configured)

SAUDI DUAL ROLE:
UNCHANGED

================================
REGRESSION
================================

C3:
PASS

ACCOUNTANT:
PASS

AUTH:
PASS

FINANCE SEMANTICS:
UNCHANGED

================================
DEPLOYMENT
================================

RULES DEPLOYED:
NO

FUNCTIONS DEPLOYED:
NO

DATA MUTATIONS:
0

================================
FINAL
================================

AGENT_HANDOFF_SECURITY:
READY_FOR_DEPLOY_GATE

REAL_AGENT_HANDOFF:
NO

STOP.
```
