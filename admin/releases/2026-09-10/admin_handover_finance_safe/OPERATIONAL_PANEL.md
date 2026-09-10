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

1. ~~Deploy Functions (`adminConfirmCashCollectionV2`, claims, `createPanelUser`).~~ **DONE 2026-09-10**
2. ~~Deploy Admin hosting~~ **DONE 2026-09-10** — Firebase Hosting `/admin/` + Render root both on git `d829939` (`1.0.17+2021`).
3. **Provision accountant** (`isAdminRule=5`) via SuperAdmin UI **إضافة محاسب** or `provision_handover_accountant.js`, then sign out/in (or `refreshMyClaims`) so token has `finance: true`.
4. Do **not** flip flags until a controlled pilot trip is approved.

## Live status (2026-09-10)

- Backend claims for accountant: **live**
- Admin cash confirm callable: **live** (still flag-gated OFF)
- Admin panel UI: **live on Render** → https://touri-ban-1.onrender.com/ (`1.0.17+2021`, git `d829939`)
- Admin panel UI: **live on Firebase Hosting** → https://tutorial-multi-language-70gx4j.web.app/admin/ (`1.0.17+2021`, git `d829939`)
- Finance write flags: remain OFF

## Create accountant now

1. Open https://touri-ban-1.onrender.com/ (or Firebase Hosting `/admin/`) as SuperAdmin.
2. Super Admins → **إضافة محاسب**.
3. Deliver email + temp password out of band.
4. Accountant signs in → lands on Finance Hub; must refresh session once if claims look stale (`refreshMyClaims` / sign-out/in).
5. Auth authorized domains: **`touri-ban-1.onrender.com` added 2026-09-10**.

### Provisioned handover accountant (2026-09-10)

- Email: `accountant.handover@tecalwaqdi.com`
- UID: `NE74q01TQrRGzt2o5JKFa0gwuaC3`
- Claims verified: `{ finance: true }` only; `isAdminRule=5`
- Temporary password: stored locally only at `~/Downloads/touri_accountant_handover_credentials.txt` (not in git)

## Out of scope (unchanged)

- Agent commission payout
- Production flag enablement
- Hosting/Render provenance pin
