# RBAC Matrix (Finance)

| Capability | Super Admin | Finance / Accountant (`isAdminRule=5`) | Country Agent / Agent | Support |
|---|---|---|---|---|
| Global finance dashboard | Y | Y | N | N |
| Agent own finance | Y | Y | Y (own) | N |
| Settlements admin (UI) | Y | Y | N | N |
| Settlement writes (server) | Flag-gated | Flag-gated | N | N |
| Finance audit global | Y | Y | N | N |
| Financial periods | Y | Y | N | N |
| Diagnostics | Y | N | N | N |
| Wallet LEGACY adjust | Y (flag-gated) | N | N | N |
| Provision accountant | Y | N | N | N |
| Settlement approve (checker) | Y / policy | policy | N | N |

Server CF enforces writes. UI hide is insufficient.

Provisioning: SuperAdmin → `AdminAddAccountant` or `firebase/scripts/provision_handover_accountant.js` sets `isAdminRule: 5` → Auth claim `finance` only.

Future granular permissions (planned keys):  
`finance.dashboard.view`, `finance.settlement.approve`, `finance.adjustment.create`, …
