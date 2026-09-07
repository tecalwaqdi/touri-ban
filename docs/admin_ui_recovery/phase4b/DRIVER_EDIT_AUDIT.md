# Phase 4B — Driver Edit Forensic Audit

**Base:** `ebf1b9ac77175c1c0ecc11a42799d18843fbddd0`  
**Branch:** `recovery/admin-phase4b-driver-edit-activation`

## EDIT ENTRY POINT

- Driver List row menu → Edit → `/addDrev?editUser=`
- Driver Profile actions → Edit → same route
- Drawer is **read-only** (opens full profile / list actions)

## EDIT ROUTE / DIALOG

- Route: `AddDrevWidget` (`addDrev` / `/addDrev`)
- Mode: `editUserRef != null` → edit

## SOURCE FILE

- `admin/Admi/lib/add_drev/add_drev_widget.dart`
- Model: `add_drev_model.dart`

## SAVE HANDLER

- `_submitRepresentative()` → direct Firestore `editUserRef.update(...)`
- Create path: `AdminUserCreation.createEmailUser` (out of Phase 4B edit scope)

## DATA SOURCE

- Load: `UserRecord.fromSnapshot(editUserRef.get())`
- Guard: `AdminResourceGuard.canEditDriver` on load **and** save

## CLOUD FUNCTION

- **None** for profile field edit

## DIRECT FIRESTORE WRITE

- **YES**

## ROLE REQUIREMENT

- Super Admin: any driver
- Country Agent: village in agent country (`canEditDriver`)
- Transport Company: own company drivers only

## LEGACY EDIT IMPLEMENTATIONS

- Canonical: `addDrev` edit mode
- Registration review (approve/reject/changes): `DriverActivationWidget` — **not** field edit
- No second competing edit form found

## DUPLICATE EDIT FIELDS

- **0** after audit (name / phone / email / city / car / plate / photo / company once each)
- Email **read-only** in edit mode (Auth identity)

## DOCUMENTS

- Owned by documents panel / registration review — **not** duplicated in edit form
