# Google Play Release Checklist — Touri Taxi

## Pre-flight (both apps)

- [ ] Deploy Firebase Functions including `requestAccountDeletion` and `createAccountDeletionRequest`
- [ ] Deploy website `/ar/delete-account` and `/en/delete-account` to the **live** domain
- [ ] Confirm public URL opens without login and clearly shows **Touri Taxi** + developer entity
- [ ] Upload new AABs with **new versionCodes** (Customer 51+, Driver 40+)
- [ ] Application IDs unchanged: `com.mycompany.araoatanapp` / `com.mycompany.mndob2`

---

## CUSTOMER APP (`com.mycompany.araoatanapp`)

### App content → Data safety

Declare **data collected = Yes** for categories below. Use **Shared = No** unless Console forces ESP classification (see audit reasoning).

| Data type | Collected | Shared | Required | Purposes |
|--|--|--|--|--|
| Email address | Yes | **No** | Required | Account management; App functionality; Fraud prevention / security / compliance |
| Name | Yes | No | Optional | Account management; App functionality |
| Phone number | Yes | No | Optional/required per flow | App functionality; Account management |
| User IDs | Yes | No | Required | Account management; App functionality; Fraud prevention |
| Address | Yes | No | Optional | App functionality |
| Approximate location | Yes | No | Required for booking | App functionality |
| Precise location | Yes | See audit (trip counterpart) | Required for booking/tracking | App functionality |
| Photos | Yes | No | Optional | Account management |
| Other in-app messages | Yes | No | Optional | App functionality |
| Purchase history | Yes | No | Optional | App functionality |
| Payment info | Yes (via processor; no full PAN in Firestore) | No | Optional | App functionality |
| Other financial info | Yes if wallet used | No | Optional | App functionality |
| App interactions | Yes | No | — | App functionality |
| User-generated content | Yes | No | Optional | App functionality |
| Device or other IDs (FCM) | Yes | No | — | App functionality |
| Advertising ID | **No** | — | — | — |
| Crash logs | **No** (no Crashlytics) | — | — | — |
| Performance diagnostics | **No** (package unused) | — | — | — |

Encryption in transit: **Yes** (HTTPS/TLS to Firebase).  
Users can request deletion: **Yes** (personal account data).  

**Disclosure required in store / privacy / delete URL:** Account deletion removes unnecessary personal account data. Trip, transaction, settlement, invoice, payout, and accounting/audit records may be retained for accounting, regulatory/legal compliance, fraud prevention, disputes, and audit. Do **not** claim “all data is deleted.” Do **not** invent a retention duration without legal approval.

### Account deletion (Play form)

- In-app deletion: **Yes** (Profile → Delete account)
- Account deletion URL:  
  - **If live:** `https://touri-taxi.com/ar/delete-account` (and ensure EN available at `/en/delete-account`)  
  - **If not deployed yet:** **NOT READY FOR PLAY SUBMISSION** — do not paste a Contact Us / Support-only URL

### Target API

- Confirm AAB `targetSdkVersion = 36` (verified in release merged manifest for this build).

---

## DRIVER APP (`com.mycompany.mndob2`)

### App content → Data safety

| Data type | Collected | Shared | Required | Purposes |
|--|--|--|--|--|
| Email address | Yes | **No** | Required | Account management; App functionality; Fraud prevention / security / compliance |
| Name | Yes | No | Required | Account management |
| Phone number | Yes | No | Required (registration field) | Account management; App functionality |
| User IDs | Yes | No | Required | Account management; App functionality |
| Photos | Yes | No | Required for onboarding | Account management; Fraud prevention |
| Files and docs | Yes | No | Required | Account management; Fraud prevention / compliance |
| Approximate location | Yes | No | Required | App functionality |
| Precise location | Yes | Trip counterpart / ops | Required | App functionality |
| Background location | Yes (during active trip tracking) | Same | Required for driver ops | App functionality |
| Other in-app messages | Yes | No | Optional | App functionality |
| Purchase history / other financial | Yes | No | — | App functionality |
| Payment info | Yes via N-Genius top-up | No | Optional | App functionality |
| Device IDs (FCM) | Yes | No | — | App functionality |
| Advertising ID | **No** | — | — | — |
| Crash / Performance | **No** unless enabled later | — | — | — |

### Account deletion

- In-app: Profile07 → Delete account (callable + gates)
- Same web URL as Customer once live
- Until live: **NOT READY FOR PLAY SUBMISSION**

### Permissions justification (Console questionnaires)

Be ready to explain: `ACCESS_BACKGROUND_LOCATION` + `FOREGROUND_SERVICE_LOCATION` only for **active trip** tracking to share location with the customer.

---

## Upload steps

1. Play Console → Customer app → Production (or testing track) → Create release → upload Customer AAB  
2. Same for Driver app with Driver AAB  
3. Update Data safety forms per tables above  
4. Paste deletion URL only after production website check  
5. Submit for review
