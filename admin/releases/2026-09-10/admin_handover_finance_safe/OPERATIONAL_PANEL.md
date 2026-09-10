# Operational finance panel — accountant-ready UI (flags OFF)

**Date:** 2026-09-10  
**Scope:** لوحة تشغيل للمحاسب (١-أ) — واجهة كاملة؛ أعلام الكتابة تبقى OFF

## What shipped

| Capability | Status |
|---|---|
| `accountantHomeV2` on Finance Hub | Done |
| FinanceRuntimeGate sticky + deep-link probe | Done |
| Create settlement draft from AdminSettlements | Done |
| Adjustments + opening balance UI (`AdminFinanceAdjustments`) | Done |
| `adminConfirmCashCollectionV2` + receivables exception UI | Done |
| Hub settlement outstanding prefers server exposure | Done |
| Reports filters + CSV for ledger types | Done |
| Accountant read access to driver wallets | Done |
| Arabic FEATURE_FLAG / SELF_APPROVAL messages | Done |

## Still OFF (intentional)

- `FINANCIAL_SETTLEMENT_WRITES_ENABLED`
- `FINANCIAL_PAYMENT_CONFIRM_ENABLED`
- `FINANCIAL_CASH_REALIZATION_V2_ENABLED`
- `WALLET_SETTLEMENT_ENABLED`

Buttons are present; callables return clear feature-flag errors until enablement is approved.

## Deploy checklist

1. ~~Deploy Functions (`auth_claims_derive`, `adminConfirmCashCollectionV2`, finance controls unchanged).~~ **DONE 2026-09-10**  
   Deployed: `syncUserClaimsOnWrite`, `createPanelUser`, `refreshMyClaims`, `confirmCashCollectionV2`, `adminConfirmCashCollectionV2`, `syncAgentSnapshotOnOrderCreate`.
2. **Deploy Admin hosting** with Hub / Settlements / Adjustments / Receivables updates (Flutter web build still local until hosted).
3. **Provision accountant** (`isAdminRule=5`) via SuperAdmin UI **إضافة محاسب** or `provision_handover_accountant.js`, then sign out/in (or `refreshMyClaims`) so token has `finance: true`.
4. Do **not** flip flags until a controlled pilot trip is approved.

## Live status (2026-09-10)

- Backend claims for accountant: **live**
- Admin cash confirm callable: **live** (still flag-gated OFF)
- Admin panel UI: **live on Firebase Hosting** → https://tutorial-multi-language-70gx4j.web.app/admin/ (`1.0.16+2018`)
- Finance write flags: remain OFF

## Create accountant now

1. Open https://tutorial-multi-language-70gx4j.web.app/admin/ as SuperAdmin.
2. Super Admins → **إضافة محاسب**.
3. Deliver email + temp password out of band.
4. Accountant signs in → lands on Finance Hub; must refresh session once if claims look stale (`refreshMyClaims` / sign-out/in).


## Out of scope (unchanged)

- Agent commission payout
- Production flag enablement
- Hosting/Render provenance pin
