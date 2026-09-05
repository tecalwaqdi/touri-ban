# Phase 4B — Runtime QA

## Environment

- Worktree: `/tmp/admin_phase4b_driver_edit_activation`
- Prefer: `http://localhost:<port>/drever` (Auth authorized domain)
- Avoid relying solely on `127.0.0.1` (not in Auth authorized domains)

## Automated

| Check | Result |
|-------|--------|
| `dart format` (touched) | PASS |
| `flutter analyze` (touched) | PASS |
| Focused tests (`admin_drivers_status_truth_test`, documents dedupe) | PASS (29) |

## Human Safari (required for freeze)

Prior Phase 4 local QA hit **LOCAL_QA_ENVIRONMENT_BLOCKER** (stale session / Resolving role).

**Before drawer/edit/activation E2E:**

1. Open `http://localhost:<port>/`
2. Logout if present → clear site data for localhost if needed
3. Login `info@admin.com`
4. Confirm role chip = Super Admin (not Resolving role)
5. `/drever` list loads

Then:

| Scenario | Status |
|----------|--------|
| Edit one harmless field → save → profile/list | **PENDING_HUMAN** |
| Activate eligible inactive driver | **PENDING_HUMAN** |
| Deactivate → reactivate | **PENDING_HUMAN** |
| Suspend | **NOT_TESTED_SAFELY** (destructive; use QA-only driver) |
| Cross-country agent deny | **NOT_TESTED** (needs agent account) |

Do **not** invent PASS for Safari mutations until recorded by operator.
