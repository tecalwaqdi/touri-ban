# Google Play Data Safety Audit — Touri Taxi

**Date:** 2026-09-12  
**Basis:** Actual code paths in `admin/ara_oatan_app` (Customer) and `admin/mndob-main` (Driver), plus Firebase Functions in `admin/Admi/firebase/functions`.  
**Apps:** Touri Taxi (`com.mycompany.araoatanapp`), Touri Taxi Driver (`com.mycompany.mndob2`)

## Shared vs Collected (Play definitions used here)

Google Play **Data safety** distinguishes:

- **Collected:** data transmitted off the device (to your servers / processors).
- **Shared:** data transferred to a **third party** for purposes other than (or beyond) processing solely on the developer’s behalf as a **service provider / processor**.

**Rule applied in this audit:** Firebase Auth/Firestore/Storage/FCM, Resend (OTP delivery), Maps routing, and N-Genius payment processing are treated as **service providers / processors** executing Touri Taxi functionality. Unless code shows the vendor using the data for its own independent purposes (ads, resale, cross-app profiling), we recommend **Shared = No** for those transfers, while still declaring **Collected = Yes** when the app sends the data off-device.

This is a **recommendation from code evidence**, not legal advice. Re-check against the latest Play Console helper text before submit.

---

## CUSTOMER — Touri Taxi

### Personal info → Email address
| Field | Value |
|--|--|
| Collected | **Yes** |
| Shared | **No** (recommended) |
| Required/Optional | **Required** for email/password signup; provided by Google/Apple when those providers are used |
| Purpose | Account management; App functionality; Fraud prevention / security / compliance (email verification) |
| Processing provider | Firebase Authentication, Cloud Firestore; optional Resend/Brevo only if OTP mode enabled (Customer release uses email-link; OTP CF is dormant) |
| Evidence | `lib/auth/firebase_auth/email_auth.dart`; `lib/backend/backend.dart` `maybeCreateUser` writes `email`; Google Sign-In scopes include `email` |
| Reasoning for Shared=No | Email is stored/processed to operate the account on behalf of Touri Taxi. No code path sells email or sends it to an ad network. Resend (if used) is transactional OTP only. |

### Personal info → Name
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Required/Optional | Optional / prompted for profile completeness |
| Purpose | Account management; App functionality |
| Evidence | `user.display_name`; profile widgets |
| Reasoning | Profile display name kept in Firestore `user/{uid}` for app UX only. |

### Personal info → Phone number
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No (except shown to assigned driver for an active trip — treat as **user-initiated / functional** sharing within the service; still typically declared Collected; Shared often No if same service) |
| Purpose | App functionality; Account management |
| Evidence | `user.phone_number` / `phone_n`; order `phone_numper` |

### Personal info → User IDs
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Purpose | App functionality; Account management; Fraud prevention |
| Evidence | Firebase Auth `uid`; Firestore `user/{uid}` |

### Personal info → Address
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Purpose | App functionality |
| Evidence | `ADRESSUSER`, `list_address`, profile address fields |

### Location → Approximate location
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Required/Optional | Required to book / resolve city coverage |
| Purpose | App functionality |
| Evidence | `lib/core/toury_location_service.dart` (Geolocator) |
| Notes | Derived from GPS / geocode when resolving country/city. No `ACCESS_BACKGROUND_LOCATION` on Customer. |

### Location → Precise location
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | Yes* (to assigned driver during an active booking for trip fulfillment — functional sharing inside the product) |
| Required/Optional | Required for pickup / tracking flows |
| Purpose | App functionality |
| Evidence | Geolocator; order location fields (`LOKESHN`, landmarks); maps |
| Notes | Foreground / while-using. Not background. Ephemeral for live UX; trip endpoints may remain on order history (anonymized on account deletion). |

\*If Play Console asks Shared for location shown to the other party in a ride: declare according to current Play guidance for “sharing with other users.” Prefer the option that matches “shared with other users of the app” if present; otherwise document as Collected with App functionality.

### Financial info → Purchase history
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Purpose | App functionality; Account management |
| Evidence | `Paymenthistory`, `order.total`, payment status fields |

### Financial info → Payment info
| Field | Value |
|--|--|
| Collected | **Limited / Yes for payment processing session** |
| Shared | No (processor: Network International / N-Genius) |
| Purpose | App functionality |
| Evidence | Hosted N-Genius flow; `payment-sdk` Android deps; no full PAN stored in Firestore per privacy text and app design |
| Notes | **Cash is not card payment info.** Cash selection is a payment method flag only. |

### Financial info → Other financial info
| Field | Value |
|--|--|
| Collected | Yes (wallet / balances if customer wallet used) |
| Shared | No |
| Evidence | `wallets`, `transactions` |

### Messages → Other in-app messages
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No (visible to trip counterpart) |
| Purpose | App functionality |
| Evidence | `chat` collection |

### Photos and videos → Photos
| Field | Value |
|--|--|
| Collected | Yes (profile photo) |
| Shared | No |
| Purpose | Account management |
| Evidence | `users/{uid}/profile.jpg`; `photo_url` |

### App activity → App interactions
| Field | Value |
|--|--|
| Collected | Yes (orders, support tickets) |
| Shared | No |
| Purpose | App functionality |

### App activity → User-generated content
| Field | Value |
|--|--|
| Collected | Yes (support text, chat, reviews) |
| Shared | No |
| Evidence | `support`, `chat`, `ReviewsUser` |

### Device or other IDs → Device or other IDs
| Field | Value |
|--|--|
| Collected | Yes (FCM token) |
| Shared | No |
| Purpose | App functionality (push) |
| Evidence | `user/{uid}/fcm_tokens`, `fcm_token` |
| Notes | **Not** Advertising ID. No AdMob / ads SDK found. |

### Diagnostics
| Field | Value |
|--|--|
| Collected | **No Crashlytics.** `firebase_performance` is in pubspec but **not activated** in `main.dart` → treat Performance as **not collected** unless enabled later. |
| Shared | No |

---

## DRIVER — Touri Taxi Driver

### Personal info → Email address
| Field | Value |
|--|--|
| Collected | **Yes** |
| Shared | **No** (recommended) |
| Required/Optional | Required for registration |
| Purpose | Account management; App functionality; Fraud prevention / security (Email OTP) |
| Processing provider | Firebase Auth + Firestore; **Resend** for OTP email delivery (`resend_email_service.js`, `email_verification_otp.js`) |
| Evidence | Driver registration + OTP CF |
| Reasoning for Shared=No | Resend is used as a transactional email **processor** to deliver verification codes on behalf of Touri Taxi. No marketing list / ad SDK usage found in code. |

### Personal info → Name / Phone / User IDs
Same pattern as Customer — Collected Yes, Shared No, Account management + App functionality.

### Photos and videos → Photos
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No (admin review internal) |
| Purpose | Account management; App functionality; Fraud prevention |
| Evidence | Profile photo + document images under `users/{uid}/uploads` |

### Files and docs
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | No |
| Purpose | Account management; Fraud prevention / security / compliance (driver onboarding) |
| Evidence | Identity / license / vehicle registration document slots (`doc_*`, `img_id*`) |
| Play category | Prefer **Photos and videos** and/or **Files and docs** as offered in Console for ID/license uploads |

### Location → Precise location
| Field | Value |
|--|--|
| Collected | Yes |
| Shared | Yes* (to customer during active trip) |
| Required/Optional | Required for accepting / executing trips |
| Purpose | App functionality |
| Evidence | `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION`; `start_tracking_and_update_firebase.dart` writes live location while trip tracking is active |
| When | Starts with active trip tracking; stops when tracking stopped / trip ends |
| Retention | Live track for operational need during trip; historical trip points may remain on order docs (anonymized on account deletion for personal fields) |

### Financial info
| Type | Collected | Shared | Notes |
|--|--|--|--|
| Purchase history | Yes | No | Trip earnings history |
| Other financial info | Yes | No | Wallet `currentBalance`, settlements (`financial_settlements`), transactions |
| Payment info | Yes (top-up via N-Genius) | No | Processor; bank fields in `bank` if used |

### Messages → Other in-app messages
Collected Yes — `chat`.

### Device IDs
FCM tokens — Collected Yes, Shared No. Not Advertising ID.

### Diagnostics
Same as Customer — no Crashlytics; Performance package unused in main.

---

## SDK / provider table

| SDK / Provider | Data | Role | Collected | Shared (rec.) | Encrypted in transit | Deletion request | Category |
|--|--|--|--|--|--|--|--|
| Firebase Auth | email, phone, uid, providers | Processor (identity) | Yes | No | Yes (TLS) | Yes via account deletion | Personal info / User IDs |
| Cloud Firestore | profile, orders, chat, wallet refs | Processor (DB) | Yes | No | Yes | PII deleted/anonymized | Multiple |
| Firebase Storage | photos, driver docs | Processor | Yes | No | Yes | Profile files deleted; KYC docs retained pending legal gap | Photos / Files |
| FCM | device tokens | Processor (push) | Yes | No | Yes | Tokens deleted | Device IDs |
| Resend | email (OTP) | Processor (email) | Yes | No | Yes | N/A after account gone | Email |
| Google Maps / Places | location queries | Processor (maps) | Yes | No | Yes | N/A ephemeral | Location |
| Google Sign-In | email, name, photo | Auth provider (user-initiated) | Yes | No* | Yes | Account deletion | Personal info |
| Apple Sign-In | relay email / name | Auth provider | Yes | No* | Yes | Account deletion | Personal info |
| N-Genius / NI SDK | payment session | Payment processor | Yes | No | Yes | Via processor + local history anonymize | Payment info |
| Firebase Performance | — | Not activated | No | No | — | — | — |
| Crashlytics | — | Not present | No | No | — | — | — |
| Ads / AdMob | — | Not present | No | No | — | — | — |

\*OAuth providers receive credentials as part of sign-in; this is not “sharing for advertising.”

---

## Email — final Play Console selection

### Customer
- Email address: **Collected = Yes**, **Shared = No**, **Required**, Purposes: **Account management**, **App functionality**, **Fraud prevention / security / compliance**

### Driver
- Email address: **Collected = Yes**, **Shared = No**, **Required**, Purposes: **Account management**, **App functionality**, **Fraud prevention / security / compliance**

If Play Console later classifies email ESP as “shared,” switch Shared→Yes **only for the Resend transfer** and keep purpose limited to security/account — but current code supports **Shared = No** under the service-provider reading.
