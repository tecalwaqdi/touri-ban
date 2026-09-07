# Phase 4 — Driver Profile Data Contract

## Identity / contact

| UI LABEL | MEANING | SOURCE | TYPE | NULL | FALLBACK | FORMATTER | EDITABLE | OWNER |
|----------|---------|--------|------|------|----------|-----------|----------|-------|
| الاسم | Display name | `display_name` / driverid | string | — | driverid / — | trim | via Edit | Header |
| البريد | Email | `email` | string | hide if empty | — | LTR line | Edit | Header |
| الهاتف | Phone | `phone_number` | string | — | — | formatPhoneDisplay | Edit | Header |
| الدولة | Country | `dolh_agent` / countryLabel | string | — | — | — | Edit | Personal |
| المنطقة | Region | `region_display` / city_display | string | omit | — | — | Edit | Personal |
| مدينة التسجيل | Reg city | `mndobVillText` / city_display | string | — | — | — | Edit | Personal |
| مدينة التشغيل | Ops city | `city_display` | string | omit if same | — | — | Edit | Personal |

## Status axes

| AXIS | SOURCE | VALUES | OWNER |
|------|--------|--------|-------|
| Registration | registration_status (+ aliases) | draft/pending/approved/rejected/needs_changes/suspended/unknown | Header badge |
| Account | actev_mndob | active/inactive | Header badge |
| Connection | truth | online/offline/unknown | OperationalStatus |
| Availability | truth | available/busy/unknown | OperationalStatus |
| Active trip | truth / resolver | bool | OperationalStatus (+ optional header chip on full page) |

## Vehicle

| UI | SOURCE | OWNER |
|----|--------|-------|
| تصنيف / ماركة / سنة / لون / لوحة | AdminDriverProfileView.vehicle | Vehicle section |

## Review timestamps

| UI | SOURCE | FORMAT |
|----|--------|--------|
| submitted/approved/rejected/changesRequested | camel or snake keys | yyyy-MM-dd or — |

## Actions

| ACTION | ROLE | HANDLER | WRITE | CONFIRM | BUSY GUARD |
|--------|------|---------|-------|---------|------------|
| عرض كامل | all with access | push DriverProfile | no | — | — |
| مراجعة التسجيل | when pending/needsChanges | DriverActivation | workflow | in activation | review screen |
| تعديل | admin | AddDrev | editor | — | — |
| تفعيل / إيقاف | admin | profile body | user update | dialog | `_actionBusy` |
| عرض الوثائق | — | sheet | no | — | — |
