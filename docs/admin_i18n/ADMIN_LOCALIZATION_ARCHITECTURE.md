# Admin Localization Architecture

## LOCALIZATION ENGINE
FlutterFlow `FFLocalizations` (`lib/flutter_flow/internationalization.dart`) with layered maps:

1. `kTranslationsMap` — FlutterFlow-generated widget keys
2. `kAdminTranslations` — shared admin chrome (`lib/l10n/admin_translations.dart`)
3. `kEnterpriseTranslations` — enterprise/finance kit (`lib/l10n/enterprise_translations.dart`)
4. `kNavTranslations` — sidebar/navigation (`lib/l10n/nav_translations.dart`)
5. `kUiCatalog` — Arabic-literal lookup catalog (`lib/l10n/ui_catalog.dart`)

Runtime helpers:

- `appTr(context, key)` / `entTr(context, key)` → stable key lookup
- `uiTr(context, arabicLiteral)` → `kArabicUiLookup` → `kUiCatalog` key → locale value (fallback: Arabic literal)

## SUPPORTED LOCALES
`en`, `ar`, `ru`, `ky`, `fr`, `ur`, `pt`

Declared by `FFLocalizations.languages()`.

## DEFAULT LOCALE
Device locale when supported; otherwise **English**.

`resolveInitialLocale()`:

1. If user previously picked a locale (`__locale_user_picked__`) → stored locale
2. Else `resolveDeviceLocale()` → supported language code or `en`

## FALLBACK
`FFLocalizations.getText`:

1. Requested locale value
2. If `ky` missing → `ru` then `en`
3. Else `en`
4. Else empty string

`uiTr` additional fallback: original Arabic literal when lookup/key missing.

**Test policy:** validator must fail on missing/empty/Arabic-in-EN even if UI fallback would render something.

## PERSISTENCE
`SharedPreferences`:

- `__locale_key__` — selected language code
- `__locale_user_picked__` — boolean; true after manual change via `storeLocale`

Language switch must not alter auth/session/role/country scope.

## RTL SOURCE
Locale-driven via Flutter `Directionality` / Material localization delegates from selected `Locale`.

- RTL: `ar`, `ur`
- LTR: `en`, `ru`, `ky`, `fr`, `pt`

Technical identifiers (email, UID, order/settlement IDs, URLs, phone) remain LTR islands in presentation widgets.

## DO NOT ADD
A second competing localization framework. Extend `FFLocalizations` + `uiTr`/`appTr` only.
