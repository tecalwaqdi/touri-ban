# TOURi TAXI — ADMIN FINAL RENDER RELEASE

**DATE:** 2026-09-09  
**PRODUCTION:** https://touri-ban-1.onrender.com/  
**MODE:** Admin web only (no Rules / Functions / Payment API deploy)

---

## Source

| Item | Value |
|---|---|
| OLD MAIN | `0d5d6c00357a294473efb58b5aa4d6943c09946c` |
| FINAL MAIN | `912d1dee9c5127bcd3c6061ce1a0bb55f46e4a57` |
| VERIFIED I18N/AUTH SOURCE | `702332611de28e6cd4b30110b2b0282cdf7ea641` |
| RELEASE BRANCH | `release/admin-final-render` |
| GATE FIX ON TOP OF 7023326 | `912d1de` — panel load-timeout `uiTr` catalog entry |

`origin/main` advanced only with this release (no intervening main commits between `0d5d6c0` and integration).

---

## Integration

| Check | Result |
|---|---|
| Strategy | Clean worktree from `origin/main` → `merge --no-ff` of `7023326` → catalog gate fix |
| CONFLICTS | **0** |
| BACKEND FILES CHANGED | **0** (no Rules / Functions / Payment API) |
| UNRELATED CHANGES | **0** |
| AGENT RUNTIME (main security parity) | **PASS** (preserved from `0d5d6c0`) |
| AUTH SESSION | **PASS** |
| I18N | **PASS** |

### Inventory (admin-only)

- **I18N:** catalogs, FF locale maps, KY/FR/PT resolution, terminology (سائق/Водитель/Chauffeur)
- **AUTH/SESSION:** panel-home decision, token debounce, transient profile ignore
- **ROLE/SCOPE:** none-role bootstrap retry, scope ready after bootstrap, `ensureScopeReady`
- **LOCALIZED TEXT:** Drivers subtitle / أضف سائقًا / Resolving role / Gallery
- **FONT:** Safari Cairo path (from verified lineage; no new font edits this release)
- **TESTS / DOCS:** auth+locale, runtime locale, translation validator, Round 3 QA docs

Finance file touches in the verified delta are **labels / `uiTr` only** (not formulas or settlement semantics).

---

## Tests (pre-merge + fresh clone)

| Gate | Result |
|---|---|
| FLUTTER ANALYZE | **PASS** (0 errors; pre-existing infos/warnings only) |
| FLUTTER TEST | **PASS** (`+556 ~2`) |
| AUTH | **PASS** |
| ROUTER / panel home policy | **PASS** |
| I18N validator + runtime locale | **PASS** |
| SECURITY source (Rules/Functions unchanged) | **PASS** |
| FRESH CLONE | **PASS** (`/tmp/touri-ban-admin-final-fresh` @ `912d1de`) |
| NEW FAILURES | **0** (one gate miss fixed before merge: catalog `تعذر تحميل لوحة التحكم`) |

---

## Provenance (local build of FINAL MAIN)

| Field | Value |
|---|---|
| VERSION | `1.0.17` |
| BUILD NUMBER | `2021` |
| FINAL MAIN SHA | `912d1dee9c5127bcd3c6061ce1a0bb55f46e4a57` |
| BUILD SHA | `912d1dee9c5127bcd3c6061ce1a0bb55f46e4a57` |
| SOURCE MATCH | **YES** |
| Flutter / Engine | `3.44.8` / `0cd610717bde95fd88343c64f81c11ba4e5c0010` |
| base_href | `/` (Render) |

---

## Render

| Field | Value |
|---|---|
| SERVICE NAME | `touri-ban-1` |
| SERVICE ID | `srv-da8eg6jbc2fs73a18eh0` |
| TYPE | Static Site |
| BRANCH | `main` |
| ROOT DIRECTORY | `admin/Admi` |
| BUILD COMMAND | `bash scripts/render_build.sh` |
| PUBLISH DIRECTORY | `build/web` |
| OLD DEPLOY (rollback) | `dep-daf842on74is738pmge0` @ `d50d620` (`1.0.17+2021`) |
| NEW DEPLOY | `dep-dagb96qjnfac7389kpk0` |
| DEPLOYED SHA | `912d1dee9c5127bcd3c6061ce1a0bb55f46e4a57` |
| DEPLOY STATUS | **LIVE** |
| CLEAR CACHE | Yes |
| LIVE PROVENANCE | `https://touri-ban-1.onrender.com/build_provenance.json` → **MATCH** |

**Payment API** `touri-ban` / `srv-d9raia710e5c73fk86mg` — **NOT deployed** (last live still prior commit).

---

## Production smoke

Evidence: `docs/releases/prod_smoke/`

### Auth

| Role | Result |
|---|---|
| SUPER ADMIN | **PASS** |
| ACCOUNTANT | **PASS** (Finance Hub → Audit / Agents routes; writes **0**) |
| COUNTRY AGENT (KG) | **PASS** (ops routes); `/adminFinanceHub` → `/home22Dashboard` (**DENY** global finance) |
| LOADER STUCK | **0** |
| UNEXPECTED LOGOUT / LOGIN REDIRECT | **0** |

Safari.app: production URL opened; Country Agent dashboard captured (`safari_prod_home.png`). Chromium injection used for full 3-role matrix.

### Languages / viewports / security

| Check | Result |
|---|---|
| AR EN RU KY FR UR PT (auth-stable) | **PASS** |
| AR TOFU / UR TOFU | **0** / **0** (reviewed) |
| 1440 / 1280 / 1024 / 768 | **PASS** |
| 390 | **PASS / ADMIN_FALLBACK_ONLY** |
| F03 / F07 / C3 / CREATE SECURITY | **PASS** (unchanged backend; Agent cross-country **0**) |
| ACCOUNTANT WRITES | **0** |
| CROSS COUNTRY | **0** |

Text defects previously fixed remain corrected on production Drivers: **السائقون** / **أضف سائقًا** (no مناديب / برنامج تشغيل on that surface).

---

## Backend

| Deploy | Result |
|---|---|
| RULES | **NO** |
| FUNCTIONS | **NO** |
| PAYMENT API | **NO** |
| Firebase Hosting production | **NO** (preview QA only) |

---

## Rollback

| Item | Value |
|---|---|
| ROLLBACK READY | **YES** |
| ROLLBACK TARGET | `dep-daf842on74is738pmge0` (`d50d620`) |
| ROLLBACK USED | **NO** |

---

## Final

| Gate | Status |
|---|---|
| ADMIN_RENDER_PRODUCTION | **PASS** |
| READY_FOR_REAL_AGENTS | **YES** |
| READY_FOR_NORMAL_OPERATION | **YES** |
