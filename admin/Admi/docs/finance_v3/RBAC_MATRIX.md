# RBAC Matrix (Finance)

| Capability | Super Admin | Finance | Country Agent / Agent | Support |
|---|---|---|---|---|
| Global finance dashboard | Y | Y | N | N |
| Agent own finance | Y | Y | Y (own) | N |
| Settlements admin | Y | Y | N | N |
| Finance audit global | Y | Y | N | N |
| Financial periods | Y | Y | N | N |
| Diagnostics | Y | N | N | N |
| Wallet LEGACY adjust | Y | N | N | N |
| Settlement approve (checker) | Y / policy | policy | N | N |

Server CF enforces writes. UI hide is insufficient.

Future granular permissions (planned keys):  
`finance.dashboard.view`, `finance.settlement.approve`, `finance.adjustment.create`, …
