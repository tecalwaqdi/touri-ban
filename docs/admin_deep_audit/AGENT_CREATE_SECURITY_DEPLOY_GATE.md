# TOURi TAXI — AGENT CREATE SECURITY DEPLOY GATE

**Date:** 2026-09-08  
**Firebase project:** `tutorial-multi-language-70gx4j`  
**Admin:** `admin/Admi`  
**Worktree:** `/Users/ventura/ara-ban-agent-runtime`  
**Branch tip (docs):** `2f1f4094ca728930a2d59fe7e5c22a76ac492cf9`  
**Runtime UI fix commit:** `41b03e8e74591ca3de4ce8a1a97bcd628042474a`  
**Main security base:** `c7627915997e3a916d056dd033fd7ccd379b2468`  
**i18n branch:** `recovery/admin-i18n-fix-findings` — **NOT merged**

SOURCE:
worktree `recovery/agent-runtime-ui-findings` @ `2f1f409` + uncommitted Rules/Function create-lock delta (deployed live)

RULES COMMIT:
source SHA1 `7740346499cf69d74f5fc2a3cad6d962d3936641` (`firestore.rules` ×3 copies byte-identical); live release 2026-09-08 via `firebase deploy --only firestore:rules`

FUNCTION COMMIT:
`createPanelUser` only (`functions:admin_functions:createPanelUser`); live `firebase-functions-hash` **NEW** `91476bdccb81b7d17f976a9203ab6888c6d97e68` (was `4ef7a1059dcc20874149a74c22b9670fd990aee6`)

================================
CREATE POLICY
================================

USER CREATE:
ALLOW (own-country only; CF-authoritative)

DRIVER CREATE:
ALLOW (own-country only; same `createPanelUser` path)

LANDMARK CREATE:
ALLOW (own-country only; direct Firestore + Rules)

================================
1 — AUDIT CREATE OPERATIONS
================================

### ADD USER
- **UI function:** `AdminUserCreation.createEmailUser` → Add User widget  
- **Cloud Function/API:** `createPanelUser` (callable)  
- **Firestore direct write:** NO (default `allowClientFallback=false`)  
- **country field:** `Rev_dolh` (+ `Rev_dloh_agent` when missing)  
- **client supplied:** YES (may send)  
- **server resolved:** YES — `applyCountryAdminCreateLock` forces claim `country_id`  
- **Rules enforcement:** `panelCanProvisionUser` + `countryRefMatchesClaim` (defense-in-depth; CF is primary)  
- **CURRENT PRODUCTION SECURITY:** **PASS** (post-deploy)

### ADD DRIVER
- **UI function:** Add Driver → `AdminUserCreation.createEmailUser` with `ismndob`  
- **Cloud Function/API:** `createPanelUser`  
- **Firestore direct write:** NO (same CF path)  
- **country field:** `Rev_dolh`  
- **client supplied:** YES  
- **server resolved:** YES — same lock; foreign DENY  
- **Rules enforcement:** same user create rules  
- **CURRENT PRODUCTION SECURITY:** **PASS**

### ADD LANDMARK
- **UI function:** `AdminaddMkan` / `AdminaddMkanCopy` → `AdminFirestoreDelete.setDocument` + `createMkanRecordData`  
- **Cloud Function/API:** none (direct Firestore)  
- **Firestore direct write:** YES  
- **country field:** `Rev_dolh`; region `id_cit` (cities); city `id_vill` (villages)  
- **client supplied:** YES  
- **server resolved:** NO CF; **Rules** validate claim country + geo `dolh` hierarchy via `mkanCreateInClaimCountry()`  
- **Rules enforcement:** claim-only Reference equality + region/city `dolh` get()  
- **CURRENT PRODUCTION SECURITY:** **PASS**

================================
SERVER AUTHORITY
================================

USER COUNTRY:
SERVER_FORCED

DRIVER COUNTRY:
SERVER_FORCED

LANDMARK COUNTRY:
SERVER_VALIDATED

REGION/CITY HIERARCHY:
PASS (KY Rev_dolh + India region → live DENY; KY region → ALLOW then QA cleanup)

================================
LIVE SECURITY
================================

Probe principal: Kyrgyzstan Country Agent UID `Kq0OjniqdcXpHQA3tZOxS0GJHbK2` (credentials not recorded).

OWN COUNTRY USER CREATE:
PASS (lock allows path; invalid email → `INVALID_ARGUMENT` before Auth create — no persistent user)

FOREIGN USER CREATE:
DENY (`Country scope mismatch.` India + Spain)

PRIVILEGED USER CREATE:
DENY (`Cannot set isAdmin` / `Isagent` / `isAdminRule`)

OWN DRIVER CREATE:
PASS (same invalid-email after lock)

FOREIGN DRIVER CREATE:
DENY (`Country scope mismatch.`)

OWN LANDMARK CREATE:
PASS (ephemeral `qa_fixture` docs created then Admin-SDK deleted)

FOREIGN LANDMARK CREATE:
DENY (India + Spain direct writes)

DIRECT BYPASS:
DENY (foreign user + foreign mkan REST writes → `PERMISSION_DENIED`)

FOREIGN region hierarchy:
DENY (`Rev_dolh=kyrgyzstan` + `id_cit=region_in_new_delhi`)

================================
BOOKING TOTAL
================================

AGGREGATE SOURCE:
SOURCE_TOTAL from aggregate/lifecycle when reliable (`admin_a_l_lhg_z_widget.dart`)

DISPLAY FLOOR:
PRESENT (`sanitizeTotal` → DISPLAY_SAFE_MINIMUM when aggregate undercounts vs visible rows)

FINANCE EFFECT:
0

AUTHORITATIVE WRITE:
0  
(UI presentation only — not fed into finance / reports / settlements / exports / server decisions)

================================
REGRESSION
================================

F03:
PASS (`security_f03_f07_guard.sh` + `agent_handoff_security_f03_f07.test.js`)

F07:
PASS

C3:
PASS (`agent_country_assignment.test.js` — one-active-agent-per-country)

ACCOUNTANT:
PASS (`admin_accountant_rbac_f3b2_test.dart`)

CROSS COUNTRY:
0 (KY→India / KY→Spain DENY on CF + Rules)

NEW FAILURES:
0  
(tests: panel_user_country_lock 8, agent_create_security_gate 9, F03/F07, phase_8a, C3, Flutter agent runtime + accountant)

================================
DEPLOYMENT
================================

RULES:
YES (`firestore.rules` released; helpers `countryRefMatchesClaim`, `mkanCreateInClaimCountry`, `panelCanProvisionUser` claim-ref)

FUNCTIONS:
`createPanelUser` only  
- WHY: Admin SDK bypasses Rules; country lock + privileged elevation deny must be live  
- OLD LIVE HASH: `4ef7a1059dcc20874149a74c22b9670fd990aee6`  
- NEW SOURCE/LIVE HASH: `91476bdccb81b7d17f976a9203ab6888c6d97e68`  
- EXPECTED DELTA: `panel_user_country_lock.js` force `Rev_dolh` from claims; reject foreign; reject privileged roles; driver `transport_company` exception for country_admin only

ADMIN WEB:
NO (prod Render unchanged; preview channel still carries UI runtime fix)

I18N:
UNCHANGED (not merged)

================================
SAFARI SMOKE
================================

- Safari.app opened to preview:  
  `https://tutorial-multi-language-70gx4j--admin-agent-runtime-fi-cxiz9w2f.web.app/admin/`
- WebKit engine probe (Agent token): Users / Drivers / Landmarks / Bookings — **no** raw `permission-denied` / false network strings  
- Flutter canvas DOM text not scraped (empty `innerText`); no create clicks / no persistent fixtures  
- Prior gate: UI runtime **PASS** at `41b03e8`

================================
FINAL
================================

AGENT_CREATE_SECURITY_PRODUCTION:
PASS

AGENT_RUNTIME:
PASS

READY_FOR_AGENT_HANDOFF:
YES

READY_FOR_I18N_INTEGRATION:
YES

STOP.
