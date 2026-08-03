# Touri Taxi Release Readiness Audit

Date: 2026-07-18

## Executive status

**Verdict: NOT READY**

The highest-risk source defects were corrected: Touri no longer handles PAN/CVV,
paid and cash bookings are finalized by trusted Functions, financial writes are
restricted, map routes use a server-side Directions key, localization is
centralized, and the three applications share canonical Firestore and Storage
rules. Production release is still blocked because the supplied N-Genius keys
do not authenticate, the new Functions/rules have not been deployed and
verified, and no real hosted-payment acceptance test has passed.

## Production sources

| Surface | Source | Version | Android id | Firebase project |
| --- | --- | --- | --- | --- |
| Customer | `ara_oatan_app` | `9.1.9+17` | `com.mycompany.araoatanapp` | `tutorial-multi-language-70gx4j` |
| Admin | `Admi` | `1.0.2+2004` | `com.mycompany.tutorialmultilanguageapp` | `tutorial-multi-language-70gx4j` |
| Driver | `mndob-main` | `2.0.1+8` | `com.mycompany.mndob2` | `tutorial-multi-language-70gx4j` |

An older driver copy exists at `D:\Projects\ara\mndob-main` (`2.0.0+6`). It is
not the accepted release source.

## Findings and status

| Severity | Finding | Status |
| --- | --- | --- |
| BLOCKER | Supplied N-Genius Service Account API keys are rejected | Open; no charge attempted |
| BLOCKER | Functions/rules/storage not deployed and verified | Open |
| CRITICAL | Client/direct Function handled PAN/CVV | Fixed; hosted payment only |
| CRITICAL | Client finalized paid bookings | Fixed; server transaction and idempotency |
| CRITICAL | Client could forge cash booking totals | Fixed; callable server creation |
| CRITICAL | Broad Firestore financial/order writes | Fixed in canonical local rules; deployment pending |
| CRITICAL | Weak/inconsistent Storage rules | Fixed in all three local rule files; deployment pending |
| CRITICAL | Firebase Admin private key present under Functions | Removed; key revocation still required in Console |
| HIGH | Route API key exposed to Directions requests | Fixed; route calls proxy through callable Function |
| HIGH | WhatsApp/geocoding/WASL secrets in clients | Fixed; moved behind callable Functions/secrets |
| HIGH | Mixed languages and hardcoded UI text | Fixed by static checker and 749 keys in 11 locales; native-language QA remains |
| HIGH | Notifications always used Arabic | Fixed; recipient `preferred_locale` and localized payload text |
| HIGH | Dark booking-list contrast | Fixed using theme-aware surfaces, status colors, and contrast tests |
| MEDIUM | Release toolchain versions nearing deprecation | Open; plan Gradle/AGP/Kotlin upgrade separately |

## Verified results

- Customer `flutter analyze`: no issues.
- Customer `flutter test`: 17/17 passed, including localized notification templates.
- Driver route/cloud integration analysis: no issues.
- Functions ESLint: passed with zero warnings.
- N-Genius unit tests: passed.
- Localization: 11 files, 749 keys each, no missing/extra/empty/broken
  values or placeholder mismatches.
- Hardcoded static `Text` checker: passed.
- Firestore rule SHA-256 values match across all three applications.
- Storage rule SHA-256 values match across all three applications.

The final post-change Android App Bundle build did not finish within 15 minutes
and did not update the artifact. The older valid AAB must not be represented as
the artifact for this change.

## Release gates still open

1. Revoke the exposed Firebase Admin service-account key.
2. Obtain a new active N-Genius production Service Account API key for outlet
   `63c9f06b-19ad-4963-a8d8-50538be90f54`.
3. Configure all Function secrets and environment values.
4. Deploy Functions, Firestore rules, Storage rules, indexes, and hosting.
5. Verify App Check enforcement and Google API-key restrictions in Console.
6. Pass hosted payment, 3DS, decline, cancel, webhook, retry, idempotency,
   refund, and cash acceptance tests.
7. Pass Firebase rules emulator tests and real-device Android/iOS testing.
8. Generate and verify fresh Android and iOS release artifacts.
