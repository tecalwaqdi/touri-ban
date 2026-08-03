# Audit remediation progress — 2026-07-21

Local fixes only. **No firebase deploy.**

## Done this session

| ID | Fix |
|---|---|
| C-01 | Documented canonical Firebase root + synced `firestore.rules` mirrors → `docs/audits/FIREBASE_SINGLE_SOURCE.md` |
| C-03 | Cash fallback rejects inconsistent quotes / bad GPS; stamps `pricing_authority: client_fallback_pending_cf`; rules require matching `pricing_quote_halalas` |
| C-04 | Rules: approved active drivers can browse unassigned open pool + claim order |
| C-05 | Claim key allow-list; assigned driver cannot reassign; `completeTrip` checks prior status; cash complete carve-out without editing totals |
| C-06 | Privileged user fields now include `is_partner` + `actevMndob` lock |
| C-07 | Browse/claim require `actevMndob` (or driver claim) |
| H-01 | Driver `getVariableText` uses language-code switch (no `[en,ar][index]` RangeError) |
| H-02 | Admin locales → `en/ar/ru/ky`; `getVariableText`/`getText` ky fallback |
| H-03/H-04 | Removed Riyadh-as-GPS; reject only `(0,0)` pair; map shell = Makkah area for paint-only |

## Still blocked / not claimed ready

| ID | Status |
|---|---|
| C-02 | N-Genius Functions still unpublished (Cloud Billing) |
| C-03 full | Server-authoritative pricing needs deployed `createCashBooking` |
| H-05+ | Dual tracking / push spam / Storage ACL / admin finance scope — not in this batch |
| Analyze | `flutter analyze` / `dart analyze` hung under SDK lock (same as audit note); IDE lints used for changed files |

## Deploy gate

Do **not** deploy rules/functions until operator approves. After Billing: deploy from `ara_oatan_app/firebase` only.
