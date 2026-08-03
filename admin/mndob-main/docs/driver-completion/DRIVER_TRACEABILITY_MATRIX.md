# DRIVER_TRACEABILITY_MATRIX

Legend: **F**=Fixed · **U**=Unit tested · **W**=Widget tested · **I**=Integration · **M**=Manual device · **P**=Partial · **N**=Not done · **L**=Legacy ignore

Updated: 2026-07-28 (Phase 4 closeout — Country/Region/City cascade + validators)

| Screen | Route | File | Component | Expected | Current | Data | Backend | Loading | Error | Nav | F | U | W | I | M | Result |
|--------|-------|------|-----------|----------|---------|------|---------|---------|-------|-----|---|---|---|---|---|--------|
| `/` AuthGate | `/` | `driver_auth_gate.dart` | Bootstrap embed | Lifecycle destination | Bootstrap + Retry | Auth+user | read user | pulse | Retry | embed | F | U | N | N | N | Phase2 code; device TBD |
| Onboarding | (embedded) | `driver_onboarding_widget.dart` | Skip/Next/Back | Once; no Auth | Prefs flag | prefs | — | — | — | re-bootstrap | F | N | N | N | N | Device TBD |
| Login1 | `/login1` | `login1_widget.dart` | Sign In | go `/` | Validation+errors | Auth | signIn | button | dialog | `/` | F | U | N | N | N | Device TBD |
| Login1 | | | Forgot password | Generic success | Implemented | Auth | reset email | | | | F | N | N | N | N | Device TBD |
| Login1 | | | Register now | Open regdrever | pushNamed | — | — | | | regdrever | F | N | N | N | N | Device TBD |
| regdrever | `/regdrever` | `regdrever_widget.dart` | 4 steps+OTP+Submit | Draft; unicode; CRC; go `/` | Account/Location cascade/Vehicle/Review | prefs+user | Auth+set+upload | submit | dialog | `/` | F | U | N | N | N | P4 code; device TBD |
| regdrever | | | Name/phone/birth/plate | Country-aware validators | Central validators | — | — | | dialog | | F | U | N | N | N | Unit PASS |
| regdrever | | | Country/Region/City | Cascade from cities/villages | `DriverRegLocationCascade` | countries/cities/villages | queryOnce | spin | Retry | | F | U | N | N | N | Device TBD |
| regdrever | | | Docs upload | HTTPS URL only success | pending→flush after UID | Storage | uploadData | flags | dialog | | F | U | N | N | N | Device upload TBD |
| regdrever | | | Review+Edit | Real values; return refreshes | `_ReviewStep` + region | controllers | — | | | steps | F | N | N | N | N | Device TBD |
| regdrever | | | Save and exit | Persist draft; `/` | AppBar action | prefs | — | | | `/` | F | U | N | N | N | Unit draft; UI device TBD |
| regdrever | | | Continue banner | Show if draft | Banner on restore | prefs | — | | | | F | U | N | N | N | |
| Draft service | — | `driver_registration_draft.dart` | load/save/migrate | No cross-user | guest+uid + region/village paths | SharedPreferences | — | | | | F | U | N | N | N | Unit PASS |
| Location catalog | — | `driver_location_catalog_service.dart` | regions/cities | Existing collections | queryOnce | cities/villages | — | | | | F | N | N | N | N | |
| Validators | — | `driver_registration_validators.dart` | Name/phone/location/… | Unicode + ISO + CRC | Central | — | — | | | | F | U | N | N | N | Unit PASS |
| Pending | `/driverPendingApproval` | `driver_pending_approval_widget.dart` | Pending | Live; refresh; logout | Stream+refresh | user | get | pulse | Retry | stay | F | U | N | N | N | Device TBD |
| Pending | | | Changes requested | Notes+Edit | Distinct UI+Edit | user | — | | | regdrever | F | U | N | N | N | Device TBD |
| Pending | | | Rejected | Reason+resubmit | Distinct+Edit | user | — | | | regdrever | F | U | N | N | N | Device TBD |
| Pending | | | Suspended | Support | Distinct; no edit | user | — | | | | F | U | N | N | N | |
| Pending | | | Approved leave | go `/` | go `/` | lifecycle | — | | | `/` | F | U | N | N | N | |
| Resolver | — | `driver_account_state_resolver.dart` | Legacy→lifecycle | One outcome | Priority rules | user fields | — | | | | F | U | N | N | N | Unit PASS |
| Compat | — | `driver_legacy_field_compat.dart` | Admin patches | Dual-write helpers | Documented | — | — | | | | F | U | N | N | N | |
| NewDriverRegistration | legacy | Wasl | Deprecated | Not production | Still in nav marked DEPRECATED | | | | | | L | N | N | N | N | Ignore |
| Home Online | `/home` | home + online state | Eligibility | Lifecycle gates | Banner + goOnline | user | update ngl/ops | | | | F | U | N | N | N | Device TBD |
| Offers | nav wrap | `driver_new_order_listener` | Online-only sheet | Gate+countdown | AuthStream + ready | orders | listen | | | trip | F | P | N | N | N | Device TBD |
| Accept/Trip | `/tfaselOrser` | `driver_trip_service` | Atomic accept/SM | Txn+offline gate | Backend recovery | order | txn | | | | F | U | N | N | N | Device TBD |
| Lifecycle | nav wrap | `DriverAppLifecycleCoordinator` | Resume recover | Backend-first | Session+trip+queue | user/order | | | | | F | U | N | N | N | Device TBD |
| Wallet | `/driverWallet` | wallet widget | Balance | Localized currency | Streams | wallet | read | | | | P | N | N | N | N | Top-up TBD |
| Orders/Trip UI | various | FF screens | CTA path | Working | Legacy polish | | | | | | P | N | N | N | N | Device TBD |

## Auth state machine

`loggedOut → incompleteProfile → pendingApproval ⇄ changesRequested → rejected|suspended`  
`→ activeOffline ⇄ activeOnline → onTrip`

## Notes

- **M=N** means honest: not run on Emulator/device in this session.
- Production registration path = **regdrever only**.
- Region = Firestore `cities`; City/area = Firestore `villages` (Admin seed convention).
- Phase 4 additive fields: `birth_date`, `vehicle_color`, `seat_count`, `city_display`, `normalized_plate`, `region_ref`, `region_display`.
- Final workstreams M–R: code+docs; Device QA + Deploy still pending → **not Production Ready**.
