# Phase 3 — Driver List Data Contract

## Row fields (canonical table / card)

| UI LABEL | SOURCE FIELD | FALLBACK | FORMATTER | STATUS MAPPING | NULL BEHAVIOR |
|----------|--------------|----------|-----------|----------------|---------------|
| المندوب (name) | `displayName` | `driverid` → `—` | trim | — | `—` |
| secondary (email/uid) | `email` | truncated `reference.id` | — | — | uid snippet |
| الهاتف | `phoneNumber` | `—` | `AdminDriverRow.formatPhoneDisplay` | — | `—` |
| المدينة | `mndobVillText` / `city_display` | `—` | trim | — | `—` |
| المركبة | profile vehicle helpers | plate fields | `AdminDriverProfileView.vehicle` | — | empty labels |
| لوحة | `number_lohh_car` / `normalized_plate` | vehicle.plate | — | — | empty |
| التسجيل | `registration_status` (+ truth map) | unknownLegacy | `AdminDriverStatusLabels.registration` | `AdminDriverReviewBucket` → badge kind | "حالة غير محددة" |
| الحالة التشغيلية | connection + availability truth | unknown | connection/availability labels | online/offline + available/busy | connection-only if offline |
| تفعيل حساب | `actevMndob` via truth | — | toggle actions | activated/deactivated | disable carefully |
| الرحلات | `Bookings_Agent` / `bookings_count` / `total_trips` / `trips_count` | `—` | toString | — | `—` |
| أرباح (adapter; not primary column) | `totalApp` / `total_app` | `—` | fixed0 | — | `—` |
| صورة | `photo_storage_path` else `photoUrl` | initials | avatar | — | initials |

Raw Firestore maps/enums are not shown as raw strings in list cells; labels go through `AdminDriverStatusLabels`.

## Counters (`AdminDriversSummaryStrip`)

| CHIP | SOURCE | QUERY/FILTER | ROLE SCOPE | UI | NOTES |
|------|--------|--------------|------------|-----|-------|
| إجمالي المناديب | `DriverAdminStats.total` | aggregate loader + filter scope | SA / Agent lock | number | Correct when loader succeeds |
| بانتظار المراجعة | `pendingReview` | registration status bucket | same | number | |
| معتمدون | `approved` | registration | same | number | |
| متصلون الآن | page hint `onlineHint` | **current page rows only** | — | hint | Not full-collection SoT |
| متاحون / مشغولون | page hints | current page | — | hint | Same |
| موقوفون | `suspended + deactivated` | aggregates | same | number | Combined chip |

Stats refresh (`_loadStats`) must **not** reset list content (reload contract).

## Search targets (supported)

Client `matchesSearch` / server plan via `AdminOpsSearch`:

- name, phone (digit-normalized), email, uid / doc id, `driverid`
- city, vehicle name/class, plate / normalized plate

Unsupported: arbitrary nested document fields not listed above.

## Filters

| FILTER | SOURCE | VALUES | DEFAULT | QUERY EFFECT | RESET |
|--------|--------|--------|---------|--------------|-------|
| Country / region / city | AdminOpsFilterState | geo refs | all / agent lock | Firestore where | clears cascade |
| Registration / review | AdminOpsFilterState | buckets + unknown | all | Firestore / unknown panel | |
| Activation | AdminOpsFilterState | actev | all | Firestore | |
| Documents / date / vehicle | AdminOpsFilterState | enums/refs | all | Firestore | |
| Connection / availability | AdminDriversExtraFilters | online/offline, available/busy | all | **Client** on loaded page | in signature → reloadKey |
| Search | searchQuery | string | empty | Client and/or server search branch | clear → stable |
| Page size | `_pageSize` | 20/… | 20 | pageSize + reloadKey | |

Filter change → `reloadKey` / `ValueKey` change → controlled hard reset (valid).
