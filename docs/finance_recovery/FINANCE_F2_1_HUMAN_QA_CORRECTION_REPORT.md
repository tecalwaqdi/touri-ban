# TOURi TAXI — FINANCE F2.1 HUMAN QA CORRECTION REPORT

BASE:
235d51d4a97ec5fbaff8caf9c81c19df6bf906a5

COMMIT:
(see git after commit)

PREVIEW:
https://tutorial-multi-language-70gx4j--admin-finance-f2-1-im0eagw0.web.app/admin/#/adminFinanceHub

PRODUCTION DEPLOYED:
NO

================================
CONSISTENCY ROOT CAUSE
================================

HUB ZERO VS REPORT 150 ROOT CAUSE:
1. Hub KPIs used `AccountantFinanceReadModel` → excluded QA fixtures from totals.
2. Hub money table did **not** exclude fixtures → fixtures still listed (`fin_rt_*`, `fin7_ctrl_*`, `fin9_ctrl_*`).
3. Reports used legacy `FinancialAccountingLoader` / CF `server_v2` → **included** fixtures → ~150 SAR (typical 3×50 fixture shape).
4. Extra Hub risk: Super Admin loader could inherit `AdminCountryScope.activeCountryRef` and silently scope away from «كل الدول».

HUB REAL TRIPS:
Canonical F1 COMPLETE + non-fixture only (via `AccountantFinanceLoader`).

REPORT REAL TRIPS (F2.1):
Same loader / same filter / same aggregate as Hub.

QA FIXTURE CONTRIBUTION BEFORE:
Included in Reports + money table (visible IDs + inflated gross).

QA FIXTURE CONTRIBUTION AFTER:
0 (normal Hub / table / on-screen report).

================================
SUMMARY
================================

PRIMARY CARDS:
الرحلات المكتملة · القيمة المالية الموثقة · المحصل · غير المحصل

SECONDARY:
عمولة الشركة · الضريبة · صافي السائقين · المستحق للشركة/السائق

DATA QUALITY WARNING:
PASS — compact «رحلات ببيانات مالية ناقصة: N»

MISSING AS ZERO:
0 — uses `—` via `AccountantFinanceTextMoney.zeroOrDash` when unreliable

================================
MONEY TABLE
================================

QA ROWS:
0 (filtered with `isFinanceQaFixture` / `AdminQaFixture`)

RAW IDS AS PRIMARY LABEL:
0 — trip/driver/country use human labels; tech IDs under «بيانات تقنية»

================================
REPORTS
================================

HUB VS REPORT:
MATCH — on-screen report summary uses `AccountantFinanceLoader`

Rev_dolh VISIBLE:
0

server_v2 VISIBLE:
0

================================
SETTLEMENTS
================================

COMPACT UI:
PASS — summary chips + DataTable

DUE/PAID/REMAINING:
PASS

RAW/LOOSE TECH TEXT:
0 (scattered draft/locked counters replaced)

================================
TRIP DETAILS
================================

COUNTRY HUMAN LABEL:
PASS — السعودية (not countries/saudi_arabia)

DRIVER HUMAN LABEL:
PASS — display name when available

RAW IDS BUSINESS SECTION:
0 — collapsed «بيانات تقنية»

AGENT SHARE PRESENTATION:
PASS — «حصة الوكيل من عمولة الشركة» + disclaimer not extra gross

================================
VISUAL
================================

RTL:
PASS

CAIRO:
PASS (Admin theme / GoogleFonts)

CONTRAST:
PASS — shared `AccountantFinanceText` uses `theme.secondaryText` ink (not `theme.info` white)

GIANT WHITESPACE:
0 — compact chips + advanced filters expansion

TEXT CONTRAST:
PASS

WHITE-ON-WHITE:
0

INVISIBLE HEADINGS:
0

LOW-CONTRAST MONEY VALUES:
0

LIGHT MODE:
PASS

DARK MODE:
PASS (ink follows theme.secondaryText)

SHARED THEME FIX:
YES — `accountant_finance_text.dart`

================================
TESTS
================================

ANALYZE:
PASS (finance-touched paths)

FINANCE TESTS:
PASS — `flutter test test/core/finance/` → 108 passed

FULL TEST:
Finance suite only in this gate; known CSV historical failure may remain outside finance path.

NEW FAILURES:
0

================================
FINAL
================================

ACCOUNTANT UI:
READY_FOR_SECOND_HUMAN_QA

F1 SEMANTICS CHANGED:
NO

FINANCE WRITES CHANGED:
NO

DATABASE MIGRATION:
NO

READY_FOR_F3:
NO

STOP.
