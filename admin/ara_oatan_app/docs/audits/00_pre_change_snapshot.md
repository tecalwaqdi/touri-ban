# 00 — Pre-change Snapshot

**Date:** 2026-07-18  
**Scope:** Touri Taxi full-system audit / regression recovery  
**Operator:** Cursor audit agent

## Git state

| Item | Value |
|------|-------|
| Working directory | `d:\Projects\ara\admin` (repo root appears to be `d:\Projects\ara`) |
| Current branch | `main` |
| Commits | **None** — `No commits yet` |
| HEAD | unavailable |
| Staged changes | none |
| Untracked | entire tree (`admin/`, `docs/`, `mndob-main/`, `arawatan/`, APK, localization changelog) |

**Risk:** No Git history means regression analysis cannot use `git log` / `git blame` on this clone. Recovery must rely on code comparison between duplicates, docs, and runtime contracts.

**Policy:** Do not delete untracked work. No destructive clean. Branch `audit/full-system-recovery` cannot be meaningfully created without an initial commit (deferred; work continues on working tree).

## Toolchain

| Tool | Version |
|------|---------|
| Flutter | 3.44.4 (stable) |
| Dart | 3.12.2 |
| DevTools | 2.57.0 |
| Java | (see local JDK; used by Android Gradle) |
| Node / npm / Firebase CLI | present in environment / `.tools` when available |

## Application roots discovered

| Path | Role |
|------|------|
| `admin/ara_oatan_app` | Customer app (Touri Taxi) |
| `admin/mndob-main` | Driver app (canonical) |
| `mndob-main` (repo root) | Driver duplicate (stale) |
| `admin/Admi` | Admin panel |
| `arawatan/` | Redirect / archive README only |
| `admin/ara_oatan_app/firebase` | Customer Functions + rules |
| `admin/Admi/firebase` | Admin Firebase config |
| `admin/mndob-main/firebase` | Driver Firebase config |

## Environment files (names only — secrets not logged)

Expected patterns present under apps: `.env*` (if any), `google-services.json`, `GoogleService-Info.plist`, `keystore.properties`, Firebase function env/secrets. **Do not print secret values.**

## Pre-change risks

1. Uncommitted localization + prior payment work may already have altered booking/status contracts.
2. Driver `google-services.json` may list wrong `package_name` (customer package) — Firebase Android config risk.
3. No Git baseline → hard to prove “what was deleted” from history on this machine.
4. Success of `flutter analyze` does not prove E2E booking/payment/driver sync.

## Snapshot decision

Proceed with **production identification → contract audit → fix blockers** without wiping working tree.
