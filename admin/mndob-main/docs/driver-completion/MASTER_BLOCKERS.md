# MASTER BLOCKERS

Only real external blockers. Code defects are fixed, not listed here.

| ID | Type | Impact | Required action | Workaround in code |
|----|------|--------|-----------------|-------------------|
| device_qa_not_run | Device | Cannot claim Production Ready | Run DEVICE_QA_RUNBOOK | Keep Device QA = TBD |
| firebase_functions_deploy | Deploy | Server approve/accept/FCM not live | Explicit Deploy later | Local stubs + client writes where allowed |
| firestore_rules_deploy | Deploy | claim `acceptedAt` not live | Deploy rules | Local copies only |
| fcm_device_proof | Device/Console | Push unproven | Device + Console | Code paths retained |
| git_no_baseline_commit | Git | No safe baseline | Intentional first commit | Working tree only |

**Resolved this pass:** android release keystore config found (`keystore.properties` + jks); gitignore hardened for secrets.

**Not blockers:** analyze infos/warnings, FAQ UI polish.
