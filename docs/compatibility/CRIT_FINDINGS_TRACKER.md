# CRIT-01 … CRIT-20 Tracker (2026-08-27 execution)

| ID | REPORT | CURRENT_RUNTIME_STATUS | ROOT_CAUSE / NOTE | FIX / STATUS | DEPLOY |
|---|---|---|---|---|---|
| CRIT-01 | Dashboard ≠ lists | **STILL_BROKEN** (UNPROVEN magnitude) | Count vs country-scoped lists; missing `Rev_dolh` | Inventory only; no mass backfill | PREPARED_NOT_DEPLOYED |
| CRIT-02 | Missing composite indexes | **PARTIALLY_FIXED** | Proven Admin queries lacked indexes | Added + deployed indexes | DEPLOYED indexes |
| CRIT-03 | Bookings page broken | **PARTIALLY_FIXED** | Likely index (`Rev_dolh`+`data_order` / ALLNOW) | Indexes deployed; Admin UI runtime **NOT_RUNTIME_PROVEN** | INDEXES_DEPLOYED |
| CRIT-04 | Registration V2 | **PARTIALLY_FIXED** | Code+tests in tree; auto-activate forms remain | Dual-read/write exists; form defaults **OUTDATED vs TARGET** | No enforcement change |
| CRIT-05 | Transport companies | **PARTIALLY_FIXED** | Missing `Rev_dolh`+`naim` index | Index deployed; form TARGET gaps remain | INDEXES_DEPLOYED |
| CRIT-06 | type_car / pricing | **STILL_BROKEN** (data quality) | Duplicate/demo prices in data | No pricing mutation | PREPARED_NOT_DEPLOYED |
| CRIT-07 | Finance vs wallets | **STILL_BROKEN** / UNPROVEN | Different definitions + index on top-ups | Index for tx type; no balance rewrite | INDEX partial |
| CRIT-08 | Raw errors / UIDs | **PARTIALLY_FIXED** | Wallets showed raw Firestore + full UID | Friendly errors + truncated ids | Admin source only |
| CRIT-09 | Profits/reports | **UNPROVEN** / likely index+scope | Reports loaders depend on order indexes | Indexes help; full reports QA pending | NOT_RUNTIME_PROVEN |
| CRIT-10 | Super Admin risk | **STILL_BROKEN** vs TARGET | Invitation/2FA not enforced | Inventory only | PREPARED_NOT_DEPLOYED |
| CRIT-11 | Audit log incomplete | **STILL_BROKEN** | Coverage gaps | No destructive change | PREPARED_NOT_DEPLOYED |
| CRIT-12 | Geo mess | **STILL_BROKEN** | Duplicate/test countries | Dry-run only | PREPARED_NOT_DEPLOYED |
| CRIT-13 | Old branding | **STILL_BROKEN** | Ara Watan strings | P2 UI, not done | — |
| CRIT-14 | i18n incomplete | **PARTIALLY_FIXED** | Locales exist; gaps remain | No silent locale change | — |
| CRIT-15 | Password change weak | **STILL_BROKEN** | Client-side pattern | No auth tighten | PREPARED_NOT_DEPLOYED |
| CRIT-16 | Loading/empty/error | **PARTIALLY_FIXED** | Some admin list states exist | Wallets errors sanitized | — |
| CRIT-17 | Search vs counts | **STILL_BROKEN** | Client filtered counts | P2 grid work not done | — |
| CRIT-18 | A11y | **UNPROVEN** | Needs real a11y pass | Not claimed PASS | — |
| CRIT-19 | Auto-activation forms | **STILL_BROKEN** vs TARGET | Defaults activate | Changing defaults may break ops — defer | PREPARED_NOT_DEPLOYED |
| CRIT-20 | Maps keys | **UNPROVEN** | Restriction plan only | No key rotation | PREPARED_NOT_DEPLOYED |

## Cash booking visibility (P0-A)

| Check | Status |
|---|---|
| CASH_ORDER_EXISTS | PASS (sample) |
| CASH_OWNER_REF | PASS |
| CASH_ACTIVE_LOCK | N/A after customer cancel |
| CUSTOMER_LIST_QUERY | STATIC_PASS (`USER`+`data_order`) |
| LEGACY_VISIBILITY_CONTRACT | PASS (compat fields present) |
| NO_NGENIUS_FOR_CASH | PASS |
| DEVICE_TEST_REQUIRED | YES (new cash after install) |
