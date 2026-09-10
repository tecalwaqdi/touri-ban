# Handover — Admin panel / wallets / accountant / agents (SAFE)

**Date:** 2026-09-10  
**Scope:** Operational readiness with **all money-write feature flags OFF**  
**Agent commission:** View / review only (no agent payout path)

---

## Status summary

| Area | Status |
|---|---|
| Accountant role (`isAdminRule=5` → `finance`) | Ready to provision |
| Accountant create UI | `AdminAddAccountant` (SuperAdmin only) |
| Operational finance panel (Hub home, settlements create, adjustments, admin cash exception) | Ready — see [OPERATIONAL_PANEL.md](./OPERATIONAL_PANEL.md) |
| Agent login + own finance view | Ready (existing) |
| Demo/trial agent exclusion from FIN-9 | Code + seed flags + backfill script |
| Driver wallets admin view | Read for SuperAdmin + Finance; adjust frozen |
| Finance Hub / Agent Finance | Operational UI; freeze banners |
| Cash realization / settlements / wallet adjust writes | **OFF** (intentional) |

### Feature flags (defaults — must stay OFF for this handover)

- `FINANCIAL_CASH_REALIZATION_V2_ENABLED` = false  
- `FINANCIAL_SETTLEMENT_WRITES_ENABLED` = false  
- `FINANCIAL_PAYMENT_CONFIRM_ENABLED` = false  
- `WALLET_SETTLEMENT_ENABLED` = false  
- `AUTOMATIC_PAYOUT_ENABLED` = false  

---

## How to create the accountant (handover)

### Option A — Admin UI
1. Sign in as SuperAdmin.  
2. Open **Super Admins** → **إضافة محاسب**.  
3. Create user → home route becomes `AdminFinanceHub`.  
4. Deliver email + temporary password **out of band** (not in git).

### Option B — Script
```bash
cd admin/Admi/firebase/functions
GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
ACCOUNTANT_EMAIL='accountant@example.com' \
ACCOUNTANT_PASSWORD='…' \
ACCOUNTANT_NAME='محاسب التسليم' \
  node ../scripts/provision_handover_accountant.js
```

Claims expected: `{ finance: true }` only.

---

## Agents

1. Use existing **Add Agent** flow for real country agents (one active agent per country, `Agent_total` set).  
2. Flag demo/trial agents so they do not receive commission attribution:
```bash
cd admin/Admi/firebase/functions
GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
  node ../scripts/flag_demo_agents_exclude_attribution.js --dry-run
# then without --dry-run
```
3. New trial seeds set `exclude_from_agent_attribution` / `is_demo_agent` / `demo_agent`.

**Accountant messaging:** outstanding = full provable commission; paid = 0; no agent settlement yet.

---

## Driver wallets

- SuperAdmin-only LEGACY tool.  
- Balance ≠ trip earnings ≠ settlement.  
- Adjust calls fail while `WALLET_SETTLEMENT_ENABLED` is false — UI states this explicitly.

---

## Deploy notes before production use

1. Deploy Cloud Functions so `auth_claims_derive` / `isAdminRule=5` is live.  
2. Deploy Admin hosting build that includes `AdminAddAccountant` + banners.  
3. Pin Hosting / Render / git to the **same** commit (known prior drift).  
4. Do **not** flip finance write flags in this handover.

---

## Verification run (2026-09-10)

- `node --test test/auth_claims_derive.test.js test/agent_order_snapshot.test.js` → PASS  
- `flutter test test/admin_role_isadmin_rule_precedence_test.dart test/admin_agent_finance_route_rbac_test.dart test/core/admin_rbac_authoritative_test.dart` → PASS  
- Flag defaults in `finance_feature_flags.js` → all write flags false  

---

## Explicitly deferred

- Enabling cash realization / settlement writes  
- Agent payout / settlement statements  
- Hosting ↔ Render provenance unification (required before any money enable)  
- Rotating hardcoded smoke-script API keys (separate security follow-up)
