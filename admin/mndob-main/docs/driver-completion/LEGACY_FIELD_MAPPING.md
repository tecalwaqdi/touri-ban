# LEGACY FIELD MAPPING — Driver ↔ Admin Compatibility

**Phase:** 3  
**Deploy:** none — fields kept as-is in Firestore

## Field meanings (from `mndob-main` + `Admi`)

| Field | Writer | Reader (legacy) | Meaning |
|-------|--------|-----------------|---------|
| `ismndob` | Regdrever submit, Admin approve | Admin queues, reports | User is a driver (or pending driver) |
| `ismndom` | Regdrever submit, Admin | Admin pending lists | New / pending-driver companion flag |
| `actev_mndob` | **Admin only** (approve) | Was used for Home gates | Account activated for operations |
| `ngl` | Driver online toggle | Order match / UI | Operationally online |
| `mndon_newacc` | Trip assign / busy | Order intake | Busy / on trip |
| `registration_status` | Regdrever + Admin | Resolver | Review pipeline string |
| `rejection_reason` | Admin reject / changes | Pending UI | Free-text admin note |

## Priority (driver app — single outcome)

Implemented in `DriverAccountStateResolver`:

1. no auth / anonymous → `loggedOut`
2. missing `user/{uid}` → `incompleteProfile`
3. `suspended` / `blocked` → `suspended`
4. `rejected` → `rejected`
5. `changes_requested` → `changesRequested`
6. incomplete → `incompleteProfile`
7. submitted / awaiting `actev_mndob` → `pendingApproval`
8. approved + trip → `onTrip`
9. approved + `ngl` → `activeOnline`
10. approved → `activeOffline`

## Compatibility layer

`DriverLegacyFieldCompat` (`lib/core/driver_legacy_field_compat.dart`):

- Documents meanings
- `adminApprovePatch` / `adminRejectPatch` / `adminSuspendPatch` dual-write helpers
- UI helpers: `isOperationallyApproved`, `statusMessageKey`, `rawSnapshot`

Admin continues filtering on `ismndob` / `actev_mndob` — **no Production migration**.

Driver production screens must use `DriverLifecycle` / `DriverOnlineState`, not raw booleans for gates.
