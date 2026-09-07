# Phase 1 — Global Shell Changed Files

**Branch:** `recovery/admin-phase1-global-shell`  
**Base:** `6eff3e061dd58269a9cdef6fbd46c6848342a6d6`

## New

| File | Why |
|------|-----|
| `admin/Admi/lib/core/admin_shell_rules.dart` | Pure shell rules (menu hide, padding XOR, content max width) |
| `admin/Admi/test/core/admin_shell_rules_test.dart` | Focused unit tests |
| `docs/admin_ui_recovery/phase1/*` | Phase 1 audit/contract/QA docs |
| `docs/admin_ui_recovery/*.md` | Phase 0 docs preserved on branch |

## Modified (shell)

| File | Change |
|------|--------|
| `lib/flutter_flow/nav/nav.dart` | `_AuthLoadingScreen` → `AdminSplashScreen` |
| `lib/components/menu2_widget.dart` | Use `AdminShellRules.shouldHideNavItems` |
| `lib/components/admin_layout_widget.dart` | Compact `contentMaxWidth` via shell rules |
| `lib/components/admin_ui.dart` | Slightly tighter `pagePadding` tokens |

## Modified (shell wiring only — `padContent: false`)

No page content/business logic changed. Only disables layout padding where the page already pads:

- `admin_finance_hub_widget.dart`
- `admin_finance_channels_widget.dart`
- `admin_finance_receivables_widget.dart`
- `admin_agent_finance_widget.dart`
- `admin_finance_reports_widget.dart`
- `admin_finance_audit_widget.dart`
- `admin_financial_periods_widget.dart`
- `admin_reconciliation_widget.dart`
- `admin_diagnostics_widget.dart`
- `admin_settlements_widget.dart`
- `admin_settlement_details_widget.dart`
- `admin_settlement_receipt_widget.dart`

## Not modified

- `admin_firestore_list.dart`
- Driver list/profile bodies
- Customer app / Driver app
- Cloud Functions / Firestore
- Hotfix `227602a`

## Proposed Admin version (not bumped in this commit)

Keep `1.0.16+2018` until promotion policy.  
**Proposed next when accepting Phase 1:** `1.0.17+2019` (shell-only release).
