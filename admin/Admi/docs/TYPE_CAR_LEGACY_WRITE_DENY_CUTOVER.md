# Legacy Admi type_car writer cutover (PREPARE ONLY — DO NOT ACTIVATE)

## Current write path (ACTIVE)

Flutter Legacy Admi (`admin/Admi`) writes `type_car` **directly via client SDK**:

- `lib/components/admin_vehicle_type_editor.dart` → `reference.update(...)`
- `lib/car_type_addition/car_type_addition_widget.dart` → create
- Firestore rules currently allow:

```
match /type_car/{document} {
  allow read: if true;
  allow create: if isSuperAdmin() || typeCarScopedWriteCreate();
  allow update: if isSuperAdmin() || typeCarScopedWriteUpdate();
  allow delete: if isSuperAdmin() || typeCarScopedWriteDelete();
}
```

Admin Next Production writes remain gated by `VEHICLE_CATALOG_WRITE_ENABLED=false`
(must stay false until cutover day).

## Preferred final architecture

| Actor | type_car READ | type_car WRITE |
|-------|---------------|----------------|
| Flutter/mobile/admin client SDK | allowed | **denied** after cutover |
| Admin Next (Admin SDK / service identity) | n/a (server) | only writer |
| Cloud Functions (Admin SDK) | n/a | allowed (rules bypass) |

## Exact rules change (ACTIVATE LATER)

In `admin/Admi/firebase/firestore.rules` (and synced `mndob-main` copy), replace the
three `allow create/update/delete` lines under `match /type_car/{document}` with:

```
allow create, update, delete: if false;
```

Keep:

```
allow read: if true;
```

Commented cutover block is already present in rules (inactive).

## Cutover sequence (when READY)

1. Customer + Driver store builds published (old clients still OK for booking/driver guards).
2. Enable Admin Next `VEHICLE_CATALOG_WRITE_ENABLED=true` (+ global production write gates).
3. Deploy Admin Next as sole writer; verify create/update/archive.
4. Deploy Firestore rules with `type_car` client write deny.
5. Smoke: Legacy Admi update → permission-denied; Admin Next write → OK.
6. Do **not** mutate historical orders/drivers.

## Safety

- Admin SDK / CF bypass rules → server writers continue.
- Old Legacy Admi builds become non-writers (cannot remain hidden writers).
- READ remains open so Customer/Driver catalog queries keep working.
