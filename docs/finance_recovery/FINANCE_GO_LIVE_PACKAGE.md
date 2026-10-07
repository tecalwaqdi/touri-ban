# Finance Control Center — GO-LIVE PACKAGE (blockers closed)

**FINAL_STATUS candidate:** see agent return block  
**LIVE_CONFIG:** `PENDING`  
**SHADOW_VALIDATION:** `NOT_RUN` (credentials unavailable)  
**No deploy / no flag writes / no production mutations in this wave.**

## CASH CUTOVER (CRITICAL — CORRECTED)

**Verified CF behavior:** `confirmCashCollectionV2` calls `assertFlag(..., 'FINANCIAL_CASH_REALIZATION_V2_ENABLED')`.  
When the flag is **false** (default), the call **rejects** with `failed-precondition` / `FEATURE_FLAG_DISABLED` (unit-tested).  
Exception: `LEGACY_ADMIN_WRITE_MODE=super_admin_emergency_only` can bypass domain flags for Super Admin only — not a Driver migration path.

**Correct migration (both old + new clients work):**
1. Read LIVE `financial_config/runtime`
2. Deploy Finance Functions
3. Keep TEMPORARY_COMPAT cash rules ACTIVE
4. Enable `FINANCIAL_CASH_REALIZATION_V2_ENABLED=true` **while** compat rule remains
5. Controlled CF cash runtime test (success + audit + idempotent duplicate)
6. Release Driver ≥ 11.1.18+47 (CF-only)
7. Verify Driver CF adoption
8. Only then `driverCanCompleteCashCollection()=false` + deploy canonical rules
9. READ-ONLY shadow → `MISMATCHES=0`
10. Enable settlement writes only after shadow=0
11. Controlled QA settlement test
12. Enable payment confirm if settlement test passes
13. Keep `AUTOMATIC_PAYOUT_ENABLED=false` and `WALLET_SETTLEMENT_ENABLED=false`

## RULES

- **RULES_PARITY:** PASS (Admi / mndob / ara_oatan SHA1 identical)
- **CANONICAL_RULES_SOURCE:** `admin/Admi/firebase/firestore.rules`  
  (copy to mndob + ara_oatan mirrors before commit; one Firebase project `tutorial-multi-language-70gx4j`)

## SHADOW (READ-ONLY)

```bash
cd admin/Admi/firebase/functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json   # or ADC
node scripts/finance_shadow_readonly.js --orderId=<ORDER_ID> --currency=SAR
```

Require `MISMATCHES=0` before settlement write / payment confirm flags.

## CORRECTED_DEPLOYMENT_ORDER

1. Read LIVE `financial_config/runtime` (human gate)
2. Deploy Functions (cash + settlement callables)
3. Keep TEMPORARY_COMPAT cash Firestore rule ACTIVE
4. Enable `FINANCIAL_CASH_REALIZATION_V2_ENABLED=true` (compat rule still on)
5. Controlled `confirmCashCollectionV2` runtime: success + audit + idempotent opId
6. Release Driver ≥ 11.1.18+47 (CF-only) + deploy Admin web (settlement writes still off)
7. Verify Driver CF cash adoption/runtime
8. Flip `driverCanCompleteCashCollection()=false`; deploy canonical rules once
9. READ-ONLY shadow → require `MISMATCHES=0`
10. Enable `FINANCIAL_SETTLEMENT_WRITES_ENABLED` only if shadow=0
11. Controlled QA settlement test
12. Enable `FINANCIAL_PAYMENT_CONFIRM_ENABLED` only if settlement test passes
13. Keep `AUTOMATIC_PAYOUT_ENABLED=false` and `WALLET_SETTLEMENT_ENABLED=false`

## ROLLBACK

Disable write flags → prior Functions → restore TEMPORARY_COMPAT rules if cash outage → prior Admin/Driver builds

## FILES (this blocker wave)

- Rules TEMPORARY_COMPAT restored + synced (3 mirrors)
- `finance_arap_loader.dart` + receivables rebuild
- AdminReportsHub / AdminAgentReport → FIN V2 redirects
- Menu reports → AdminFinanceReports
- PDF Cairo fail-closed + Arabic test
- `finance_shadow_readonly.js`
