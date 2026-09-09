# Admin i18n Exceptions

## Documented exceptions (this phase)

### 1. Arabic canonical label constants
Files such as:
- `lib/core/admin_booking_status_label.dart`
- `lib/core/finance/financial_state_labels.dart`
- `lib/core/finance/accountant_finance_labels.dart`
- related settlement/reconciliation label helpers

Keep **Arabic canonical strings** as internal presentation keys.
UI must resolve via `uiTr` / `*.localized(...)` helpers.
Internal enums/codes remain unchanged.

### 2. Context-free adapters / pure Dart layers
Examples:
- `admin_booking_details_adapter.dart` timeline labels (no `BuildContext`)
- `backend/firebase_storage/storage.dart` messages without UI context

These remain Arabic canonical until a later pass threads `BuildContext` or `FFLocalizations` without changing behavior.

### 3. Seed / demo / production seed datasets
`admin_production_seed_data.dart`, `admin_demo_seed.dart`, landmark seeds — not Admin UI chrome.
Demo marker IDs like `DEMO-CASH-010` unchanged.

### 4. Layer maps still containing English copies in fr/pt (subset)
`admin_translations` / `nav_translations` / `enterprise_translations` already have full keys for all 7 locales.
Some fr/pt values historically equal EN (acceptable for brand/shared tokens; remaining phrase gaps tracked for human language QA).

### 5. Runtime fallback
`FFLocalizations.getText`: ky → ru → en.
Validator forbids empty/missing required keys even if fallback would render.

### 6. Visual / overflow / dark-mode / full role×locale matrix
Not fully screenshot-gated in this phase. Preview channel + human language QA required.

### 7. Password reauthentication logic
Localized copy only. Old-password / reauth behavior unchanged (existing P1).

### 8. Business logic bugs found via i18n
None fixed in this phase (security/finance frozen).
