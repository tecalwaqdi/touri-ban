# Touri Migration and Rollback

**Date:** 2026-07-18  
**Note:** This clone has **no git commits**; rollback cannot rely on git revert until a commit baseline exists.

## Data migration (status field)

| Change | Direction | Risk |
|--------|-----------|------|
| Prefer `status_code` | Readers already updated to query/use it | Low if dual-read kept |
| CF write `pending_driver` instead of `awaiting_driver` | New orders only after deploy | Legacy docs may still show `awaiting_driver` |
| Localizer alias `awaiting_driver` → pending | Read-side safety net | Keep until old docs aged out |

### Optional backfill (if needed)

| Query | Action |
|-------|--------|
| `status_code == awaiting_driver` OR legacy text | Set `status_code=pending_driver`; set Arabic pending `halh_text` if empty/wrong |

Run only after Functions deploy; backup export first.

## Payment migration

| Change | Notes |
|--------|-------|
| Stop unset→cash | No Firestore migration required for method |
| Existing ambiguous docs | Review manually if any were auto-cash |

## Rollback plan

| Layer | Rollback action | Status / caveat |
|-------|-----------------|-----------------|
| Cloud Functions | Redeploy previous function bundle that matches last known-good | OPEN — need artifact/version tag; no git history here |
| Client apps | Reinstall previous internal build | Keep prior APK/IPA in release store |
| Localizer alias | Keep alias even when rolling CF if old CF writes `awaiting_driver` | Safe |
| Rules | Redeploy previous rules file | If changed |

## Do not

- Delete untracked trees as “cleanup” without backup  
- Ship root `mndob-main` as rollback of driver  
- Remove `awaiting_driver` alias until production has zero legacy docs  

## Status

| Item | Status |
|------|--------|
| Documented dual-read / alias strategy | FIXED |
| Actual Functions rollback artifact | OPEN |
| Git-based rollback | OPEN (empty clone) |
