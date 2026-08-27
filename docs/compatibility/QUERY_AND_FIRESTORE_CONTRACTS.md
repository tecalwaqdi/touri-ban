# Published Firestore + Query Contracts

## Customer My Bookings / active booking

- Collection: `order`
- Query: `where('USER', isEqualTo: userRef).orderBy('data_order', descending: true)`
- Sources: `touri_firestore_cache.dart`, `touri_active_booking.dart`
- Client bucketing: `touriResolveBookingBucket` (status_code / payment / cancel / expired)
- **Do not** require `ActiveOrder == true` for list visibility (historical ActiveOrder=false on many valid rows)

### Cash / Card→Cash visibility fields (compatibility)

| Field | Cash create CF | Card→Cash client patch | Compatibility normalizer |
|---|---|---|---|
| `USER` | required | preserved | preserved |
| `data_order` | set | preserved | preserved |
| `PaymentMethod` | `Cash` | often missing on old client | normalized to Cash |
| `payment_method` / `payth` | `TOURY_PAY_CASH` | set | ensured |
| `payment_status` | `cash_pending` | `cash_pending` | preserved |
| `ElectronicPayment` | `false` | `false` | ensured |
| `status_code` | `pending_driver` (typical) | `pending_driver` | preserved / revive if wrongly expired |
| `ALLNOW` | true while open | true | ensured while open |
| `ActiveOrder` | false (legacy) | false | **do not flip casually** |
| `cash_compat_version` | `1` | additive | `1` |
| `acceptanceDeadline` | refreshed | often stale on patch | refreshed by normalizer |

Production sample (Card→Cash then cancel): `order/82c0a998…` — `USER` present, cash fields normalized, later `status_code=cancelled_by_customer` (appears under cancelled, not active).

## Driver open / assigned / active

- Open jobs: country / vehicle / `ALLNOW` / status pending patterns (see driver home + accept flow)
- Assigned: `mndob_user == driverRef` + active statuses / `ActiveOrder`
- Accept gate: callable `acceptDriverOrder` (+ wallet / eligibility)

## Admin bookings

- `AdminOpsQueryBuilder.applyOrderFilters`
- Country: `where Rev_dolh == country`
- Active lifecycle: `where ALLNOW == true` + `orderBy data_order DESC`
- All lifecycle: `Rev_dolh` + `orderBy data_order DESC` (**index required**)
- Other lifecycles: `status_code` (+ whereIn) + `data_order`

## Admin drivers / dashboard

- Drivers: `ismndob` + optional `actev_mndob` / registration fields + `Rev_dolh`
- Dashboard counts often use collection counts / country refs; list pages apply stricter country scope → CRIT-01 mismatch risk when docs lack `Rev_dolh`

## Admin transport companies

- `AdminCountryScope.applyTransportCompanyQuery` + `orderBy('naim')` → needs `Rev_dolh + naim`

## Admin support

- `applySupportFilters`: `Rev_dolh` + `orderBy('data' DESC)` → needs `Rev_dolh + data`

## Admin villages

- `applyVillageQuery` / list: `dolh` + `orderBy('naim')` → needs `dolh + naim`

## Admin wallet top-ups

- `transactions` `where type in ['top_up','credit'] orderBy createdAt DESC` → needs `type + createdAt`
