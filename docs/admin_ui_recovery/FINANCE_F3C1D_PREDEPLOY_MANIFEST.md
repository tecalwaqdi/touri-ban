# F3-C1D Pre-Deploy Manifest
# Project: tutorial-multi-language-70gx4j
# No secrets

recorded_at_utc: 2026-09-05T22:48:00Z
branch: recovery/admin-finance-f3c1-write-path
approved_review_commit: fad73797aec44645c587cb6eea8e7536a2c9f4a0
implementation_commit: 565b1cd
deploy_head: 4c646f8e2a63a03ff2729741bafe5cd70bd5509e
deploy_head_note: docs-only descendant of approved review (F3-C1R report)
functions_workspace: admin/ara_oatan_app/firebase/functions
codebase: functions
firebase_project: tutorial-multi-language-70gx4j

targets:
  - export_name: createCashBooking
    entry_point: createCashBooking
    region: us-central1
    generation: 1st (gcfv1 / firebase Version v1)
    trigger: callable
    runtime: nodejs22
    status: ACTIVE
    version_id: "5"
    update_time: "2026-08-27T12:30:33.392Z"
    firebase_functions_hash: ac043d1187e7918da50125875858281eb882bd37
  - export_name: finalizeNGeniusBooking
    entry_point: finalizeNGeniusBooking
    region: us-central1
    generation: 1st (gcfv1 / firebase Version v1)
    trigger: callable
    runtime: nodejs22
    status: ACTIVE
    version_id: "1"
    update_time: "2026-08-21T00:45:08.370655628Z"
    firebase_functions_hash: 5199f5eef4b95bd0139b402fc593f8583ee18462

approved_deploy_count: 2
