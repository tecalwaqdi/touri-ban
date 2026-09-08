# TOURi TAXI — Admin i18n A→Z Repair Report

**Branch:** `recovery/admin-i18n-az-repair`  
**Base:** `origin/main` @ `c7627915997e3a916d056dd033fd7ccd379b2468`  
**Security:** FROZEN (Rules / Functions / Payment / finance / RBAC unchanged)

## Architecture

See `ADMIN_LOCALIZATION_ARCHITECTURE.md`.

| Item | Value |
|---|---|
| Engine | FFLocalizations + uiTr/appTr (no second framework) |
| Supported | ar, en, ru, ky, fr, ur, pt |
| Default | Device locale if supported, else en |
| Fallback | locale → (ky: ru) → en; uiTr → Arabic literal |
| Persistence | SharedPreferences `__locale_key__` + `__locale_user_picked__` |
| RTL | Locale-driven (`ar`, `ur`) |

## Work completed

1. Clean branch from frozen security tip.
2. Master inventory + glossary + coverage docs.
3. Cleared Arabic values inside English FF map (**0** remaining).
4. Expanded `kUiCatalog` / `kArabicUiLookup` to **1845** keys covering uiTr literals + finance/status label canons.
5. Bulk translation pipeline (`tool/i18n/*`) with poison repair for Google 500 contamination.
6. Status/error helpers: `admin_status_localization.dart`; localized wrappers on booking/finance labels.
7. Hardcoded UI wraps where `BuildContext` available (finance reconciliation columns, hub filters, etc.).
8. Strict validator + Flutter test gate.
9. Security F03/F07 guard re-run: **PASS**.

## Metrics

| Metric | Value |
|---|---|
| TOTAL USER-FACING UI CATALOG KEYS | 1845 |
| EN ARABIC VALUES BEFORE | ~52 |
| EN ARABIC VALUES AFTER | 0 |
| AR/EN/RU/KY/FR/UR/PT MISSING (validator) | 0 |
| EMPTY VALUES | 0 |
| UITR LOOKUP GAPS | 0 |
| FLUTTER ANALYZE ERRORS | 0 |
| TRANSLATION VALIDATOR | PASS |
| SECURITY GUARD | PASS |

## Quality notes

Machine-assisted translations were glossary-overlaid for finance terms and poison-scrubbed.  
Human language QA remains required for ky/fr/pt/ur nuance and long-label overflow.

## Deployment

- MAIN MERGED: **NO**
- PRODUCTION: **NO**
- RULES / FUNCTIONS / PAYMENT API: **UNCHANGED**

## Final

**ADMIN_I18N_AZ: READY_FOR_HUMAN_QA**  
**NEXT: HUMAN_LANGUAGE_QA** on preview channel `admin-i18n-az`.
