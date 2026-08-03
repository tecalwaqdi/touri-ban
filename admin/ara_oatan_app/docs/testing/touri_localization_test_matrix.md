# Touri Localization Test Matrix

| Screen / Flow | ar | en | ru | ky | RTL/LTR | Notes |
|---------------|----|----|----|----|---------|-------|
| Splash | ☐ | ☐ | ☐ | ☐ | OK | Brand Touri Taxi |
| Login / Register / OTP | ☐ | ☐ | ☐ | ☐ | ar=RTL | FF + EasyLocalization |
| Home | ☐ | ☐ | ☐ | ☐ | ar=RTL | Language picker 4 langs only |
| Trip type / landmarks | ☐ | ☐ | ☐ | ☐ | | Fixed "Looking for a teacher" |
| Map / Places search | ☐ | ☐ | ☐ | ☐ | | API language param; place names from Google |
| Checkout / hours / price | ☐ | ☐ | ☐ | ☐ | | Glossary fees/VAT/total |
| Payment method | ☐ | ☐ | ☐ | ☐ | | Cash / online localized |
| Payment WebView | ☐ | ☐ | ☐ | ☐ | | Gateway may be EN (external) |
| Booking confirmation | ☐ | ☐ | ☐ | ☐ | | |
| Bookings list | ☐ | ☐ | ☐ | ☐ | | Status via localizer keys |
| Booking details | ☐ | ☐ | ☐ | ☐ | | **Fixed** raw `halhText` |
| View route / tracking | ☐ | ☐ | ☐ | ☐ | | ETA `.tr()` |
| Profile / language | ☐ | ☐ | ☐ | ☐ | | preferred_locale sync |
| Wallet | ☐ | ☐ | ☐ | ☐ | | |
| Support | ☐ | ☐ | ☐ | ☐ | | Hardcoded leftovers possible |
| Notifications | ☐ | ☐ | ☐ | ☐ | | Locale clamped to prod |
| Empty / error / offline | ☐ | ☐ | ☐ | ☐ | | ErrorLocalizer |
| Dark mode | ☐ | ☐ | ☐ | ☐ | | |
| Kyrgyz glyphs ңөүҢӨҮ | — | — | — | ☑ | LTR | Widget test + sample key |

Automated checks:

```bash
dart run tool/check_localizations.dart
dart run tool/check_kyrgyz_characters.dart
dart run tool/check_mixed_languages.dart
dart run tool/check_translation_consistency.dart
dart run tool/localization_coverage_report.dart
dart run tool/check_hardcoded_strings.dart
flutter test test/localization
```
