# Firebase single source of truth (C-01)

**Date:** 2026-07-21  
**Canonical root:** `ara_oatan_app/firebase/` only.

## Deploy only from

```text
D:\Projects\ara\admin\ara_oatan_app\firebase
```

| Artifact | Canonical path |
|---|---|
| `firebase.json` / `.firebaserc` | `ara_oatan_app/firebase/` |
| Cloud Functions (`functions`, `custom_cloud_functions`) | `ara_oatan_app/firebase/functions` (+ `custom_cloud_functions`) |
| Firestore rules | `ara_oatan_app/firebase/firestore.rules` |
| Storage rules | `ara_oatan_app/firebase/storage.rules` |
| Indexes | merge into `ara_oatan_app/firebase/firestore.indexes.json` before deploy |

## Mirrors (do not deploy)

| Path | Status |
|---|---|
| `Admi/firebase/` | Mirror for local FlutterFlow tooling only. `firestore.rules` synced from canonical on 2026-07-21. |
| `mndob-main/firebase/` | Same. Do **not** run `firebase deploy` here. |

If you must edit rules while working in Admin/Driver trees, copy **back** to `ara_oatan_app/firebase/firestore.rules` before any deploy.

## Merge plan (Functions)

1. Keep N-Genius + maps + booking callables in `ara_oatan_app/firebase/functions`.
2. Port missing Admin callables from `Admi/firebase/functions/index.js` (finance aggregate, admin push helpers) into the canonical codebase under clear named exports.
3. Port any Driver-only helpers (e.g. `getRoadRoute`) if not already present in canonical `functions` / `custom_cloud_functions`.
4. After merge, delete or stub mirror `index.js` exports so accidental deploy cannot overwrite production with Braintree/Stripe-era code.
5. Deploy only after Cloud Billing is enabled (blocks N-Genius Secrets + Functions publish today — C-02).

## Hard rule

No `firebase deploy` from this audit workstream without explicit operator approval.
