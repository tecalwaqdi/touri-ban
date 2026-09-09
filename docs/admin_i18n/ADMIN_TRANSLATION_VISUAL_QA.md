# Admin Translation Visual QA

## Scope
Preview-only. No production deploy.

## Required checks (human)

For each locale `ar en ru ky fr ur pt`:

| Route | Check |
|---|---|
| Login | Native language names in selector; persistence |
| Dashboard | Title/subtitle localized; RTL/LTR |
| Drivers / Agents / Users / Landmarks / Bookings | Tables, filters, empty states |
| Finance Hub / Reconciliation / Money Movement / Settlements / Agent Finance / Reports / Audit | Finance glossary terms |
| Profile / Settings | Password labels localized |

### Direction
- AR + UR: page RTL; IDs/emails/phones LTR islands
- EN RU KY FR PT: LTR

### Widths
1440 / 1280 / 1024 / 768 — watch sidebar, chips, table headers (ru/ky/fr/pt).

### Roles
- Accountant: finance read-only workspace in all locales
- Agent: country-scoped UI in representative locales

## Preview channel
Suggested: `admin-i18n-az`

## Status
PENDING_HUMAN_QA — automated string gates pass; screenshots to be captured on preview.
