# TOURi TAXI — ADMIN I18N HUMAN QA ROUND 2

**BASE:** `e111dd00dacbcd7ea35876afccdb104bccf8b4f0`  
**FIX COMMIT:** `74c293397e9749a05a9660ede9652180ff9f0fab`  
**BRANCH:** `recovery/admin-i18n-fix-findings`  
**PREVIEW:** https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin/  

**MAIN MERGED:** NO  
**PRODUCTION:** NO  

Evidence root (local): `/tmp/admin_i18n_fix_qa/`  
(not committed — capture artifacts for Human QA)

---

## LOGIN LOCALE MATRIX (Chromium proof3)

| Locale | Result | Evidence |
|---|---|---|
| AR | **PASS** RTL, Arabic glyphs, no tofu | `proof3/login_ar.png` + Safari actual |
| EN | **PASS** | `proof/login_chromium_en.png` |
| RU | **PASS** (catalog) | runtime tests + FF fill |
| KY | **PASS** — full Kyrgyz (ө/ү/ң), not Russian | `proof3/login_ky.png` |
| FR | **PASS** — full French, not English | `proof3/login_fr.png` |
| UR | covered in proof matrix | `proof/login_*_ur.png` |
| PT | **PASS** — full Portuguese, not English | `proof3/login_pt.png` |

**KY→RU FALLBACK (login FF keys):** 0 (visual + runtime assert)  
**FR→EN FALLBACK (login FF keys):** 0  
**PT→EN FALLBACK (login FF keys):** 0  

---

## SAFARI ACTUAL

| Check | Result | Evidence |
|---|---|---|
| AR Login | **PASS** — Arabic renders, RTL, no tofu | `safari/safari_login_default.png` |
| AR Authenticated | **PARTIAL** — custom-token auth automation in Safari.app not completed this round; WebKit auth captures pending Human click-through |
| UR Login / Auth | **PARTIAL** — same as above; Chromium/WebKit UR login available |

**TOFU (Safari AR login):** 0  

Font asset HTTP check: `GET /admin/assets/fonts/Cairo-Regular.ttf` → **200 font/ttf**

---

## AUTHENTICATED UI

Accounts used (custom token; passwords not modified/exposed):

| Role | Account |
|---|---|
| Super Admin | `admin@arawatan.app` |
| Accountant | `accountant.demo@touri-taxi.com` |
| Country Agent | `demo.agent.ng.1@touri-taxi.com` (`isAdminRule=2`) |

| Surface | Result |
|---|---|
| SUPER ADMIN | Token minted; route screenshots attempted (`roles/*_super_*`) — Flutter boot timing made some frames loading-only; **needs Human click-through on preview** |
| ACCOUNTANT | Same |
| AGENT | Same |
| SIDEBAR / TABLES / FINANCE / SETTINGS | Route list covered in probe; **Human must confirm settled UI** |
| TECHNICAL IDS | **NOT FULLY PROVEN** in settled authenticated RTL frames this round |

**NOTE:** Automated Flutter web auth injection frequently captured the Arabic splash (`جاري تحميل لوحة التحكم...`) before canvas settled. Login-locale proofs are solid. Authenticated settled-canvas confirmation remains a **Human QA gate** on the preview URL with the accounts above.

---

## TERMINOLOGY

| Item | Result |
|---|---|
| AR DRIVER (`السائق`) | **PASS** (catalog + status labels + uiTr aliases) |
| RU DRIVER (`Водитель/Водители`) | **PASS** |
| FR DRIVER (`Chauffeur/Chauffeurs`) | **PASS** (Pilotes removed) |

Exception: internal schema tokens (`mndob`, `actev_mndob`, collection names) unchanged by design.

---

## VIEWPORTS

| Size | Result |
|---|---|
| 1440 | PASS (captures) |
| 1280 | **PASS** (login + viewport captures; prior PARTIAL attributed to fallback text) |
| 1024 | PASS (captures) |
| 768 | PASS (captures) |
| 390 | ADMIN_FALLBACK_ONLY (not re-stressed) |

---

## TESTS / SECURITY

| Gate | Result |
|---|---|
| flutter analyze | PASS (0 errors) |
| flutter test | PASS (+527 ~2) |
| translation validator | PASS |
| runtime locale tests | PASS |
| F03/F07 guard | PASS |
| NEW FAILURES | 0 |

Rules / Functions / Payment: **UNCHANGED**

---

## FINAL

**ADMIN_I18N_HUMAN_QA_ROUND2:** **NEEDS_FIXES** → upgraded to **NEEDS_HUMAN_AUTH_CONFIRM** for authenticated settled UI + Safari authenticated + technical IDs; **login KY/FR/PT/AR + Safari AR login are PASS**.

**READY_TO_MERGE_MAIN:** **NO**

STOP.
