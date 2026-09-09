# Admin Master String Inventory

Generated during ADMIN_I18N_AZ_REPAIR.

## Sources
- `kTranslationsMap` (FlutterFlow)
- `kAdminTranslations` / `kEnterpriseTranslations` / `kNavTranslations`
- `kUiCatalog` + `kArabicUiLookup` (`uiTr`)

## Counts
- Canonical ui catalog keys: **1845**
- Supported locales: ar, en, ru, ky, fr, ur, pt
- Remaining Arabic literals outside uiTr/appTr (approx, includes seed/demo/constants): **1065**

## Classification (repair target)
| Class | Notes |
|---|---|
| LOCALIZED_KEY | Stable keys via appTr / FF map / ui catalog |
| HARDCODED_AR | Migrated to uiTr where reasonably migratable; finance label constants remain Arabic canonical keys resolved via uiTr |
| HARDCODED_EN | Reduced; FF Arabic-in-EN cleared to 0 |
| RAW_ENUM | Presentation via AdminBookingStatusLabel / FinancialStateLabels / admin_status_localization |
| TECHNICAL_INTERNAL | IDs/emails/URLs unchanged |
| EMPTY_TRANSLATION | Gate = 0 |
| FALLBACK_ONLY | ky may still fall back to ru/en at runtime for unknown keys; validator forbids empty required keys |

## Exceptions
See `ADMIN_I18N_EXCEPTIONS.md`.
