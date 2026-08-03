# PHASE 1 FINDINGS — Touri Taxi Driver Completion

**Date:** 2026-07-28  
**Source of truth:** filesystem + `build.gradle` + `google-services.json` + `.firebaserc` + `nav.dart` + `user_record.dart`  
**Deploy:** NOT performed (no Production publish)

---

## 1. مسار تطبيق السائق الفعلي

`d:\Projects\ara\admin\mndob-main`

- pubspec name: `mndob`
- version: `2.0.2+9`
- entry: `lib/main.dart`

## 2. مسار تطبيق المستخدم الفعلي

`d:\Projects\ara\admin\ara_oatan_app`

- pubspec: customer app
- entry: `lib/main.dart`

## 3. مسار لوحة الإدارة الفعلية

`d:\Projects\ara\admin\Admi`

- entry: `lib/main.dart`

## 4. Package Name لكل تطبيق

| App | Android `applicationId` | iOS Bundle (from project) |
|-----|-------------------------|---------------------------|
| Driver | `com.mycompany.mndob2` | `com.mycompany.mndob3` |
| Customer | `com.mycompany.araoatanapp` | (customer iOS in ara_oatan_app) |
| Admin | `com.mycompany.tutorialmultilanguageapp` | (admin iOS in Admi) |

Evidence:
- `mndob-main/android/app/build.gradle` L67
- `ara_oatan_app/android/app/build.gradle` L69
- `Admi/android/app/build.gradle` L59
- `mndob-main/ios/.../project.pbxproj` → `com.mycompany.mndob3`

## 5. Firebase Project ID لكل تطبيق

**All three apps use the same project:**

`tutorial-multi-language-70gx4j`

Evidence:
- `mndob-main/android/app/google-services.json` → `project_id`
- `ara_oatan_app/android/app/google-services.json` → `project_id`
- `Admi/android/app/google-services.json` → `project_id`
- `ara_oatan_app/firebase/.firebaserc` → `"default": "tutorial-multi-language-70gx4j"`
- `Admi/firebase/.firebaserc` → same
- `mndob-main/lib/backend/firebase/firebase_config.dart` → `projectId: "tutorial-multi-language-70gx4j"`

Canonical rules/functions tree: `ara_oatan_app/firebase/`

## 6. النسخ المكررة التي وُجدت

| Duplicate | Path / ID | Action |
|-----------|-----------|--------|
| Old Android package in Firebase clients | `com.mycompany.mndob` (in google-services alongside mndob2/mndob3) | Do not build against this |
| Legacy Wasl registration | `lib/new_driver_registration/` route `NewDriverRegistration` | Do not use for production UX |
| Production registration | `lib/regdrever/` | USE THIS |
| Legacy trip detail | `lib/tfasel_copy/` | Prefer `tfasel_orser` |
| Demo screens | `demo_a_i1`, `sfdf`, `dfddf`, `taimr_demo` | Exclude from QA path |
| Legacy lists | `hgz_copy`, `hgzmgbol`, `hgzmktml`, `dashboard5`, `mktmlh` | Exclude |
| Release artifacts folder | `admin/store_release` | Not an app source |
| Prior incomplete docs | `mndob-main/docs/DRIVER_*.md` vs `docs/driver-completion/` | Completion pack is authoritative |

## 7. مخطط تشغيل تطبيق السائق الحالي (من الكود)

```
main()
  → EasyLocalization + DriverCachedAssetLoader (assets/langs)
  → initFirebase()  [project tutorial-multi-language-70gx4j]
  → DriverBootstrap.clearAnonymousSession()
  → FFAppState.initializePersistedState()
  → MyApp + GoRouter(refreshListenable: AppStateNotifier)
  → route '/' = DriverAuthGate
       ├─ no user / anonymous → Onboarding (once) or Login1
       ├─ user doc loading → splash spinner (timeout → Login)
       ├─ pendingApproval | rejected | suspended | active* | onTrip → NavBarPage
       └─ incompleteProfile → Login1  (NEVER auto Regdrever)
  → Login1 email+password
       → if ismndob → route by DriverLifecycle (home shell)
       → else signOut
  → Regdrever (manual CTA only): Account → GPS map → Vehicle
       → Auth create + user/{uid} set (actev_mndob:false, registration_status:pending_review)
       → go Home
  → Home: Go Online gated by actev_mndob + GPS via DriverOnlineState / DriverEligibilityService
```

## 8. جميع شاشات السائق الموجودة

### Production / in use
- Login1 — `lib/login1/`
- DriverOnboarding — `lib/onboarding/driver_onboarding_widget.dart`
- DriverAuthGate — `lib/components/driver_auth_gate.dart`
- Regdrever — `lib/regdrever/`
- DriverPendingApproval — `lib/driver_pending_approval/`
- Home — `lib/home/`
- Now — `lib/now/`
- Accepted — `lib/accepted/`
- Completed — `lib/completed/`
- Cansel — `lib/cansel/`
- Profile07 — `lib/profile07/`
- TfaselOrser — `lib/tfasel_orser/`
- Chat — `lib/chat/`
- DriverWallet — `lib/driver_wallet/`
- UpdetBank — `lib/updet_bank/`
- Suport — `lib/suport/`
- ProfileUpdatePage — `lib/profile_update_page/`
- Listvill — `lib/listvill/`
- Ttb3 — `lib/ttb3/`
- RegCompne — `lib/reg_compne/` (company; not consumer driver path)

### Legacy / demo (registered but not production UX)
- NewDriverRegistration, TfaselCopy, Dashboard5, HgzCopy, Hgzmgbol, Hgzmktml, DemoAI1, Dfddf, Sfdf, TaimrDemo, Mktmlh

## 9. جميع Routes (من `nav.dart` + widgets)

| name | path |
|------|------|
| `_initialize` | `/` |
| `Login1` | `/login1` |
| `DriverPendingApproval` | `/driverPendingApproval` |
| `hgzCopy` | `/hgzCopy` |
| `Dashboard5` | `/dashboard5` |
| `Profile07` | `/profile07` |
| `mktmlh` | `/mktmlh` |
| `tfaselCopy` | `/tfaselCopy` |
| `hgzmgbol` | `/hgzmgbol` |
| `hgzmktml` | `/hgzmktml` |
| `reg_compne` | `/regCompne` |
| `demoAI1` | `/demoAI1` |
| `NewDriverRegistration` | `/newDriverRegistration` |
| `sfdf` | `/sfdf` |
| `Now` | `/neworder` |
| `Accepted` | `/Accepted` |
| `Completed` | `/Completed` |
| `regdrever` | `/regdrever` |
| `listvill` | `/listvill` |
| `home` | `/home` |
| `suport` | `/suport` |
| `TfaselOrser` | `/tfaselOrser` |
| `dfddf` | `/dfddf` |
| `Chat` | `/chat` |
| `UpdetBank` | `/updetBank` |
| `DriverWallet` | `/driverWallet` |
| `taimrDemo` | `/taimrDemo` |
| `ttb3` | `/ttb3` |
| `cansel` | `/cansel` |
| `ProfileUpdatePage` | `/profileUpdatePage` |

## 10. حالات التسجيل والتفعيل الفعلية

### Firestore fields on `user/{uid}` (schema + writers)

| Field | Type | Meaning in code |
|-------|------|-----------------|
| `ismndob` | bool | Is driver account |
| `ismndom` | bool | Pending-driver flag used by admin query |
| `actev_mndob` | bool | Admin-activated / approved to work |
| `ngl` | bool | Online |
| `mndon_newacc` | bool | Busy / on trip |
| `registration_status` | string | `pending_review` \| `submitted` \| `changes_requested` \| `approved` \| `rejected` \| `suspended` \| `blocked` |
| `rejection_reason` | string | Admin note |

### Code enum `DriverLifecycle` (`driver_lifecycle_state.dart`)

`loggedOut`, `loading`, `incompleteProfile`, `pendingApproval`, `rejected`, `suspended`, `activeOffline`, `activeOnline`, `onTrip`

Resolution rules (actual):
- `actev_mndob == false` + `registration_status == rejected` → rejected
- `actev_mndob == false` + (submitted \| ismndob \| name) → pendingApproval
- else incomplete → Login (not auto register)
- `actev_mndob == true` + busy → onTrip
- `actev_mndob == true` + `ngl` → activeOnline else activeOffline

Admin approve (`Admi/lib/driver_activation/...`): sets `actev_mndob: true`, `ismndob/ismndom: true`, `registration_status: approved`, clears `rejection_reason`.

## 11. نظام اللغات في تطبيق المستخدم

- Package: **easy_localization**
- Files: `ara_oatan_app/assets/langs/{en,ar,ru,ky}.json`
- Loader: `TouryCachedAssetLoader`
- Locales: `touryProductionLocales` = en, ar, ru, ky
- Fallback: **`Locale('en')`** (`touryFallbackLocale`) — English, not Arabic
- Resolver: `lib/core/toury_resolve_locale.dart`
- Wired in `ara_oatan_app/lib/main.dart` via `EasyLocalization(...)`

Driver mirrors this with `DriverCachedAssetLoader` + `assets/langs/*` + `driverTr`.

## 12. سبب فشل التعديلات السابقة (من الكود)

1. **Anonymous auth during registration** (`regdrever` `signInAnonymously`) left `loggedIn == true` → root `/` treated guest as session → opened registration again.
2. **AuthGate previously returned `RegdreverWidget` for `incompleteProfile` / missing doc / `!ismndob`** → restored SharedPreferences draft at **last step**.
3. **Post-submit navigation raced AuthGate** → Pending UI then gate rebuild → Regdrever.
4. **Mixed gates:** Login checked `ismndob`; Online needs `actev_mndob`; Wasl screen still linked historically.
5. **Success claimed on `flutter build`** without device cold-start proof of session routing.
6. **Two registration UIs** (`regdrever` vs `NewDriverRegistration`) caused wrong deep-links.

## 13. ملفات المرحلة الثانية (Bootstrap / Session / Router) — بدء الإصلاح الآن

1. `lib/main.dart`
2. `lib/core/driver_bootstrap.dart`
3. `lib/components/driver_auth_gate.dart`
4. `lib/core/driver_lifecycle_state.dart`
5. `lib/core/driver_session_router.dart`
6. `lib/onboarding/driver_onboarding_widget.dart`
7. `lib/flutter_flow/nav/nav.dart`
8. `lib/login1/login1_widget.dart` / `login1_model.dart`
9. `lib/regdrever/regdrever_widget.dart`
10. `lib/auth/firebase_auth/auth_util.dart`
11. `lib/backend/backend.dart` (`maybeCreateUser`)

No Firebase deploy / no Production publish in this phase.
