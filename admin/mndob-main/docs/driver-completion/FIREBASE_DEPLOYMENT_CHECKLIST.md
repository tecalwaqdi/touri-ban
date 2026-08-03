# FIREBASE_DEPLOYMENT_CHECKLIST

- [ ] Staging project selected
- [ ] Rules reviewed (`acceptedAt` in claim keys)
- [ ] Functions built / linted
- [ ] Emulator tests (optional)
- [ ] Backup of current live rules/functions
- [ ] Rollback owner named
- [ ] **Deploy command intentionally NOT run in agent session**
- [ ] Post-deploy smoke: login, accept, complete, FCM
- [ ] Update MASTER_PROGRESS `firebaseDeployed=true` only after success
