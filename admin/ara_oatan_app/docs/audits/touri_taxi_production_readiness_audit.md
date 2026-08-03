# Touri Taxi Production Readiness Audit

**Date:** 2026-07-19  
**Trigger:** Device screenshots (ky locale) showing mixed languages, overflow, aircraft landmarks, wrong city names.

## Production source of truth

| App | Path | Verdict |
|-----|------|---------|
| Customer | `admin/ara_oatan_app` | **PRODUCTION** — Android `com.mycompany.araoatanapp`, Firebase `tutorial-multi-language-70gx4j` |
| Driver | `admin/mndob-main` | PRODUCTION (separate) |
| Admin | `admin/Admi` | PRODUCTION panel |
| Duplicate driver | `mndob-main/` (repo root) | ARCHIVE / do not build |
| arawatan | redirect only | ARCHIVE |

## Screenshot failures (mandatory)

1. Kyrgyz UI + Arabic country/city (`المملكة العربية السعودية`, `الرياض`, `مكة المكرمة`)
2. Hardcoded English: `My trip list`, `List of added locations.`, `Total Amount:`, `Looking for a teacher`, `Book now`, `Trip scheduling`, `Payment method.`
3. Landmark category chips in Arabic while chrome is Kyrgyz
4. Aircraft landmarks (F-15, Tornado, Boeing) in trip/landmark lists
5. `RIGHT OVERFLOWED BY … PIXELS` on trip list / landmarks header
6. Vertical single-character text (narrow Flex)
7. Infinite image loading / generic error banner
8. Dark/light section mismatch on checkout bottom
9. Possible stale city (Riyadh) vs Mecca GPS context

## Root-cause hypotheses

| Area | Likely cause |
|------|----------------|
| Geo names Arabic | Firestore `name` / `naimmdenh` without locale pick from `names_i18n` / `osf_i18n` |
| Looking for teacher | FF hash `6bdi3tuo` or search hint still English in landmarks screen |
| Hardcoded EN trip titles | Phrase keys / FF getText / missing `.tr()` on checkout66 / list screens |
| Aircraft | Unfiltered Places/import or polluted `mkan` collection |
| Overflow | Row without Flexible/Expanded around long Kyrgyz strings |

## Execution status (2026-07-19 evening)

| Item | Status |
|------|--------|
| Geo i18n + no Arabic chrome leakage | **Fixed in client** |
| Startup + language-change label refresh | **Fixed** |
| Country/city picker writers localized | **Fixed** |
| Landmark chips all `.tr()` | **Fixed** |
| Aircraft client filter | **Fixed** (Firestore soft-delete still manual) |
| Checkout map overflow | **Fixed** |
| Place photo infinite spinner | **Mitigated** (12s timeout) |
| Checkout theme surface tokens | **Partial** |
| `flutter analyze` (changed files) | **Clean** |
| `flutter test localization+regression` | **21 passed** |
| `flutter build apk --release` | **OK** (119.4MB) |
| `flutter build appbundle --release` | **OK** (88.3MB) |
| Functions deploy | **Blocked** (manual) |
| Store readiness | **NOT READY** — INTERNAL QA |

## Out of scope blockers (manual)

- N-Genius secrets / Functions deploy  
- Driver `google-services.json` package mismatch  
- Full seed of 20 verified landmarks per city (needs Places API quota + policy)
- Admin soft-delete of junk `mkan` documents
