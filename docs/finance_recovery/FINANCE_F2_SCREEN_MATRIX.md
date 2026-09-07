# Finance F2 — Screen Matrix

| Route | Classification | F2 action |
|---|---|---|
| `/adminFinanceHub` | **CANONICAL** | Accountant summary + money movement + alerts + details |
| `/adminFinanceAgents` | **CANONICAL** (agent scope) | Same read model; country-scoped for agents |
| `/adminSettlements` | CANONICAL (settlements list) | Softened Arabic; no ledger/wallet marketing copy |
| `/adminSettlementDetails` | CANONICAL (settlement write UI) | Arabic action labels (اعتماد / تسجيل دفعة) |
| `/adminSettlementReceipt` | CANONICAL | Unchanged receipt |
| `/adminProfits` | **REDIRECT_TO_CANONICAL** | Soft redirect → Finance Hub |
| `/adminFinanceChannels` | TECHNICAL_DIAGNOSTIC | Banner + link to Hub; removed from primary menu |
| `/adminFinanceReceivables` | LEGACY_DEFERRED | Route kept; not in primary menu |
| `/adminReconciliation` | LEGACY_DEFERRED | Route kept; not in primary menu |
| `/adminFinancialPeriods` | TECHNICAL_DIAGNOSTIC | Route kept; not in primary menu |
| `/adminFinanceReports` | LEGACY_DEFERRED (exporter) | Still V2 report families; Hub is source of truth for KPIs |
| `/adminFinanceAudit` | TECHNICAL_DIAGNOSTIC | Super Admin secondary link only |
| `/adminDriverWallets` | TECHNICAL_DIAGNOSTIC | Removed from primary finance menu |

## CSV / PDF exporters

Existing `csv_export.dart` / report exporters may still use legacy V2 aggregates.

**F2:** documented as deferred — do not silently rewrite exporters without tests.

Classify: `LEGACY_DEFERRED_EXPORTER`
