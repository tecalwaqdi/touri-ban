# Phase 4 — Driver Profile Runtime QA

**Source:** Phase 4 worktree web `1.0.16+2018`  
**Serve:** SPA `http://127.0.0.1:8083/` (Phase 4 `build/web`)  
**Entry:** `/drever` → details drawer / `/driverProfile`

## Source confirmation

| Check | Result |
|-------|--------|
| PHASE 4 BUILD | YES |
| version.json | 1.0.16 / 2018 |
| Safari Super Admin list | YES (`osama` / سوبر أدمن; counters 24 / pending 5 / approved 8) |
| RTL / Cairo shell | PASS |

## Profile open automation note

Flutter CanvasKit hit-testing via `cliclick` frequently missed the eye/row target and hit **إضافة مندوب** (Add Driver) instead. Full drawer pixel QA therefore relies on:

1. Code ownership contracts + focused tests (dedupe, license front/back/legacy)
2. Prior authenticated list session proving Phase 4 origin + list stability
3. Manual Safari verification recommended for drawer scroll/documents when promoting

## Observed on authenticated Phase 4 list (Safari)

| Check | Result |
|-------|--------|
| LIST LOADED | PASS |
| LIST SKELETON AFTER STABLE LOAD | 0 (when session healthy) |
| HORIZONTAL OVERFLOW (list) | 0 observed |
| DRIVER LIST MODIFIED | NO (Phase 3 freeze) |

## Duplicate ownership (code + source audit)

| Item | Before | After |
|------|--------|-------|
| Phone | header + KV | header only |
| Registration stack | header + section | header only |
| Lifecycle strip in docs | always | `showLifecycleStrip: false` in drawer/profile |
| Operational axes | header + section | OperationalStatus section |
| Raw authStatus enum | shown | removed |
| Legacy+front/back license | model already correct | tests lock behavior |

## Data verification (masked; list-visible axes)

| DRIVER | IDENTITY | STATUS | VEHICLE | NOTES |
|--------|----------|--------|---------|-------|
| A (approved/active) | MATCH list columns | MATCH معتمد+نشط | MATCH model/plate | Entry row type |
| B (needs changes) | MATCH | MATCH يحتاج تعديلات | MATCH | |
| C (pending) | MATCH | MATCH بانتظار المراجعة | MATCH | |

Document slot MATCH deferred to authenticated drawer open (model tests cover front/back/legacy).

## Artifacts

`/tmp/phase4_driver_profile_qa/qa_list.png`, `list_ready.png`, `final_list.png`
