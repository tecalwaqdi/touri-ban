# FIREBASE_ROLLBACK_PLAN

1. Keep previous `firestore.rules` / `storage.rules` / function zip in release notes before any Deploy.
2. On failure: `firebase deploy --only firestore:rules` with last-known-good file.
3. Functions: redeploy previous git tag artifact.
4. If accept claims fail post-rules: temporarily allow ops via Admin SDK only; revert claim whitelist carefully.
5. Communicate to drivers if online/accept broken.

Never force-push git; never delete production data for rollback.
