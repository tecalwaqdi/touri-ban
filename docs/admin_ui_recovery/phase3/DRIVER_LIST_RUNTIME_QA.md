# Phase 3 — Driver List Runtime QA

**Source:** Phase 3 worktree web build `1.0.16+2018`  
**Serve:** SPA fallback `http://127.0.0.1:8083/` (Python SPA handler)  
**Route:** `/drever`  
**Browsers:** Native Safari (Super Admin session) + Chromium Playwright overflow smoke

## Source confirmation

| Check | Result |
|-------|--------|
| PHASE 3 SOURCE | YES — built from `recovery/admin-phase3-driver-list` |
| version.json | `1.0.16` / `2018` |
| Safari Super Admin | YES (`osama` / سوبر أدمن visible in shell) |

## Idle flicker (post-load)

Timed Safari window captures **t01–t12** (1s apart, 12s idle after load):

| Metric | Value |
|--------|--------|
| unique_frames | **1** |
| size_span_bytes | **0** |
| IDLE_FLICKER_PROXY | **STABLE** |
| FULL LIST DISAPPEAR | **0** |
| UNEXPECTED SKELETON RETURN | **0** observed |

## Interactive checklist

| Step | Result | Notes |
|------|--------|-------|
| Open Driver List | PASS | Loaded table + counters |
| Wait 10s after loaded | PASS | Identical frames |
| Search / clear / filter / paginate | PARTIAL | Not scripted (Safari Apple Events JS disabled); UI controls present; debounce/filter signature covered by tests |
| Stats strip visible | PASS | total 24 / pending 5 / approved 8 / page hints online/available/busy |
| Open/close drawer | NOT AUTOMATED | List action icons present; profile out of Phase 3 scope |
| Overflow desktop/tablet/mobile | **0** | Playwright |

## Shared-list smoke (open only)

`/adminuser`, `/adminALLhgZ`, `/adminM3alm` — navigated in Playwright; overflow **0**; no infinite-loader assertion without auth in Chromium (redirects to login/`homePage`).

## Data verification (masked)

From Safari Super Admin capture on Phase 3 local:

| DRIVER | UI STATUS | SOURCE STATUS | UI PHONE | SOURCE PHONE | UI COUNTRY/CITY | MATCH |
|--------|-----------|---------------|----------|--------------|-----------------|-------|
| Row1 (masked name) | معتمد + نشط | registration approved + account active (adapter axes) | masked | same formatter path | city shown (e.g. Bishkek/Mecca family) | MATCH (UI axes consistent) |
| Row2 | يحتاج تعديلات + نشط | needs_changes + active | masked | — | city shown | MATCH |
| Row3 | بانتظار المراجعة | pending_review | masked | — | city shown | MATCH |

List count label: **20 من 24** aligns with pageSize 20 and total chip **24**.

Online/available chips are **page hints** (documented), not full-collection SoT.

## Artifacts

- `/tmp/phase3_driver_list_qa/safari_phase3_drever2.png`
- `/tmp/phase3_driver_list_qa/safari_loaded_stable.png`
- `/tmp/phase3_driver_list_qa/flicker/t*.png`
- `/tmp/phase3_driver_list_qa/report.json`
