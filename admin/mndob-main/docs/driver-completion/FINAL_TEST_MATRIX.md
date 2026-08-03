# FINAL TEST MATRIX

**Updated:** 2026-07-28  
**productionReady:** false

## Unit (local)

| Area | Automated | Result |
|------|-----------|--------|
| Bootstrap / auth gate | Yes | PASS (prior) |
| Account / registration resolvers | Yes | PASS |
| Draft / submission idempotency | Yes | PASS |
| Approval prerequisites / requested_changes | Yes | PASS |
| Eligibility / online | Yes | PASS |
| Location usable coords | Yes | PASS |
| Trip haversine / assignable / radii | Yes | PASS |
| Offline queue serde | Yes | PASS |
| Recovery next-action mapping | Yes | PASS |
| FCM route alias normalize | Yes | PASS |
| Atomic accept (Firestore txn) | Code present | Device TBD |
| Cash confirmation idempotency | Code policy | Device TBD |
| stopTracking after complete | Code present | Device TBD |

## Widget

| Screen | Widget test | Result |
|--------|-------------|--------|
| Login / Reg / Pending / Home / Offer / Trip / Wallet / History / Profile | Scaffolding limited | TBD (Firebase) |
| RTL / text scale / 320px | Device | TBD |

## Integration (local emulator)

| # | Scenario | Result |
|---|----------|--------|
| 1–10 | Reg → Approve → Online | TBD |
| 11–18 | Offer → Trip complete | TBD |
| 19–24 | Offline / FCM / Suspend | TBD |

Do not mark PASS without evidence.
