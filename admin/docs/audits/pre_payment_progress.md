# Progress — pre-payment wave (2026-07-20)

## Done (payment deferred)

### Driver
- `DriverOnlineState` — online = `user.ngl == true` (no Settings.ngl compare)
- Registration: `actevMndob: false` until admin approval
- Home: go-online button sets `ngl=true`; pending approval opens activation flow
- Now screen uses `canReceiveOrders`

### Admin
- Booking badges via `status_code` + `admin_booking_status_label.dart`
- Finance labels via `OrderStatusHelper`

### Indexes
- Added `order` indexes for `status_code + mndob_user + data_order` in `Admi/firebase/firestore.indexes.json`
- Full indexes deploy failed on unrelated obsolete `mkan` index (400). New composites still in file for re-deploy after cleanup.

## Next (still before payment)
- Driver AAB build verification
- Admin APK/web build if time
- Customer regression smoke

## Last
- Cloud Billing + N-Genius Functions deploy
