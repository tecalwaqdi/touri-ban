# DEVICE QA RUNBOOK (Final)

**Status:** TBD — not executed in this session  
**App:** `mndob-main` (`com.mycompany.mndob2`) version `2.0.2+9`  
**Firebase:** `tutorial-multi-language-70gx4j`  
**Rule:** Never mark Production Ready while any critical row is TBD.

## Evidence columns (fill per run)

Preconditions | Test account | Device | OS | Locale | Country | Network | Steps | Expected | Actual | Screenshot/video | Log ref | Pass/Fail/TBD | Defect ID

---

## A. Install / launch

| ID | Scenario | Result |
|----|----------|--------|
| A1 | Clean Install | TBD |
| A2 | Clear App Data | TBD |
| A3 | Cold Start (no session) → Login | TBD |
| A4 | Upgrade Install from prior APK | TBD |

## B. Registration

| ID | Scenario | Result |
|----|----------|--------|
| B1 | Full register → Pending | TBD |
| B2 | Draft Save & Exit → restore | TBD |
| B3 | Country→Region→City cascade | TBD |
| B4 | Document uploads HTTPS | TBD |
| B5 | Plate up to 20 chars / VIN-style | TBD (code fix shipped) |
| B6 | Profile/ID/Vehicle upload buttons | TBD (UX fix shipped) |

## C. Review / activation (Admin + Driver)

| ID | Scenario | Result |
|----|----------|--------|
| C1 | Admin approve → Home offline | TBD |
| C2 | Request changes → driver notes | TBD |
| C3 | Resubmit same UID | TBD |
| C4 | Reject / Suspend / Reactivate | TBD |

## D. Locales

| ID | Scenario | Result |
|----|----------|--------|
| D1 | العربية | TBD |
| D2 | English | TBD |
| D3 | Russian | TBD |
| D4 | Kyrgyz | TBD |
| D5 | SA vs KG country data | TBD |

## E. Online + location

| ID | Scenario | Result |
|----|----------|--------|
| E1 | Go Online success | TBD |
| E2 | GPS Disabled | TBD |
| E3 | Permission Denied | TBD |
| E4 | Weak network | TBD |

## F. FCM

| ID | Scenario | Result |
|----|----------|--------|
| F1 | Foreground | TBD |
| F2 | Background | TBD |
| F3 | Terminated | TBD |

## G. Offers

| ID | Scenario | Result |
|----|----------|--------|
| G1 | Offer while Online | TBD |
| G2 | No offer while Offline | TBD |
| G3 | Countdown expiry | TBD |
| G4 | Two drivers same order | TBD |

## H. Trip

| ID | Scenario | Result |
|----|----------|--------|
| H1 | Accept → Arrived → Start → Complete | TBD |
| H2 | Cancel | TBD |
| H3 | Complete twice blocked | TBD |
| H4 | Kill app mid-trip → recover | TBD |
| H5 | Reboot phone mid-trip | TBD |
| H6 | Network disconnect mid-trip | TBD |

## I. Payment / wallet

| ID | Scenario | Result |
|----|----------|--------|
| I1 | Cash accept wallet gate | TBD |
| I2 | Cash confirmation once | TBD |
| I3 | Cash confirmation twice | TBD |
| I4 | Wallet currency display | TBD |

## J. Offline / recovery

| ID | Scenario | Result |
|----|----------|--------|
| J1 | Offline goOnline queues / message | TBD |
| J2 | Offline accept blocked | TBD |
| J3 | Reconnect reconcile | TBD |

## K. Suspend

| ID | Scenario | Result |
|----|----------|--------|
| K1 | Suspend while Online → forced offline | TBD |
| K2 | Suspend during trip (policy) | TBD |

## L. Upgrade

| ID | Scenario | Result |
|----|----------|--------|
| L1 | Old → new keeps session | TBD |
| L2 | Old → new recovers active trip | TBD |
