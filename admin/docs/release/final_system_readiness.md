# Final system readiness (honest gate — 2026-07-20)

## Production roots

| App | Path | Version |
|-----|------|---------|
| Customer | `admin/ara_oatan_app` | `9.1.10+18` (prior build) |
| Driver | `admin/mndob-main` | `2.0.2+9` |
| Admin | `admin/Admi` | `1.0.3+2005` |
| Firebase | `tutorial-multi-language-70gx4j` | Functions region `us-central1` |

## Fixed this session (admin + driver integration)

1. Shared booking/payment status codes across apps.
2. Driver **transactional accept** — prevents double assignment.
3. Driver unified start/complete with `status_code` + cash collection fields.
4. Completed order lists query `status_code == completed`.
5. Admin finance status matching without Mojibake; `FinancialEngine` restored.
6. Disabled auto landmark/order seed on admin super-login.

## Not Store Ready yet

| Gate | Status |
|------|--------|
| Driver APK `2.0.2+9` | Building / verify |
| Admin full multilingual UI | Incomplete (many AR hardcodes) |
| Driver online/`ngl` toggle | Still inconsistent |
| N-Genius Functions live | **Blocked — Cloud Billing** |
| Full 3-app E2E on device | Pending manual |

## Required external step

Enable billing on `tutorial-multi-language-70gx4j`, then deploy payment Cloud Functions (see customer `docs/release/manual_external_requirements.md`).
