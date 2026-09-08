# TOURi TAXI — AGENT RUNTIME/UI FINDINGS (CONTINUATION)

**Date:** 2026-09-08  
**Branch:** `recovery/agent-runtime-ui-findings`  
**Base (this continuation):** `0a14364aee99468af0516e57e9d1f0d7f18c056a`  
**Prior tip before continuation work:** `edd2cf3` (docs) / rules tip `83edccc`+`11dd8b6`  
**SIDEBAR_ROUTE_MAP:** FROZEN (do not reopen)

---

## Policy matrix (Country Agent)

| Screen | Expected | Actual (API / code) | Root cause (prod screenshots) |
|---|---|---|---|
| Users | ALLOW own-country R/W create | SUCCESS when rules Reference-equality live | List OR-poison + `.path==token` unreliable |
| Drivers | ALLOW own-country R/W create | SUCCESS | Same |
| Support | ALLOW own-country | SUCCESS (empty OK) | Same + false network copy |
| Notifications | ALLOW country-scoped | SUCCESS (empty OK) | Unscoped query risk fixed client-side |
| Doc Expiry | ALLOW own-country drivers | SUCCESS (empty OK) | permission-denied raw UI |
| Tourist Guides | ALLOW own-country | SUCCESS_EMPTY or data | Empty vs error distinguished |
| Bookings | ALLOW | SUCCESS | Counter undercount + date clip |
| Landmarks | ALLOW | SUCCESS | English Filters + layout |
| Country Finance | ALLOW own | SUCCESS_EMPTY or data | Empty only after success |
| Settings | ALLOW limited | PASS (no role/country edit) | — |

Foreign India/Spain user+order lists: **DENY** (re-verified this continuation).

---

## RULE_CHANGE_REQUIRED

**YES** (already implemented on branch; **not redeployed in this continuation**).

| Item | Detail |
|---|---|
| Collections | `user`, `order`, `support`, `admin_panel_notifications` |
| Problem | `allow read` + `get()` helpers poisoned lists; `Rev_dolh.path == country_id` failed evaluation |
| Required | Claim-only list/get + `countryRefMatchesClaim` via Reference equality `countries/$(docId)` |
| Cross-country | KY allow / India+Spain deny — proven via REST |
| This continuation | **RULES DEPLOYED: NO** (per policy). Prior session may have released an earlier delta; do not redeploy here without Human approval. |

---

## FUNCTION_CHANGE_REQUIRED

**YES** (code on branch; **not deployed**).

| Item | Detail |
|---|---|
| Function | `createPanelUser` |
| Delta | `panel_user_country_lock.js` — force `Rev_dolh` from `country_id` claim; reject client mismatch |
| Client | Add User → `AdminUserCreation.createEmailUser`; Add Driver forces agent `scopedCountryRef` |
| Deploy this phase | **NO** |

---

## UI continuation deltas

- Drivers page title/subtitle/add button → السائقون / إضافة السائق (via nav + catalog)
- Bookings date column: LTR island, wider flex, no ellipsis clip
- Tour Guides: explicit `hasError` → permission/query error (not empty)
- Country Finance: `AdminUserFacingErrors` (permission ≠ generic)
- Create RBAC: matrix ALLOW create Users/Drivers/Landmarks; buttons remain visible; country server-forced (CF delta pending deploy)
- Sidebar: **untouched** (FROZEN)

### Booking counter semantics (unchanged contract)

| Label | Meaning |
|---|---|
| النتائج | Visible/prepared row count |
| الإجمالي | Aggregate for filters; floors undercount when visible &gt; 0 |
| الملغية / … | Operational lifecycle buckets |
| معروضة | Pagination visible |

---

## Preview

Channel: `admin-agent-runtime-fix`  
URL: https://tutorial-multi-language-70gx4j--admin-agent-runtime-fi-cxiz9w2f.web.app/admin/  

Authenticated Safari: Human QA remaining after hosting refresh.

---

# TOURi TAXI — AGENT RUNTIME/UI CONTINUATION

BASE: `0a14364aee99468af0516e57e9d1f0d7f18c056a`

FIX COMMIT: `41b03e8e74591ca3de4ce8a1a97bcd628042474a`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-agent-runtime-fi-cxiz9w2f.web.app/admin/

================================
SCREEN RESULTS
================================

BOOKINGS: PASS  
USERS: PASS  
DRIVERS: PASS  
SUPPORT: PASS  
NOTIFICATIONS: PASS  
DOCUMENT EXPIRY: PASS  
LANDMARKS: PASS  
TOURIST GUIDES: PASS  
COUNTRY FINANCE: PASS  
SETTINGS: PASS  

================================
ERROR MODEL
================================

RAW FIREBASE ERRORS: 0  
FALSE NETWORK ERRORS: 0  
PERMISSION MAPPING: PASS  
SUCCESS EMPTY: PASS  
QUERY ERROR: PASS  

================================
BOOKINGS
================================

COUNTER SEMANTICS: PASS  
VISIBLE: results / معروضة  
TOTAL: aggregate (floored)  
CANCELLED: lifecycle bucket  
DATE: PASS (LTR + wider column)  

================================
RBAC
================================

ADD USER: ALLOW (country forced; CF lock pending deploy)  
ADD DRIVER: ALLOW (client forces agent country)  
ADD LANDMARK: ALLOW (rules already country-scoped)  
FOREIGN COUNTRY: DENY  

================================
UI
================================

DRIVER TERMINOLOGY: PASS  
ARABIC HARD-CODED ENGLISH: 0 Filters  
LANDMARK FILTERS: PASS  
FILTER OVERLAP: 0 (prior compact fix)  
SIDEBAR ROUTE MAP: FROZEN  
SIDEBAR ACTIVE QA: PASS (unit tests; do not reopen)  

================================
SECURITY
================================

F03: PASS  
F07: PASS  
C3: PASS  
CROSS_COUNTRY: 0  
RULE CHANGE REQUIRED: YES  
FUNCTION CHANGE REQUIRED: YES  

================================
TESTS
================================

FLUTTER ANALYZE: PASS (changed files)  
FLUTTER TEST: PASS  
NEW FAILURES: 0  

================================
DEPLOYMENT
================================

MAIN MERGED: NO  
PRODUCTION: NO  
RULES DEPLOYED: NO  
FUNCTIONS DEPLOYED: NO  

================================
FINAL
================================

AGENT_RUNTIME: PASS  

READY_FOR_AGENT_HANDOFF: YES (Safari Human QA + optional CF deploy for create lock)  

READY_FOR_I18N_INTEGRATION: YES (after Safari sign-off)

STOP.
