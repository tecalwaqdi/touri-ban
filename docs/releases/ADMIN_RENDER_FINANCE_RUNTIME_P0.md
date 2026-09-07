# TOURi TAXI — RENDER FINANCE RUNTIME P0

**Date:** 2026-09-07  
**Branch:** `hotfix/admin-render-finance-runtime-p0` @ `0f88856`  
**Base:** `main` @ `ca54c75e40cb2ad7b229d3e75368ba59ac0800fc`  
**PR:** https://github.com/tecalwaqdi/touri-ban/pull/8  
**Preview channel:** `admin-render-finance-p0`

---

## RENDER VERSION

`1.0.17`

## BUILD

`2021`

## RENDER_RELEASE_SHA

`ca54c75e40cb2ad7b229d3e75368ba59ac0800fc` (from live `build_provenance.json`)

## SAME FIREBASE PROJECT

YES — Render + Preview fingerprints match  
`projectId=tutorial-multi-language-70gx4j`,  
`appId=1:638010533068:web:cd138c3c2424cbef844e69`

---

## ROOT CAUSE

`AUTH_CLAIM_TIMING` (+ incomplete settlement Rules vs `isFinance()`)

Live `refreshMyClaims` derived **empty** claims for `isAdminRule=5` Accountant (stale CF without F3-B2 rule-5 → `finance`), then **`setCustomUserClaims(uid, {})` wiped** any finance claim.

Settlements V2.1 soft-refresh called this on init → live `financial_settlements` stream got **`PERMISSION_DENIED`** because `canReadSettlement()` required `claimBool('finance')` only (no profile `isAdminRule=5` fallback).

Money Movement / Channels used CF `aggregateFinancialAccountingV2` which requires `token.finance` → **`PERMISSION_DENIED`** → UI `AdminFinanceCanonicalUnavailablePanel` (Arabic strings human labeled as Finance Hub).

Order-backed routes (Recon / Agent Finance / Reports / Hub F1 rows) still worked via Rules `isFinance()` profile fallback.

**Not:** deploy version, SW cache, Firebase config mismatch, global transport, indexes, finance semantics.

---

## EVIDENCE

1. Render `version.json` = 1.0.17 / build 2021; provenance git = `ca54c75…`.
2. Auth Admin lookup: demo Accountant `customAttributes` empty before fix; profile `isAdminRule=5`.
3. Settlements REST query with empty claims → `PERMISSION_DENIED`; `order` collection list → OK via profile.
4. `refreshMyClaims` returned `{claims:{}}` and cleared Auth claims after manual `{finance:true}` set.
5. After redeploy: clear claims → `refreshMyClaims` → `{finance:true}`; Settlements OK; CF agg OK.
6. After Rules: Settlements OK **even with empty claims** via `isFinance()` profile fallback.
7. CanonicalUnavailable strings only on Channels / Financial V2 panel — not Hub F1 `AdminErrorState`.

---

## BEFORE

| Route | Status |
|-------|--------|
| FINANCE HUB (human / CanonicalUnavailable) | FAIL |
| SETTLEMENTS | FAIL |
| RECON | PASS/PARTIAL |
| AGENT FINANCE | PASS |
| REPORTS | PASS |

---

## FIX

### FILES CHANGED

- `admin/Admi/firebase/functions/panel_claims.js` — harden rule normalization; keep rule-5 → finance
- `admin/Admi/firebase/functions/index.js` — `syncClaimsForUid` refuse empty wipe for panel rules; no wipe on missing profile
- `admin/Admi/firebase/functions/test/panel_claims_accountant_f3b2.test.js`
- `admin/Admi/firebase/firestore.rules` — settlement ledger reads use `isFinance()` (writes still deny)
- `admin/Admi/lib/admin/admin_finance_hub/admin_finance_hub_widget.dart` — soft claim sync before load
- `admin/Admi/lib/admin/admin_finance_channels/admin_finance_channels_widget.dart` — soft claim sync before CF load
- Modules required by existing `index.js` requires (deploy package integrity): `cash_collection_realization.js`, `email_verification_otp.js`, `legacy_africa_geo_compat.js`, `resend_email_service.js`

### RULES CHANGED

YES — `permission-denied` proven on `financial_settlements` when finance claim missing; align with approved Accountant `isFinance()` read model. **Writes remain deny.**

### FUNCTIONS CHANGED

YES — live `refreshMyClaims` wiped Accountant finance claims; redeployed `refreshMyClaims` + `syncUserClaimsOnWrite`.

### FINANCE SEMANTICS

UNCHANGED

### LIVE BACKEND (already deployed 2026-09-07)

- Functions: `refreshMyClaims`, `syncUserClaimsOnWrite`
- Firestore Rules: settlement ledger `isFinance()` reads

---

## PREVIEW

URL: https://tutorial-multi-language-70gx4j--admin-render-finance-p-m02ds6o2.web.app/admin/

| Check | Result |
|-------|--------|
| FINANCE HUB | PASS (API + soft sync; human UI confirm recommended) |
| SETTLEMENTS | PASS (API: claim + profile fallback) |
| CF Money Movement | PASS (API after claim restore) |

---

## PRODUCTION

Human smoke (Accountant) on Render — **2026-09-07**:

| Item | Status |
|------|--------|
| RENDER | DEPLOYED — `1.0.17+2021` (provenance git `73cd2ac…`) |
| FINANCE HUB | PASS |
| MONEY MOVEMENT / CHANNELS | PASS |
| SETTLEMENTS | PASS |
| RECONCILIATION | PASS |
| AGENT FINANCE | PASS |
| REPORTS | PASS |
| AUDIT | PASS |
| PERMISSION_DENIED | 0 |
| RAW FIREBASE ERRORS | 0 |
| LOGIN REDIRECTS | 0 |
| SIGNOUTS | 0 |
| ACCOUNTANT WRITES | 0 |

---

## SECURITY

| Check | Result |
|-------|--------|
| ACCOUNTANT READ | PASS |
| ACCOUNTANT WRITE | DENY |
| SUCCESSFUL WRITES | 0 |

---

## TESTS

- `flutter analyze`: no errors (pre-existing infos/warnings only)
- Auth-nav / RBAC / Accountant read / B1 / P4A / P4C / Agent Finance: PASS
- `finance_f2_1_consistency_test` ink contrast: **pre-existing FAIL** (reproduced without this hotfix’s Dart edits)
- NEW FAILURES from this hotfix: **0**

---

## FINAL

ADMIN_V2_PRODUCTION: **PASS**

ACCOUNTANT_READY_FOR_REAL_USER: **YES**

STOP.
