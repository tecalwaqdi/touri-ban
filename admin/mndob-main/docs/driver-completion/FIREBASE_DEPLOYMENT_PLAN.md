# FIREBASE_DEPLOYMENT_PLAN

**Status:** Prepared locally — **Deploy NOT executed**

## Project

- Firebase project: `tutorial-multi-language-70gx4j`
- Rules source of truth: `ara_oatan_app/firebase/firestore.rules` (+ mirrored `mndob-main/firebase/firestore.rules`)
- Functions: `ara_oatan_app/firebase/functions/`

## Items requiring Deploy for Production effectiveness

| Item | Why | Apps | Local tests | Risk | Suggested command | Rollback |
|------|-----|------|-------------|------|-------------------|----------|
| Firestore rules (`acceptedAt` claim whitelist) | Driver accept txn writes `acceptedAt` | Driver | Static review | Medium — deny claims if old rules live | `firebase deploy --only firestore:rules` | Redeploy previous rules file |
| Storage rules (if changed) | Uploads | Driver/Customer | Review | Medium | `firebase deploy --only storage` | Prior rules |
| `driver_registration_approval` CF | Server approve/changes | Admin/Driver | Stub local | High | `firebase deploy --only functions:…` | Delete/redeploy prior |
| `addFcmToken` / push dispatch | Token ownership | All | Code present | Medium | functions deploy | Prior functions |
| Indexes | Query ActiveOrder | Driver | — | Low | `firebase deploy --only firestore:indexes` | Prior indexes |
| Wallet/ledger CF (if any new) | Top-up | Driver | — | High secrets | functions | Prior |

## Explicit warning

Until Deploy runs, **local** client fixes + Admin SDK writes may work in debug with privileged clients, but **production security rules / CF will not include** local `acceptedAt`, approval stubs, or FCM updates. Atomic accept / approval / wallet server paths are **not live**.

## Pre-deploy checks (manual later)

1. `firebase use tutorial-multi-language-70gx4j`
2. Lint/build functions
3. Emulator rules tests
4. Staging project preferred before prod
5. Announce maintenance window

**Do not run deploy from this session.**
