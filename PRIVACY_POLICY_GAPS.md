# Privacy Policy Gaps — Touri Taxi

Compared: app behavior (Customer + Driver) × Data Safety audit × Privacy pages (`admin/touri-website` + `firebase/public/privacy`) × Delete-account page.

**Official product decision (approved):** Financial freeze on account deletion — trip/financial/accounting records are **not** deleted, modified, or anonymized during account deletion. They are read only for safety gates.

## CRITICAL

1. **Account deletion URL not live on production domain yet**  
   Page exists in repo at `/[locale]/delete-account`, but Play submission must use a **public HTTPS URL**. Until deploy + DNS for `touri-taxi.com` (or the live site URL) is confirmed: **NOT READY FOR PLAY SUBMISSION** for the deletion-link field.

2. **`requestAccountDeletion` / `createAccountDeletionRequest` must be deployed** to Firebase project `tutorial-multi-language-70gx4j` before in-app deletion and web form backend work in production.

3. **Legal entity naming inconsistency**  
   Apps/brand: Touri Taxi. Website delete page: Ara Watan Agency / وكالة أرى وطن. Privacy “controller” text still says “منصة توري تاكسي” without crisp legal entity. Needs legal sign-off for Play + privacy controller identity.

4. **Privacy Policy must match financial freeze (approved)**  
   Main privacy pages still imply broader anonymization / timed purge of account-linked trip data. They must be updated by legal to state clearly that:
   - Unnecessary personal account profile data is removed on verified deletion.
   - Trip/order, wallet, transaction, settlement, invoice, payout, and audit/accounting records may be **retained unchanged** (including linked customer/driver identity when needed) for:
     - accounting
     - regulatory/legal compliance
     - fraud prevention
     - disputes
     - audit  
   - **Do not invent a retention period** in copy until legal sets one.  
   Delete-account page (repo) already discloses this; privacy policy HTML/i18n still need counsel update.

## HIGH

5. **Driver KYC document retention undefined**  
   Code **retains** identity/license/vehicle Storage objects on deletion (clears live profile URL fields). Privacy policy does not define a retention period for KYC docs. Do **not** invent a duration until legal decides.

6. **Privacy cites “90 days” / “24 months” / “5–7 years”**  
   These durations appear in website privacy i18n and static privacy HTML. They conflict with (a) immediate profile cleanup and (b) indefinite financial freeze until legal sets durations. Align all three surfaces: app behavior, privacy policy, delete-account page.

7. **Email Shared declaration**  
   Policy should state email is used for account/security and may be processed by infrastructure providers (Firebase, email OTP vendor) as processors — consistent with Data Safety Shared=No recommendation.

8. **Background location (Driver)**  
   Policy mentions live location during trips; ensure it explicitly covers Android background/foreground-service tracking used in `start_tracking_and_update_firebase.dart`.

## MEDIUM

9. **Terms page marked as legal draft** — get counsel approval.

10. **Chat message bodies retained**; only display name may be cleared on chat/support/reviews when safe. Document under disputes/safety retention.

11. **N-Genius / payment processors** should be named (or categorized) in privacy “processors” section if not already clear.

12. **No Crashlytics**; Performance package unused — privacy should not claim crash analytics if not enabled.

## LOW

13. Legacy strings still say “Ara Watan” / “عرا وطن” in some Customer localization keys — branding cleanup.

14. Contact email on site may be empty via env (`NEXT_PUBLIC_CONTACT_EMAIL`); delete page falls back to `info@touri-taxi.com` text.

## Actions for legal/product (human decisions required)

- Approve controller legal name for Play + privacy.
- Update Privacy Policy text to match approved financial freeze (no invented durations).
- Decide KYC document retention period and purge process.
- Confirm production public URL for delete-account before Play Console paste.
