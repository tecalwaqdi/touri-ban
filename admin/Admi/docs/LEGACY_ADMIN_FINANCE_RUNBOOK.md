# Legacy Admin Finance Runbook

**Audience:** Operators using Legacy Admin as emergency fallback when Admin Next is unavailable.  
**Panel:** Legacy Touri Taxi Admin (`admin/Admi`).

## How to read money fields

| Term (AR) | Meaning |
|-----------|---------|
| إجمالي الرحلات / إجمالي الرحلة | Gross trip value from persisted order majors |
| عمولة توري | Platform commission from persisted `total_app` |
| الضريبة | VAT from persisted `total_vat` |
| صافي السائق | Driver net from persisted `total_mndob` (or marked مشتق if derived) |
| المبلغ المحصل نقدًا | Cash collected from customers |
| مستحقات الشركة | Company receivable / cash due from drivers |
| المبلغ المسدد | Confirmed settlement payments |
| المتبقي | Outstanding = expected − confirmed payments (± approved corrections) |
| التسوية | Settlement document lifecycle (not the same as trip payment status) |
| التصحيح | Approved adjustment / correction record |
| المطابقة | Reconciliation / DQ finding (flag only) |

**Missing ≠ zero.** If a field shows `—` or “غير متاح”, it is unknown. Do not treat it as `0`.

## Current commercial rules

1. **Cash only** for current operations. Do not look for Apple Pay / Moyasar / N-Genius actions in this panel.
2. **15% Touri commission** is the *current* pricing rule for new trips. Historical trips keep their stored commission.
3. **One country = one active agent** (server-enforced). If activation fails with a conflict, another active agent already holds that country.

## Daily operator path

1. Open **المركز المالي (Finance Hub)** — KPIs come from server aggregate V2.
2. Open **التقارير المحاسبية** for the same period — numbers must match Hub.
3. Open **جودة البيانات المالية** to review CRITICAL / WARNING / INFO findings. Do **not** edit historical amounts to clear flags.
4. Open **المصالحة المالية** for structured mismatches (flag only).
5. Export CSV from Reports when needed — it copies the same on-screen canonical values.

## Settlements

1. Prepare / refresh draft via existing settlement screens (CF-backed).
2. Lock only when trip lines look complete.
3. Confirm payments separately from settlement status.
4. Outstanding must show Expected / Paid / Outstanding together.
5. Never delete a settlement to “fix” a number — void via the supported CF path if authorized.

## Corrections

1. Use **التعديلات المالية (Adjustments)** — draft → approve (checker) → reverse if needed.
2. Original trip majors remain visible.
3. Every mutation should leave an audit trail (actor, reason, before/after).

## What NOT to do

- Manually edit historical order money fields in Firestore.
- Manually change driver wallets to force Hub/detail agreement.
- Delete settlements or payments.
- Treat missing as zero in exports or verbal reports.
- Combine different currencies into one total.
- Auto-correct Production data from DQ findings.
- Send test push notifications to real users.
- Bypass one-active-agent conflicts from the client.

## When screens disagree

1. Confirm same filters: date range, country, agent, driver, currency.
2. Prefer Finance Hub / Reports canonical snapshot over Operations Hub legacy cards.
3. Check Data Quality for incomplete majors on the specific trip.
4. If still wrong, escalate with trip ID + settlement ID — do not patch Production majors.

## Deploy / fallback note

Legacy Admin is the operational fallback. Prefer Admin Next when available. Deploy Legacy only after finance tests/build pass and no financial regression is observed on smoke samples.
