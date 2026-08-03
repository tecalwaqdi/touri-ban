# Touri Taxi Release Acceptance

Date: 2026-07-18

Legend: PASS = automated and completed; BLOCKED = needs credentials/deployment
or device; NOT RUN = environment unavailable.

| Area | Result | Evidence / remaining work |
| --- | --- | --- |
| Customer static analysis | PASS | Full `flutter analyze`, no issues |
| Driver route/cloud analysis | PASS | Four integration files, no issues |
| Customer unit/widget tests | PASS | 17/17, including localized notification payloads |
| Pricing/VAT/commission invariants | PASS | Integer-halalas tests |
| Route validation/metrics | PASS | Invalid and impossible routes rejected |
| N-Genius state/idempotency unit tests | PASS | Node unit suite |
| Functions lint | PASS | ESLint, zero warnings |
| Localization structure | PASS | 11 x 749, strict checker |
| Hardcoded static UI strings | PASS | Checker excludes only brand/format glyphs |
| RTL/LTR selection | PASS | Arabic/Urdu RTL; tested LTR locales |
| Light/dark theme contrast | PASS | WCAG-style 4.5:1 surface test |
| Firestore/Storage rule equality | PASS | Matching hashes in three apps |
| Firebase rules behavior | BLOCKED | Emulator/deployed-rule tests not completed |
| Arabic | PASS (automated) | Structure, placeholders, active strings |
| English | PASS (automated) | Structure, placeholders, active strings |
| French | PASS (automated) | Active fallbacks translated |
| Russian | PASS (automated) | Active fallbacks translated |
| Kyrgyz | PASS (automated) | Active fallbacks translated, glyph test |
| Other six locales | PASS (automated) | Structural/active-string coverage |
| Native linguistic review | NOT RUN | Required before store submission |
| Cash booking end to end | BLOCKED | Requires deployed callable/rules |
| Hosted payment/3DS success | BLOCKED | N-Genius credential rejected |
| Decline/cancel/retry/idempotency | BLOCKED | Requires provider sandbox/production test |
| Webhook/reconciliation/refund | BLOCKED | Requires deployed endpoint/provider setup |
| Maps/live trip on device | NOT RUN | Requires two real devices and live order |
| Android final AAB | NOT RUN | Final build timed out and artifact stayed old |
| iOS archive/signing | NOT RUN | macOS/Xcode environment unavailable |
| Firebase deployment | NOT RUN | Intentionally withheld while blockers remain |

## Manual device matrix

Run customer and driver on separate devices for Arabic, English, French,
Russian, and Kyrgyz in light and dark mode. For each language verify sign-in,
country flag, country map bounds, region/landmark content, custom place, car
selection, return navigation, trip list, booking details, map route, cash,
hosted payment, notification deep link, cancellation, and location denial.

## Current acceptance decision

Automated source acceptance is strong, but release acceptance is **BLOCKED** by
payment credentials, Firebase deployment/rules behavior, real-device E2E, and
fresh release artifacts.
