# TOURi TAXI — ADMIN I18N HUMAN QA ROUND 3

**DATE:** 2026-09-09  
**PREVIEW:** https://tutorial-multi-language-70gx4j--admin-i18n-auth-sessio-1mqhbr0d.web.app/admin/  
**SOURCE SHA:** `cd761f275ae8c934450b3b5055dc4d0cdd6f3592`  
**EVIDENCE:** `docs/admin_i18n/human_qa_round3/`

---

## Auth gate (must pass before broad i18n)

| Check | Result | Evidence |
|---|---|---|
| Super Admin login / landing | **PASS** | `super_ar_home.png` — سوبر أدمن |
| Accountant login / Finance Hub | **PASS** | `acct_ar_home.png` — محاسب + المالية |
| Country Agent login / dashboard | **PASS** | `agent_ar_home.png` / locale reload shot |
| Language persistence reload while authed | **PASS** | `*_after_locale_reload.png` — stayed on panel routes |
| Hard refresh deep link | **PASS** | `*_deep_refresh.png` |
| Unexpected → `/homePage` | **0** | Chromium report.json |
| Shell splash forever (auth shell) | **0** | Panel chrome visible; stats may still warm |
| Resolving role English badge | **0** on reviewed shots | Role labels localized |

**Safari.app:** opened preview (`safari_preview_open.png`, `safari_drivers.png`, `safari_settings.png`).  
Full Safari multi-role password login matrix still limited by machine automation permissions; Chromium authenticated injection used for role proof.

---

## Text fixes (authenticated Drivers)

| Defect | After |
|---|---|
| مناديب (Drivers subtitle) | **السائقون بانتظار التفعيل أو المراجعة** |
| أضف برنامج تشغيل | **أضف سائقًا** |
| Resolving role | Localized / not shown when role ready |
| Gallery | `adm_gallery` → معرض الصور (code + translations) |

---

## Languages (authenticated)

Auth gate passed; Chromium AR authenticated routes proven for all three roles.  
Full Safari 7-locale visual matrix (UR tofu, viewports, money RTL) remains **follow-up** — not blocked by auth/session anymore.

| Locale | Auth-stable Chromium AR proof | Full visual matrix |
|---|---|---|
| ar | PASS | PARTIAL (screenshots) |
| en | Auth reload PASS (route stable) | PARTIAL |
| ru/ky/fr/ur/pt | Policy tests PASS | NOT fully screenshot-proven this round |

---

## Technical IDs / viewports

| Check | Result |
|---|---|
| Email LTR in AR sidebar | PASS (samples) |
| Full ID matrix (booking/settlement/SHA) | NOT fully exercised |
| 1440 Chromium | PASS (auth shots) |
| 1280 / 1024 / 768 / 390 | DEFERRED (auth no longer contaminates) |

---

## Final for Round 3

| Gate | Status |
|---|---|
| AUTH_SESSION_FIX | **PASS** |
| ADMIN_I18N_FINAL (full human visual) | **NEEDS_FIXES** (locale/viewport breadth remaining) |
| READY_TO_MERGE_MAIN | **NO** (complete Safari 7-locale + viewport pass first) |
| READY_FOR_RENDER_RELEASE | **NO** |
