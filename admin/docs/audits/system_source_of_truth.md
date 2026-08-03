# System source of truth — Touri Taxi

**Date:** 2026-07-20  
**Branch intent:** `fix/admin-driver-full-production-readiness` (repo has no commit history on `main`)

## Production apps

| Role | Path | Package / ID | Firebase |
|------|------|--------------|----------|
| **Customer** | `d:\Projects\ara\admin\ara_oatan_app` | `com.mycompany.araoatanapp` | `tutorial-multi-language-70gx4j` |
| **Driver** | `d:\Projects\ara\admin\mndob-main` | `com.mycompany.mndob2` | same |
| **Admin** | `d:\Projects\ara\admin\Admi` | Flutter admin (`com.mycompany.tutorialmultilanguageapp` / web) | same |
| **Functions** | `ara_oatan_app\firebase\functions` (+ Admi mirrors) | Region `us-central1` | same |

## Abandoned / duplicate trees (DO NOT ship)

| Path | Note |
|------|------|
| `d:\Projects\ara\mndob-main` | Stale driver copy (2.0.0+6) |
| `d:\Projects\ara\arawatan\` | Legacy |
| `ara_oatan_app` list_vi_copy* screens | Legacy FlutterFlow copies |

## Shared truth gaps (critical)

1. Booking status: Arabic free-text `halh_text` + English `halh` + `status_code` + `Halh` enum — fragmented.
2. Payment status: `Cash`/`Paid`/`Pending`/`pending_cash`/`cash_pending` mixed across apps.
3. Driver accept: transactional accept landed in `DriverTripService`; rules now allow open-pool browse + claim (C-04).
4. Driver online: `ngl` compared to Settings inconsistently.
5. Payment Cloud Functions: **not deployed** (billing 403); customer cash uses Rules fallback marked `pricing_authority: client_fallback_pending_cf` (C-03 interim).
6. Admin status matching includes Mojibake corrupt strings in `financial_engine.dart` (partially cleaned).

**Deploy policy:** see `docs/audits/FIREBASE_SINGLE_SOURCE.md` — deploy Firebase only from `ara_oatan_app/firebase`.

## Canonical codes (adopt now)

### Booking `status_code`

```
draft, awaiting_payment, pending_driver, driver_assigned, driver_arriving,
driver_arrived, trip_started, trip_in_progress, completed,
cancelled_by_customer, cancelled_by_driver, cancelled_by_admin, expired,
refunded, disputed
```

Legacy Arabic `halh_text` may remain for UI display via localizers only.

### Payment `payment_status`

```
unpaid, pending_cash, processing, authorized, captured, paid,
failed, cancelled, refunded, partially_refunded, cash_collected
```

## Execution plan

1. Shared status packages / mirrored consts in each app.
2. Driver: transactional accept + unified start/complete via `DriverTripService`.
3. Admin: normalize financial status matching; remove Mojibake; use codes.
4. Customer: already maps aliases (`pending_driver`, `awaiting_driver`); keep aligned.
5. Tests + Release builds for driver & admin; customer regression.

## Immediate files of record

- Customer booking localizer: `ara_oatan_app/lib/core/...`
- Driver: `mndob-main/lib/core/driver_trip_service.dart`, `driver_trip_constants.dart`
- Admin: `Admi/lib/core/finance/financial_engine.dart`, `backend/schema/enums/enums.dart`
