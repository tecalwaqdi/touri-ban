# ACTIVE_PROJECT_MATRIX

Generated: 2026-08-27 — repository truth audit (read + verified paths).

Firebase project (all ACTIVE apps): `tutorial-multi-language-70gx4j`

| Path | Role | Status | Version | Deploy / runtime |
|---|---|---|---|---|
| `admin/ara_oatan_app` | Customer app | **ACTIVE** | `9.1.25+38` | App Store / TestFlight published contract |
| `admin/mndob-main` | Driver app | **ACTIVE** | `11.1.7+26` | App Store / TestFlight published contract |
| `admin/Admi` | Admin web | **ACTIVE** | `1.0.3+2005` | Vercel (`admin/Admi/vercel.json`) + optional Firebase Hosting |
| `admin/ara_oatan_app/firebase/functions` | Cloud Functions (primary) | **ACTIVE** | codebase `functions` | Firebase `us-central1` |
| `admin/ara_oatan_app/firebase/custom_cloud_functions` | Cloud Functions | **ACTIVE** | codebase `custom_cloud_functions` | e.g. `autoCancelOrders` |
| `admin/Admi/firebase/functions` | Functions mirror | **DUPLICATE** | codebase `admin_functions` | Keep in sync; do not treat as second production product |
| `admin/mndob-main/firebase` | Rules/indexes mirror | **DUPLICATE** | — | Sync with customer firebase tree |
| `admin/services/payment-api` | Payment API | **ACTIVE** | `0.2.0` | Render `https://touri-ban.onrender.com` (+ optional Functions adapter) |
| `admin/releases/**` | Release evidence | **ACTIVE** (docs) | — | Not runtime |
| Older Ara Watan naming in strings | Branding debt | **LEGACY** | — | UI copy only; do not rename collections |

## Source-of-truth notes

1. **Published Customer + Driver contracts beat TARGET_STATE** in the merged audit.
2. **N-Genius / electronic payment remains CURRENT** — audit “Cash-only” is `TARGET_ONLY` / `CONFLICTING` and must not disable live payment.
3. Firestore indexes: Admin tree historically richer; 2026-08-27 additive indexes deployed from `admin/Admi/firebase/firestore.indexes.json`.
4. Rules: keep `ara_oatan_app` / `Admi` / `mndob-main` copies synchronized before any rules deploy.
