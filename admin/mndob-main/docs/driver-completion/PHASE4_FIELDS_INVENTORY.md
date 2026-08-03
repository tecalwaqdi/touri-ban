# PHASE 4 — Registration fields inventory

**Date:** 2026-07-28  
**Source of truth:** `regdrever` + `user/{uid}` + `DriverRegistrationDraft`  
**No new collections / no Deploy**

Legend status: **Fixed** · **Added** · **Kept** · **Deferred** · **TBD**

| Section | Step | Field | Widget file | Controller / State | Firestore | Draft | Type | Req | Validation now | Validation required | Formatter / KB | Langs | Country rules | Error key | Save | Restore | Admin display | Issue | Fix | Unit | Widget | Manual |
|---------|------|-------|-------------|-------------------|-----------|-------|------|-----|----------------|---------------------|----------------|-------|---------------|-----------|------|---------|----------------|-------|-----|------|--------|--------|
| Personal | 0 | fullName | `regdrever_widget.dart` `_AccountStep` | `nameController` | `display_name` | `name` | String | Y | `DriverNameValidator` | Unicode AR/EN/RU/KY | text | 4 | none | Full name is required / unsupported | draft+submit | draft load | `display_name` | ASCII risk | Fixed | Y | N | TBD |
| Personal | 0 | identityNumber | same | `idNumberController` | `ID_hoyh_MNDOB` | `idNumber` | String | Y | `DriverIdentityValidator` | per identityType | text | 4 | soft SA | ID invalid | draft+submit | draft | ID field | SA-only risk | Fixed | P | N | TBD |
| Personal | 0 | birthDate | DatePicker | `_birthDate` | `birth_date` Timestamp | `birthDateIso` | Date | Y | `DriverBirthDateValidator` 18–80 | same | picker | 4 | minAge central | Birth date invalid | draft+submit | draft | additive | missing | Added | Y | N | TBD |
| Personal | 0 | email | same | `emailController` | `email` | `email` | String | Y | AuthValidation lowercase | same | email | 4 | none | Invalid email | draft+submit | draft | `email` | ok | Fixed | Y | N | TBD |
| Personal | 0 | phone | same | `mobileController` | `phone_number`/`phone_n` | `mobile` | String | Y | PhoneService E.164 | SA/KG/RU/UZ | phone | 4 | per ISO | Phone invalid for country | draft+submit | draft | phone | SA length | Fixed | Y | N | TBD |
| Auth | 0 | password | same | password controllers | Auth only | — | String | Y new | min 6 + confirm | same | text obscure | 4 | — | Password | Auth create | — | — | — | Kept | Y | N | TBD |
| Location | 1 | gps | `DriverRegLocationMap` | `_regLocation` | `loceshnMndobNow` | lat/lng | Geo | Y | maps config | same | map | 4 | bounds | Location required | draft+submit | draft | location | — | Kept | N | N | TBD |
| Location | 1 | country | GPS+CountryService | `FFAppState.dolh` | `Rev_dolh` Ref | `countryIso` | Ref | Y | active countries | ISO id not name | — | 4 | SA/KG/RU/UZ | Country required | applyCountry | draft ISO | country ref | Mecca default risk | Kept (no Mecca) | P | N | TBD |
| Location | 1 | regionId | `DriverRegLocationCascade` | `FFAppState.mdenh` | `region_ref` (additive) + via village.cities | `regionPath` | Ref | Y* | catalog active | Country→Region | dropdown | 4 | clear on country change | Please select a region | draft+submit | draft path | region display | was missing | Fixed | Y | N | TBD |
| Location | 1 | cityId (village) | cascade | `FFAppState.villmndoBREV` | `mndob_vill` | `villagePath` | Ref | Y* | catalog active | Region→City | dropdown | 4 | clear on region/country | Please select a city | draft+submit | draft | `mndob_vill` | was null on submit | Fixed | Y | N | TBD |
| Location | 1 | city display note | text optional | `cityController` | `city_display` | `cityName` | String | N | optional | display only | text | 4 | — | — | draft+submit | draft | additive | — | Kept | N | N | TBD |
| Vehicle | 2 | vehicleName | `_VehicleStep` | `vehicleNameController` | `NameCar` | `vehicleName` | String | Y | required | trim | text | 4 | — | required | draft+submit | draft | NameCar | — | Kept | N | N | TBD |
| Vehicle | 2 | year | same | `modelController` | `ModelCar` | `model` | String/int | Y | YearValidator | 2010…now | number | 4 | optional type policy later | Invalid year | draft+submit | draft | ModelCar | allowlist | Fixed | Y | N | TBD |
| Vehicle | 2 | plate | same | `plateController` | `number_lohh_car` + `normalized_plate` | `plate` | String | Y | PlateNormalizer | per country later | text | 4 | no SA-only | Plate invalid | draft+submit | draft | plate | — | Fixed | Y | N | TBD |
| Vehicle | 2 | color | same | `colorController` | `vehicle_color` | `color` | String | Y | required | code later | text | 4 | — | Color required | draft+submit | draft | additive | — | Added | N | N | TBD |
| Vehicle | 2 | seats | same | `seatsController` | `seat_count` | `seats` | int | Y | 1–8 | type-aware later | number | 4 | — | Seats invalid | draft+submit | draft | additive | String compat | Added | Y | N | TBD |
| Vehicle | 2 | type | ListTypeCar | `MNDOBTYPECARrev` | `mndob_type_car` | — | Ref | Y | country catalog | active+country | picker | 4 | filtered | Type required | submit | app state | type | — | Kept | N | N | TBD |
| Vehicle | 2 | brandId/modelId | — | text NameCar | — | — | text | — | — | catalogs | — | — | — | — | — | — | — | text only | Deferred | N | N | TBD |
| Docs | 2 | profilePhoto | upload | URL/pending | `photo_url` | `photoUrl` | URL | Y | size+HTTPS | MIME+progress | picker | 4 | req | File too large / upload failed | flush+submit | draft URL | photo_url | local path | Fixed | Y | N | TBD |
| Docs | 2 | idImage | upload | URL/pending | `img_id_rksh` | `idImageUrl` | URL | Y | same | same | picker | 4 | req | same | flush+submit | draft | img_id_rksh | — | Fixed | Y | N | TBD |
| Docs | 2 | carImage | upload | `_carImageUrl` | `img_id_car` | `carImageUrl` | URL | N | same | optional | picker | 4 | optional | same | flush+submit | draft | img_id_car | — | Added | Y | N | TBD |
| Docs | 2 | license/insurance/expiry | — | — | — | — | — | — | requirements repo lists future | Admin config | — | — | — | — | — | — | — | not in UI | Deferred | N | N | TBD |
| Review | 3 | summary | `_ReviewStep` | read-only | — | — | — | — | CompletenessValidator | show real values | — | 4 | — | Incomplete | — | controllers | — | `--` birth bug | Fixed | N | N | TBD |

## Storage path (unchanged)

`users/{uid}/uploads/{timestamp}.ext` via existing `uploadData` + `DriverDocumentUploadService`.

## Controllers policy

- Created in `initState`, disposed in `dispose`.  
- **Not** created inside `build`.  
- City/color/seats/name/etc. restored from draft.
