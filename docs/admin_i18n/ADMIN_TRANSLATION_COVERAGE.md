# Admin Translation Coverage

## TOTAL REQUIRED KEYS (ui catalog)
1845

## Locale parity (validator)
| Locale | Missing | Empty | Arabic-in-value (EN/LTR fallback) |
|---|---|---|---|
| ar | 0 | 0 | n/a |
| en | 0 | 0 | 0 |
| ru | 0 | 0 | 0 identical-to-ar |
| ky | 0 | 0 | 0 identical-to-ar |
| fr | 0 | 0 | 0 identical-to-ar |
| ur | 0 | 0 | n/a (RTL script) |
| pt | 0 | 0 | 0 identical-to-ar |

## Layer maps
- admin_translations / nav_translations / enterprise_translations: gaps same-as-EN filled in this repair
- FF kTranslationsMap: Arabic values in EN cleared (0)

## Validator
`admin/Admi/tool/i18n/validate_admin_translations.py`
`admin/Admi/test/i18n/admin_translation_validator_test.dart`
