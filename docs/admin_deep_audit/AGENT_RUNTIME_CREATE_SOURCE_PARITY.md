# TOURi TAXI — AGENT RUNTIME/CREATE SOURCE PARITY

**Date:** 2026-09-08  
**Repo:** https://github.com/tecalwaqdi/touri-ban.git  
**Branch:** `recovery/main-agent-runtime-security-parity`  
**Firebase:** `tutorial-multi-language-70gx4j`  
**Worktree:** `/Users/ventura/ara-ban-agent-parity` (clean from `origin/main`)

OLD MAIN:
`c7627915997e3a916d056dd033fd7ccd379b2468`

NEW MAIN:
`8fdd4799c39231310b42f7c2b869341d9d06ff14`

ORIGIN MAIN (pre-merge recorded):
`c7627915997e3a916d056dd033fd7ccd379b2468`

================================
COMMITS
================================

RUNTIME COMMIT:
`c8db406137d7f863fda4e2f62b2c0a6fc53fb29c` — `fix(admin): stabilize country agent runtime`

CREATE SECURITY COMMIT:
`8fdd4799c39231310b42f7c2b869341d9d06ff14` — `fix(security): persist agent create country enforcement`

================================
INVENTORY
================================

RUNTIME FILES:
- `admin/Admi/lib/**` Agent runtime UI/query/error/sidebar/Filters/terminology/create RBAC
- `admin/Admi/test/agent_runtime_ui_findings_test.dart`
- `admin/Admi/test/core/admin_shell_rules_test.dart`
- `docs/admin_deep_audit/AGENT_RUNTIME_UI_FINDINGS.md`
- Intermediate Rules list/get Reference equality (then superseded by create-security tip)

RULES FILES:
- `admin/Admi/firebase/firestore.rules`
- `admin/ara_oatan_app/firebase/firestore.rules`
- `admin/mndob-main/firebase/firestore.rules`  
  (byte-identical; live SHA1 `7740346499cf69d74f5fc2a3cad6d962d3936641`)

FUNCTION FILES:
- `admin/Admi/firebase/functions/panel_user_country_lock.js`
- `admin/Admi/firebase/functions/index.js` (`createPanelUser` lock + driver `transport_company` exception)
- `admin/Admi/firebase/functions/test/panel_user_country_lock.test.js`
- `admin/Admi/firebase/functions/test/agent_create_security_gate.test.js`
- `docs/admin_deep_audit/AGENT_CREATE_SECURITY_DEPLOY_GATE.md`

UNRELATED FILES (excluded):
- `admin/Admi/firebase/hosting_public/admin/.last_build_id`
- i18n branch / lang dumps
- Africa geo / customer remapping local-main-only commits
- demo finance worktrees

================================
LIVE PARITY
================================

RULES MAIN VS LIVE:
MATCH  
(source SHA1 == live identifier `7740346499cf69d74f5fc2a3cad6d962d3936641`)

createPanelUser MAIN VS LIVE:
SEMANTIC_MATCH  
(live deploy hash `91476bdccb81b7d17f976a9203ab6888c6d97e68` was built from this source set:  
`applyCountryAdminCreateLock`, force `Rev_dolh`, foreign DENY, privileged DENY, driver `transport_company` exception.  
Zip revision number not re-created — no redeploy.)

DEPLOYED-ONLY SECURITY CODE:
0

================================
CREATE SECURITY
================================

USER COUNTRY:
SERVER_FORCED

DRIVER COUNTRY:
SERVER_FORCED

LANDMARK COUNTRY:
SERVER_VALIDATED

REGION/CITY:
PASS

DIRECT BYPASS:
DENY

Matrix (repo unit + prior live probes):
- KY→KY User ALLOW | KY→India/Spain DENY | privileged DENY  
- KY→KY Driver ALLOW | foreign Driver DENY  
- KY Landmark ALLOW | foreign Landmark DENY | foreign region hierarchy DENY

================================
RUNTIME
================================

BOOKINGS:
PASS

USERS:
PASS

DRIVERS:
PASS

SUPPORT:
PASS

NOTIFICATIONS:
PASS

DOCUMENT EXPIRY:
PASS

LANDMARKS:
PASS

TOURIST GUIDES:
PASS

COUNTRY FINANCE:
PASS

SETTINGS:
PASS

RAW FIREBASE ERRORS:
0

FALSE NETWORK ERRORS:
0

SIDEBAR ACTIVE ERRORS:
0

BOOKING DISPLAY FLOOR:
DISPLAY_SAFE_MINIMUM (presentation only)  
FINANCE EFFECT: 0  
AUTHORITATIVE WRITE: 0  
(`sanitizeTotal` only in bookings widget + unit test; absent from Functions/finance)

================================
REGRESSION
================================

F03:
PASS

F07:
PASS

C3:
PASS

ACCOUNTANT:
PASS

CROSS COUNTRY:
0

================================
TESTS
================================

FLUTTER ANALYZE:
PASS (no errors; pre-existing `info` deprecations only — `--no-fatal-infos`)

FLUTTER TEST:
PASS (`agent_runtime_ui_findings`, `admin_shell_rules`, accountant RBAC, agent finance route RBAC)

RULES:
PASS (guard + static F03/F07 + create gate markers)

FUNCTIONS:
PASS (`panel_user_country_lock`, `agent_create_security_gate`, F03/F07, C3 assignment)

NEW FAILURES:
0

================================
REPRODUCIBILITY
================================

FRESH CLONE:
PASS  
(depth-1 clone of `origin/main` @ `8fdd479`; clean tree; Rules SHA match live; create lock present; F03/F07/C3 + createPanelUser tests PASS)

UNTRACKED DEPENDENCIES:
0

DEPLOYED-ONLY SOURCE:
0

================================
DEPLOYMENT
================================

RULES DEPLOY:
NO  
(Reason: live already secured; source now MATCH)

FUNCTION DEPLOY:
NO  
(Reason: live already secured; source SEMANTIC_MATCH)

ADMIN WEB DEPLOY:
NO

================================
FINAL
================================

AGENT_SOURCE_PARITY:
FROZEN

READY_FOR_AGENT_HANDOFF:
YES

READY_FOR_I18N_INTEGRATION:
YES

NEXT:
I18N_FIX_FINDINGS

STOP.
