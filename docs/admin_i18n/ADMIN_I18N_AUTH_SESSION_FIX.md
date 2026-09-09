# TOURi TAXI — ADMIN I18N AUTH/SESSION FIX

**DATE:** 2026-09-09  
**BRANCH:** `recovery/admin-i18n-auth-session-fix`  
**BASE:** `5bf16a4dbe7d30af6d0a3468c33283569e77a6db`  
**FIX COMMIT:** `cd761f275ae8c934450b3b5055dc4d0cdd6f3592`

**PREVIEW:**  
https://tutorial-multi-language-70gx4j--admin-i18n-auth-sessio-1mqhbr0d.web.app/admin/

**Provenance:** `"git_commit": "cd761f275ae8c934450b3b5055dc4d0cdd6f3592"`

---

## Root cause (proven)

### SHELL LOADER / SESSION → LOGIN

**Primary code failure:** `_loginOrPanelHome` (and `/` / `errorBuilder`) treated  
`loggedIn && !AdminRoleService.hasPanelAccess` as **login** (`HomePageWidget`).

That maps **AUTHENTICATED_ROLE_LOADING / claims race** to **UNAUTHENTICATED UI**.

Triggered especially when:

1. Locale rebuild / web auth rehydrate briefly clears or delays claims/profile binding.
2. `authenticatedUserStream` `switchMap` emitted a transient `null` profile while  
   `FirebaseAuth.currentUser` was still present → cleared `currentUserDocument` /  
   unbound role → `hasPanelAccess == false` → **fake login**.
3. `idTokenChanges(null)` during rebuild could race with persistence restore.

**Not** Cairo/font. Font assets untouched.

### SUPER ADMIN / ACCOUNTANT “FAIL” in prior human QA

Prior gate could not authenticate those roles in Safari (automation blocked).  
On this preview, Chromium injection shows both land correctly with resolved roles  
(`سوبر أدمن`, `محاسب`) and **no** redirect to `/homePage` after locale reload / deep refresh.

### LANGUAGE SWITCH

`setLocale` only updates `MaterialApp.locale` + SharedPreferences — no FirebaseAuth recreate.  
Side effect was **downstream auth gate misclassification**, not locale storage itself.

---

## Fixes shipped (`cd761f2`)

1. `AdminAuthNavPolicy.decidePanelHome` — login only when Firebase user absent;  
   loading / unauthorized otherwise.
2. Wire `/`, `homePage` stream builder, `errorBuilder` through that decision.
3. Debounced definitive sign-out on `idTokenChanges(null)` + restore path if user returns.
4. Ignore transient null profile while `currentUser` present.
5. `_PanelSessionGate` 25s timeout → retry (no infinite splash).
6. Copy: Drivers subtitle/CTA, role badge, Gallery picker labels (all 7 locales for Gallery keys).
7. **Follow-up from repro agent:** do not mark `_scopeReadyForUid` when bootstrap
   exited on `AdminRole.none`; retry profile/claims once while RBAC unsettled;
   `ensureScopeReady` syncs profile before no-op when access briefly false
   (Accountant HTML splash / `isScopeReady` forever-false).

**Unchanged:** Rules, Functions, Payment API, Agent security model, sidebar map, Cairo fonts.

---

## Tests

| Suite | Result |
|---|---|
| `admin_auth_navigation_p0_test` (+ panel home decisions) | PASS |
| `admin_auth_locale_switch_test` | PASS |
| Agent / accountant / route-guard slice | PASS |
| analyze (touched files) | PASS |

---

## Security regression

| Gate | Status |
|---|---|
| F03 / F07 / C3 / CREATE SECURITY | PASS (no backend change) |
| RULES / FUNCTIONS / PAYMENT | UNCHANGED |
| Accountant writes | 0 (model unchanged) |

---

## Chromium auth gate (new preview)

Evidence: `docs/admin_i18n/human_qa_round3/`

| Role | Landing | Locale reload | Deep refresh | → login |
|---|---|---|---|---|
| Super Admin | `/home22Dashboard` | same | `/adminDrivers` | 0 |
| Accountant | `/adminFinanceHub` | same | `/adminFinanceReconciliation` | 0 |
| Country Agent | `/home22Dashboard` | same | `/adminDrivers` | 0 |

Screenshots confirm resolved role labels (not English “Resolving role”) and Drivers copy  
`السائقون بانتظار…` / `أضف سائقًا`.
