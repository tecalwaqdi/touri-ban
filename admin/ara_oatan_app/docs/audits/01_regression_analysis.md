# 01 — Regression Analysis

**Date:** 2026-07-18  
**Scope:** Customer ↔ Cloud Functions ↔ Driver status/payment contracts  
**Git:** Clone has **no commits** (`main` empty). Entire tree untracked. History-based regression proof is **unavailable** on this machine.

## Method

| Source | Used? |
|--------|-------|
| `git log` / `git blame` | **No** — no commits |
| Code inspection (CF + Flutter) | Yes |
| Duplicate tree compare (`admin/mndob-main` vs root `mndob-main`) | Yes |
| Runtime / device E2E | **Not run** this session |

## Production matrix (context)

| Component | Path | Package / Bundle | Firebase | Production? |
|-----------|------|------------------|----------|-------------|
| Customer | `admin/ara_oatan_app` | Android `com.mycompany.araoatanapp` / iOS `com.mycompany.araoatanapp2` | `tutorial-multi-language-70gx4j` | **YES** |
| Driver | `admin/mndob-main` | Android `com.mycompany.mndob2` / iOS `com.mycompany.mndob3` | same | **YES** |
| Driver duplicate | `mndob-main` (root) | same IDs, older `v2.0.0+6` | same | **NO — archive** |
| Admin | `admin/Admi` | `com.mycompany.tutorialmultilanguageapp` | same | **YES** |
| `arawatan/` | redirect only | — | — | **ARCHIVE** |

**CRITICAL (OPEN):** Driver `google-services.json` has `package_name` `com.mycompany.araoatanapp` (customer) while `build.gradle` `applicationId` is `com.mycompany.mndob2`.

## Regressions found

### 1. Status code mismatch (BLOCKER) — Status: FIXED

| Side | Wrote / expected |
|------|------------------|
| Cloud Function (`ngenius_payments.js`) | `status_code` / `halh_text` = `awaiting_driver` |
| Customer client | Arabic pending **or** `pending_driver` |

**Impact:** Cancel UI, `isPending`, auto-cancel, bookings list broken.

**Fix applied (local):**

- CF writes `status_code=pending_driver` + Arabic `halh_text` pending
- Localizer aliases `awaiting_driver`
- `list22` no longer treats `halh_order` Paid as trip completed
- Cancel uses `isPending`
- Auto-cancel queries `status_code` too

### 2. Cash book-now default (CRITICAL) — Status: FIXED

| Behavior | Before | After |
|----------|--------|-------|
| Unset payment | Treated as cash via `touryIsCashBookNowPayment` + `touryEnsureCashPaymentIfUnset` | Cash book-now requires **explicit** cash only; ensure is **no-op** |

### 3. Localization (prior session) — Status: PARTIAL

- Locales restricted to `ar` / `en` / `ru` / `ky`
- `gen-l10n` in use
- Status localizer introduced (partial coverage)

## Remaining blockers

| Item | Status |
|------|--------|
| N-Genius sandbox E2E | OPEN — not run |
| Functions / Rules redeploy | OPEN — code fixed locally only |
| Driver `google-services` package mismatch | OPEN |
| Full device E2E (customer ↔ driver ↔ admin) | OPEN |
| Git history for deleted-feature proof | OPEN — impossible on empty clone |
| `flutter build` release | OPEN — not confirmed |
| Integration tests on device | OPEN |

## Verdict

**READY FOR INTERNAL QA** at best after unit tests pass. **NOT READY FOR STORE.** If payment remains sandbox-only → **CLOSED TESTING** when E2E sandbox passes.
