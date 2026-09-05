# Phase 4 — Deferred blockers

**Branch checkpoint (Driver recovery saved):** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Branch:** `recovery/admin-phase4d-driver-final-recovery`  
**Recorded for Finance work on:** `recovery/admin-finance-audit`  
**Status date:** 2026-09-05

---

## BLOCKER

**Driver Edit may hang while loading `user/<uid>` via client Firestore read.**

Exact QA driver:

`FQeZMZ85WwcuBRwvfv6Ft3LRXpB3`

Live QA (diagnostic preview) proved load stopped at:

- stage: `DRIVER_GET_START`
- await: `DocumentReference.get(user/FQeZMZ85WwcuBRwvfv6Ft3LRXpB3)`

**STATUS:** `DEFERRED_BY_USER`

Do **not** investigate or fix during Finance recovery work.

Do **not** treat Driver Phase 4 as fully completed.

---

## Working Driver items (keep)

| Item | Status |
|---|---|
| Driver List | Stable |
| Exceptional Super Admin approval (`reviewDriverApplicationV2` override) | Deployed and working |
| Arabic vehicle type presentation | Working |
| Driver license back | Intended optional |
| Driver Edit data load | **Unresolved / deferred** |

---

## Explicit exclusions for Finance branch

- Do **not** include temporary `ADMIN_QA_DIAGNOSTICS` UI/code.
- Do **not** base Finance work on diagnostic-only commits (`ba8bf0d…`, `c62e110…`, later Edit-fix commits).
- Finance branch base SHA must remain: **`29b6d58167b9b49d93ea9a306dcdc330deec3ac5`**.
