# DRIVER_FINAL_QA

Checklist — mark only with evidence (device log / test name / screenshot path).

**Session closeout 2026-07-28:** Unit/Release builds updated; Device rows remain unchecked → **not Production Ready**.

## Identity
- [x] Driver path = `mndob-main`
- [x] Package Android = `com.mycompany.mndob2`
- [x] Bundle iOS = `com.mycompany.mndob3`
- [x] Firebase = `tutorial-multi-language-70gx4j`
- [x] Flutter = 3.44.4
- [x] Release APK/AAB built locally (unsigned store key)
- [ ] Device QA runbook A–L evidence
- [ ] Firebase Deploy completed

## Bootstrap
- [ ] Cold start → Login (no session)
- [ ] Cold start → Home if approved session
- [ ] Cold start → Home shell if pending (not Regdrever)
- [ ] Anonymous guest never sticks
- [ ] Splash does not hang forever
- [ ] No auto-open registration

## Auth
- [ ] Login valid credentials
- [ ] Login wrong password message correct
- [ ] Login network error ≠ wrong password
- [ ] Forgot password
- [ ] Register CTA from Login only
- [ ] Register submit once
- [ ] After register → Home (pending banner)
- [ ] No return to last registration step
- [ ] Draft continues only for unfinished signup
- [ ] Auth uid == Firestore user doc id
- [x] Unit: Unicode names AR/EN/RU/KY (`driver_registration_validators_test`)
- [x] Unit: Phone SA/KG/RU/UZ + Persian digits
- [x] Unit: Birth date / year / plate / seats / doc size
- [ ] Device: registration 4 languages / 4 countries / real Storage upload
- [ ] Device: Review Edit return + Cold Start draft restore

## Approval
- [ ] Admin sees pending driver (`ismndob` + `!actev_mndob` + `ismndom`)
- [ ] Approve flips `actev_mndob` + `registration_status`
- [ ] App updates without reinstall
- [ ] Reject reason visible when set
- [ ] Admin eventually displays additive P4 fields (birth_date, vehicle_color, …)

## Online / orders
- [ ] Go Online blocked if not approved
- [ ] Go Online works when approved + GPS
- [ ] Ready to receive orders
- [ ] Accept atomic (no double assign)
- [ ] Arrive / Start / Complete / Cancel
- [ ] Trip restore after kill

## i18n / design / release
- [ ] ar/en/ru/ky no critical hardcoded on auth+home
- [x] flutter analyze Phase4 paths: 0 errors (infos remain)
- [x] flutter test Phase2–4 suites: **76 passed** (2026-07-28 closeout)
- [ ] APK path recorded (this phase)
- [ ] AAB path recorded (this phase)

## Last known artifacts
- APK (prior): `mndob-main/build/app/outputs/flutter-apk/app-release.apk`
- AAB (prior): `mndob-main/build/app/outputs/bundle/release/app-release.aab`

## Phase device TBD (do not mark Passed without run)
- Phase 2 Cold Start / Login / AuthGate
- Phase 3 Save&Exit / Continue / Changes Requested
- Phase 4 Clear App Data, Country→Region→City cascade, multilingual names, real uploads, Review
- Phase 4: change country clears region/city; Cold Start restores region/village paths
