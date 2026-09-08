# TOURi TAXI — ADMIN I18N HUMAN QA

**MODE:** QA only (read-only for product source)  
**DATE:** 2026-09-08  

## Source verification

| Check | Result |
|---|---|
| Branch | `recovery/admin-i18n-az-repair` |
| `git rev-parse HEAD` | `e111dd00dacbcd7ea35876afccdb104bccf8b4f0` |
| Approved commit | `e111dd0` **MATCH** |
| Pre-QA porcelain | **CLEAN** (untracked leftover removed before gate) |
| Product source edits during QA | **0** (hosting build artifacts local-only; QA tooling package bumps reverted) |

## Preview deploy

| Item | Value |
|---|---|
| Build script | `bash scripts/build_web_admin.sh /admin/` (pinned Flutter 3.44.8) |
| Build SHA in provenance | `e111dd00dacbcd7ea35876afccdb104bccf8b4f0` |
| Channel | `admin-i18n-az` |
| PREVIEW | https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin/ |
| Expires | 2026-09-22 |
| Production changed | **NO** |
| Rules / Functions / Payment API | **UNCHANGED** |

## Automated gates on this commit

| Gate | Result |
|---|---|
| `flutter analyze` errors | **0** |
| `flutter test` | **FAIL** — 6 failures on `e111dd0` (see below) |
| Translation validator | **PASS** (reconfirmed earlier on commit) |
| F03/F07 guard script | **PASS** |

### Flutter test failures observed on `e111dd0` (not fixed in this QA)

1. `admin_driver_expiry_adapter_test` — `uiTr` / `FFLocalizations.of` null (widget without localization delegates)
2. `admin_enterprise_states_test` — search clear/debounce widget finders
3. `phase_8a_csv_errors_test` — expects English CSV disclaimer phrase `not a tax invoice`
4. `admin_format_role_matrix_test` — Settlements/finance approve matrix assertion
5. `finance_f2_1_consistency_test` — light surface ink contrast expectation

These are **release blockers for merge** even where visual login QA passes.

## Evidence store (not committed)

`/tmp/admin_i18n_human_qa/`

Examples:

- `chromium/{ar,en,ru,ky,fr,ur,pt}/login_*.png`
- `webkit/{en,ar,fr,ur}/login_1440.png`
- `safari_actual/login_desktop.png`

**ACTUAL HUMAN VISUAL REVIEW:** **YES** (screenshots inspected via image review for login across locales/browsers).

**AUTHENTICATED ROUTE VISUAL REVIEW:** **NO** — `ADMIN_QA_*` credentials not available in environment; Super Admin / Accountant / Agent deep routes not exercised live.

---

# TOURi TAXI — ADMIN I18N HUMAN QA

SOURCE: `e111dd00dacbcd7ea35876afccdb104bccf8b4f0`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin/

================================
BROWSERS
================================

CHROMIUM: **PASS** (login captures + visual review)

WEBKIT: **PASS** (login captures; FR English leakage same as Chromium)

SAFARI ACTUAL: **FAIL** (opened real Safari.app; Arabic placeholders/button/header rendered as empty tofu boxes `□□□` while Chromium Arabic was fine — font/glyph issue or asset load failure)

================================
VIEWPORTS
================================

1440: **PASS** (login)

1280: **PARTIAL** (captured for some locales during matrix; no overflow seen on login)

1024: **PASS** (login)

768: **PASS** (login)

390: **PASS** (EN login only) / **ADMIN_FALLBACK_ONLY** for other locales (not fully matrixed)

================================
LANGUAGES (LOGIN SURFACE — visual)
================================

AR: **PASS** on Chromium/WebKit login RTL; **FAIL** on Safari Actual glyph rendering

EN: **PASS** (no Arabic visible on login)

RU: **PASS** (fully Russian login)

KY: **FAIL** (selector = Кыргызча, but most chrome remains Russian — RU fallback / incomplete login localization)

FR: **FAIL** (selector = Français; only title “Panneau de contrôle” localized; rest English)

UR: **PASS** on Chromium login RTL Urdu (no Arabic-only copy spotted on login)

PT: **FAIL** (selector = Português; only “Painel de controle” localized; rest English)

================================
LINGUISTIC
================================

### AR BLOCKERS
1. **Safari Actual glyph tofu** on login placeholders/button/header — route `/admin/` — severity **BLOCKER**
2. Catalog still mixes Driver terms (`مندوب`/`المناديب` heavily vs preferred `السائق`) — severity **MAJOR** (product-wide terminology)

### EN BLOCKERS
- Login: **0** Arabic visible  
- Catalog static: English “flight financial data” phrasing / awkward finance strings remain for later fix pass — **MAJOR** (not login-visible)

### RU BLOCKERS
- Login: none observed  
- Catalog: `المناديب` → `Драйверы` (anglicism; prefer `Водители`) — **MAJOR**

### KY BLOCKERS
1. Login mostly Russian while language = Кыргызча — **BLOCKER** for “selected language shown”
2. Several catalog strings identical to Russian — **MAJOR**

### FR BLOCKERS
1. Login mostly English while language = Français — **BLOCKER**
2. Catalog `المناديب` → `Pilotes` (wrong; should be `Chauffeurs`) — **MAJOR**
3. `مالية الوكلاء` → `Financement des agents` (awkward vs “Finance agents”) — **MAJOR**

### UR BLOCKERS
- Login Chromium: none observed  
- Safari Actual not separately proven for Urdu in this pass — **UNKNOWN / incomplete**

### PT BLOCKERS
1. Login mostly English while language = Português — **BLOCKER**

================================
DIRECTION
================================

AR RTL: **PASS** (Chromium/WebKit login)

UR RTL: **PASS** (Chromium login)

LTR LOCALES: **PASS** (EN/RU/FR/PT/KY login layout)

TECHNICAL IDS: **NOT PROVEN** (no authenticated ID tables reviewed — credentials missing)

================================
CONTENT
================================

ARABIC VISIBLE IN EN (login): **0**

FALLBACK HITS (visual login): **>0** — KY→RU, FR→EN, PT→EN on core login chrome

RAW ENUMS (login): **0**

EMPTY LABELS: Safari AR tofu counts as empty/unreadable — **FAIL**

WRONG LANGUAGE STRINGS: **YES** on FR/PT/KY login

================================
LAYOUT
================================

TEXT OVERFLOW (login reviewed): **0**

RENDERFLEX OVERFLOW (login reviewed): **0** observed

CRITICAL CLIPPING (login): **0** on Chromium/WebKit; Safari AR unreadable glyphs

SIDEBAR ACTIVE ERRORS: **NOT PROVEN** (auth required)

TABLE DATA LOST: **NOT PROVEN** (auth required)

================================
LANGUAGE SWITCH
================================

SWITCH: **PARTIAL** (dropdown shows native names; selected locale does not fully re-localize FR/PT/KY login)

HARD REFRESH: **NOT FULLY PROVEN**

DEEP LINK: **NOT PROVEN**

LOGOUT/LOGIN: **NOT PROVEN** (no auth)

PERSISTENCE: **PARTIAL** (locale init via SharedPreferences keys works for AR/EN/RU/UR)

AUTH REGRESSION: **0** observed on login-only (no sign-out induced by locale init in probes)

================================
DARK MODE
================================

AR/EN/RU/KY/FR/UR/PT: **NOT PROVEN** (login light mode only; auth required for app chrome)

================================
SECURITY
================================

ACCOUNTANT WRITES: **0** (no write attempts; guard script PASS)

CROSS COUNTRY LEAKAGE: **0** (no live cross-country UI probe; guard script PASS)

F03: **PASS** (static guard)

F07: **PASS** (static guard)

C3: **PASS** (unchanged / not re-broken by this QA; no assignment writes)

Live role matrix (Super Admin / Accountant / Agent UI): **NOT EXECUTED** — credentials unavailable

================================
EVIDENCE
================================

SCREENSHOTS: `/tmp/admin_i18n_human_qa/**` (≥17 Chromium login shots + WebKit samples + Safari Actual desktop capture)

ACTUAL HUMAN VISUAL REVIEW: **YES** (login)

AUTHENTICATED APP REVIEW: **NO**

================================
SOURCE
================================

SOURCE MODIFICATIONS DURING QA: **0** product code  
MAIN MERGED: **NO**  
PRODUCTION: **NO**

================================
FINAL
================================

ADMIN_I18N_HUMAN_QA: **NEEDS_FIXES**

READY_TO_MERGE_MAIN: **NO**

NEXT: **I18N_FIX_FINDINGS**

### Required before merge
1. Fix FR/PT/KY login + chrome strings that still fall back to EN/RU despite locale selection.
2. Fix Safari Arabic font/glyph rendering (tofu).
3. Resolve `flutter test` failures on `e111dd0` (esp. `uiTr` without `FFLocalizations`).
4. Re-run authenticated human QA (Super Admin + Accountant + Agent) with safe credentials on preview.
5. Terminology pass: Driver = السائق / Chauffeur / Водитель (retire مندوب/Pilotes/Драйверы where same concept).

STOP.
