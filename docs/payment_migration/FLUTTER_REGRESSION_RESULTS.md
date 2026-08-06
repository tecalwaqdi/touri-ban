# Flutter Regression Results

**Branch:** `feature/vercel-ngenius-payment-backend`  
**Executed:** 2026-08-06  
**Machine:** local developer environment (darwin)

Regression is **documented with executed commands**. Failures are classified. Migration-introduced failures were fixed where identified (admin `HttpHeaders` analyzer error).

---

## Customer — `admin/ara_oatan_app`

### Commands

```bash
cd admin/ara_oatan_app
flutter pub get
flutter analyze
flutter test
```

### Results

| Command | Result |
|---------|--------|
| `flutter pub get` | Success |
| `flutter analyze` | **No issues found** |
| `flutter test` | **78 passed, 1 failed** |

### Failures

#### 1. `test/core/toury_localization_theme_test.dart` — notification template localization

- **Command:** `flutter test` / isolated re-run of the file
- **Error:** Expected localized notification body **not** to equal English when resolving a non-English locale; actual remained English:  
  `Payment for booking #42 was confirmed. We are finding a driver for you.`
- **Classification:** **Pre-existing** (locale resolution / notification template loading). Not caused by payment migration files. Notification template keys were not altered for Vercel work.
- **Action:** Left failing; tracked as pre-existing localization debt. Not blocking sandbox payment configuration.

---

## Driver — `admin/mndob-main`

### Commands

```bash
cd admin/mndob-main
flutter pub get
flutter analyze
flutter test
```

### Results

| Command | Result |
|---------|--------|
| `flutter pub get` | Success |
| `flutter analyze` | Exit 0; large volume of **warnings/info** (~1654 issues historically). **0 analyzer errors** in this run (`grep "error •"` count = 0) |
| `flutter test` | **137 passed, 0 failed** (`All tests passed!`) |

### Failures

None.

Added: `test/payment_visibility_test.dart` (documents pool visibility rules).

---

## Admin — `admin/Admi`

### Commands

```bash
cd admin/Admi
flutter pub get
flutter analyze
flutter test
```

### Results

| Command | Result |
|---------|--------|
| `flutter pub get` | Success |
| `flutter analyze` (before fix) | **1 error:** `Undefined name 'HttpHeaders'` in `lib/backend/api_requests/api_manager.dart:494` |
| `flutter analyze` (after fix) | **0 errors**, 33 info/warning issues (pre-existing style/deprecations) |
| `flutter test` | **3 passed, 1 failed** |

### Failures

#### 1. Analyzer — `HttpHeaders` undefined

- **Command:** `flutter analyze`
- **Error:** `undefined_identifier` — `HttpHeaders` (typically from `dart:io`, unavailable / not imported for web targets)
- **Classification:** **Pre-existing** in FlutterFlow `api_manager.dart`, but blocked clean analyze for admin. **Fixed** in this gap-closure pass by using the literal header name `'authorization'`.
- **Introduced by migration?** No.

#### 2. `test/seed_production_test.dart` — Firestore seed

- **Command:** `flutter test`
- **Error:** `PlatformException(channel-error, Unable to establish connection on channel.)` during `Firebase.initializeCore`
- **Classification:** **Pre-existing** — integration-style seed test requires Firebase platform channels / credentials; not a unit test. Unrelated to payment UI/API client.
- **Action:** Documented; not fixed (would require Firebase test mocking or skip).

---

## Migration-introduced Flutter risk areas checked

| Area | Status |
|------|--------|
| Customer payment flags / API client | Analyzes clean; default cash-only |
| Payment confirm / Vercel finalize path | Behind flags |
| Admin refund button | Finance + `PAYMENT_API_BASE_URL` only |
| Driver registration / approval | Untouched; tests still pass |

---

## Verdict

Flutter regression **executed**. Remaining failures are **pre-existing** (customer notification locale test; admin Firebase seed test). Admin analyzer error from `HttpHeaders` **fixed**. Cash / driver / admin non-payment flows not broken by evidence of these suites.

**Do not mark device sandbox tested** — this document is unit/analyzer regression only.
