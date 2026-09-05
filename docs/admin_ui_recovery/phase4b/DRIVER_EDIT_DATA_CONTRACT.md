# Phase 4B — Driver Edit Data Contract

## Editable fields (Admin `addDrev` edit)

| UI | Meaning | Firestore | Type | Required | Validation | Role | Source | Write |
|----|---------|-----------|------|----------|------------|------|--------|-------|
| الاسم | Display name | `display_name` | string | yes | min 3 | edit roles | `displayName` | update |
| الجوال | Phone | `phone_number` | string | yes | ≥9 digits | edit roles | `phoneNumber` | update |
| البريد | Email | `email` | string | — | **READ_ONLY** edit | — | Auth/profile | not written |
| صورة | Photo | `photo_url` | string | no | upload | edit roles | `photoUrl` | update |
| مدينة العمل | Work village | `mndob_vill` + `mndob_vill_text` | ref+string | yes | picker | edit roles | village picker | update |
| دولة مشتقة | Country | `Rev_dolh` | ref | derived | from village | sync | `AdminCountrySync.countryFromVillage` | update |
| نوع المركبة | Type | `mndob_type_car` + label in `text_type_car_mndob` | ref+string | yes | type picker | edit roles | `RefTepeCar` | update |
| اللوحة | Plate | `number_lohh_car` + `normalized_plate` + label suffix | string | no | normalize | edit roles | plate field / parse | update |
| شركة النقل | Company | `transport_company` (+ text) | ref | optional | company list | edit roles | picker | update / delete |

## READ_ONLY (must not expose in edit)

- UID / Auth internals / custom claims
- Wallet / financial totals / trip totals
- `registration_status`, `actev_mndob` (activation owns these)
- Audit history fields
- Document binary slots (documents workflow)

## Cascade

- Work city picker (`AdminRegionPicker` / workcite) → country via `AdminCountrySync`
- Changing city clears incompatible refs via picker contract (existing)

## Vehicle canonical write

- Type ref: `mndob_type_car`
- Display label: `text_type_car_mndob` (`{type} - {plate}` when plate set)
- Plate SoT: `number_lohh_car` (display) + `normalized_plate` (AdminDriverPlate.normalize)

## Save path

```
FORM validate
→ busy (isSubmitting)
→ canEditDriver (edit)
→ createUserRecordData + plate fields
→ Firestore update
→ AdminListRefresh(representatives)
→ snackbar → pop
```

## Double submit

- `isSubmitting` set **before** async permission / write
