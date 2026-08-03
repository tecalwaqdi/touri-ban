# WORKSTREAM H / I / L RESULTS (partial)

**Date:** 2026-07-28  
**Deploy:** None  
**Device QA:** TBD

## H — Wallet / payment

- Wallet screen localized via `driverTr`; currency from wallet doc or country registry (no hardcoded ر.س)
- Cash accept still gated by `validateWalletForAccept` + settings min
- Top-up / withdraw remain backend/CF (driver read-only wallets in rules) — deferred; secrets not touched

## I — History / profile / support

- Existing Completed / Accepted / Now / Profile / Support screens retained
- Support still WhatsApp / commission bank form — full in-app tickets deferred

## L — Security rules (local only)

- Claim whitelist + `acceptedAt` fix
- Documented: advance-trip permissive except money/reassign; cash complete path separate
- **Not deployed**

## Gate

productionReady = **false** (Device QA + Deploy pending).
