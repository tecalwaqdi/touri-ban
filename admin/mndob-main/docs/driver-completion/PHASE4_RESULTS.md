# PHASE 4 RESULTS — Registration data, vehicle, documents

**Date:** 2026-07-28 (closeout pass 2)  
**App:** `mndob-main`  
**Firebase Project:** `tutorial-multi-language-70gx4j`  
**Deploy:** **None**

## Goal

Fix personal / country-region-city / vehicle / images / documents validation + draft persistence without breaking AuthGate / Draft / Resubmit, and without orders/trips/redesign/Deploy.

---

## 1. Registration sections

| Step | Section | Widget |
|------|---------|--------|
| 0 | Personal + Auth | `_AccountStep` |
| 1 | Country→Region→City + GPS | `_LocationStep` + `DriverRegLocationCascade` |
| 2 | Vehicle + documents | `_VehicleStep` |
| 3 | Review + Edit | `_ReviewStep` |

## 2. Fields

See `PHASE4_FIELDS_INVENTORY.md`. Schema note: **regions = `cities` collection**, **cities/areas = `villages`** (Admin seed naming).

## 3. Problems found (this pass)

1. Location step had free-text city only — no Region→City cascade.  
2. Submit wrote `mndob_vill: null` — Admin/orders cannot bind work area.  
3. Changing GPS country did not clear region/city AppState.  
4. Completeness did not validate phone E.164 or region/city.  
5. Document requirements repo unused.  
6. Birth date / location label bugs from earlier pass (already fixed).

## 4–6. Validation

Centralized in `driver_registration_validators.dart`:

- `DriverNameValidator` (Unicode AR/EN/RU/KY)  
- `DriverPhoneValidator` + `DriverPhoneNumberService`  
- `DriverEmailValidator`  
- `DriverBirthDateValidator`  
- `DriverIdentityValidator`  
- `DriverLocationValidator`  
- `DriverVehicleValidator`  
- `DriverPlateNormalizer` / Year / Seats / Document  
- `DriverRegistrationCompletenessValidator`  

## 7. Unicode names

Unit-tested: Arabic, English+apostrophe, Russian, Kyrgyz.

## 8. Phone

SA/KG/RU/UZ + Persian digits via `DriverPhoneNumberService`.

## 9. Country / Region / City

- `DriverRegLocationCascade`: active `countries` → `cities` (region) → `villages` (city).  
- Loading / empty / error / Retry states.  
- Country change clears region + city + vehicle type.  
- ISO change from GPS clears dependent fields (no Mecca fallback).  
- Draft stores `regionPath` / `villagePath` + display names.  
- Submit sets `mndob_vill`, `mndob_vill_text`, optional `region_ref` / `region_display` / `city_display`.

## 10–11. Vehicle schema / save

Still on `user/{uid}`; update/merge by UID; never self-approve (`actev_mndob=false`).

## 12. Plate

`DriverPlateNormalizer` + `normalized_plate`.

## 13–18. Documents

- Requirements wired into step-2 gate (`DriverDocumentRequirementsRepository`).  
- Upload: MIME + size + pending→flush after UID; Storage path unchanged `users/{uid}/uploads/...`.  
- Expiry / full versioning UI: still deferred (no Admin config Deploy).

## 19. Rejected docs

Phase 3 resubmit path retained; single-slot replace via re-upload.

## 20. Review

Shows country, region, city, vehicle, docs; Edit returns to steps.

## 21–22. Admin / customer

Admin already reads `mndob_vill`, name, photo, plate, etc. Additive fields remain optional for Admin UI later. No customer journey changes.

## 23–24. Security (no Deploy)

App still cannot set `actev_mndob=true`. Rules/Storage not published.

## 25. Files modified

- `lib/regdrever/regdrever_widget.dart`  
- `lib/core/driver_registration_draft.dart`  
- `lib/core/driver_registration_validators.dart`  
- `assets/langs/{en,ar,ru,ky}.json`  
- docs under `docs/driver-completion/`

## 26. Files new

- `lib/core/driver_location_catalog_service.dart`  
- `lib/components/driver_reg_location_cascade.dart`  
- (prior) validators, upload service, requirements, inventory, results

## 27–28. Tests

```
flutter test test/driver_registration_validators_test.dart \
  test/driver_registration_draft_test.dart \
  test/driver_account_state_resolver_test.dart \
  test/driver_bootstrap_routing_test.dart \
  test/driver_auth_flow_test.dart \
  test/driver_auth_validation_test.dart \
  test/driver_legacy_field_compat_test.dart
```

**Result: 76 passed, 0 failed.**

## 29. flutter analyze

Phase 4 paths: **0 errors** (infos only: deprecated Dropdown `value`, async context, unused imports).

## 30. Manual / device QA

| Item | Result |
|------|--------|
| Phase 2 device | **TBD** |
| Phase 3 device | **TBD** |
| Phase 4 Clear Data / cascade / uploads / 4 langs | **TBD** |
| Unit suites | **PASS (76)** |

## 31. Remaining

- Insurance/license expiry uploads.  
- Full document versioning UI.  
- Widget tests for forms.  
- Backend duplicate phone/plate (safe).  
- Device proof.

## 32. Needs Deploy later

Rules/Functions uniqueness / Admin display of additive fields — **not done**.

## 33. Suggested Phase 5

Do **not** auto-start. After device QA: Admin field display or eligibility/online.

---

## Success

| Gate | Status |
|------|--------|
| Personal + validators | **PASS** |
| Country→Region→City cascade (existing collections) | **PASS (code)** |
| Vehicle + docs upload path | **PASS (code)** |
| AuthGate / Draft preserved | **PASS** |
| No Deploy | **PASS** |
| Device / Production | **NO** until TBD |

**Phase 4 = Conditional complete (code + unit). Not Production-complete.**
