# TOURi TAXI — FINANCE F3-C2D DEPLOYMENT REPORT

**APPROVED CODE:** `b4eefdad727a4d12f0f0c8903bc50aa6e0884b24`  
**REVIEW DOC TIP:** `05f63d3`  
**DEPLOY HEAD:** `05f63d3738eadafe96adc25be91b5a5f225fc546` (docs-only descendant of approved C2)  
**PROJECT:** `tutorial-multi-language-70gx4j`  
**FUNCTIONS WORKSPACE:** `admin/ara_oatan_app/firebase/functions` (codebase `functions`)  
**NOT USED:** `admin/Admi/firebase/functions`

---

## A — Pre-deploy

| Check | Result |
|---|---|
| Branch | `recovery/admin-finance-f3c2-agent-snapshot` |
| Implementation ancestor | `b4eefda` present |
| Worktree | CLEAN (packaging-only untracked Admi module copies during deploy load; removed after; not committed) |
| Project | `tutorial-multi-language-70gx4j` |
| Tests | PASS (agent, N-Genius, V2, F1, money precision) |
| Fixtures | 5% of 7.50 → 0.38; 5% of 120 → 6.00; totals unchanged; ambiguous safe |

### Packaging note

Same Customer `index.js` load hygiene as F3-C1D: temporary local copies of Admin-only driver modules for Firebase analysis. **Not committed. Removed after deploy.**

---

## B — Exact exports (proven)

| | createCashBooking | finalizeNGeniusBooking |
|---|---|---|
| Export name | `createCashBooking` | `finalizeNGeniusBooking` |
| Region | `us-central1` | `us-central1` |
| Generation | **1st** (`gcfv1`) | **1st** |
| Runtime | nodejs22 | nodejs22 |
| Trigger | callable | callable |
| Codebase | `functions` | `functions` |

CLI:

```bash
firebase deploy --only functions:functions:createCashBooking,functions:functions:finalizeNGeniusBooking \
  --project tutorial-multi-language-70gx4j
```

---

## C — Pre-deploy versions

| Function | Version | Update time | Hash |
|---|---|---|---|
| createCashBooking | 6 | 2026-09-05T22:53:41.881Z | `4818e92…` (F3-C1D) |
| finalizeNGeniusBooking | 2 | 2026-09-05T22:53:39.903Z | `4818e92…` |

---

## D — Deploy

```
✔ functions[functions:finalizeNGeniusBooking(us-central1)] Successful update operation.
✔ functions[functions:createCashBooking(us-central1)] Successful update operation.
✔ Deploy complete!
```

**Updated production functions: 2**

---

## E — Post-deploy versions

| Function | Version | Update time | Hash |
|---|---|---|---|
| createCashBooking | **7** | **2026-09-05T23:21:16.017Z** | `d43021687aec1fc476022883cb16d56e01271241` |
| finalizeNGeniusBooking | **3** | **2026-09-05T23:21:08.218Z** | `d43021687aec1fc476022883cb16d56e01271241` |

Peer unchanged:

| Function | Hash |
|---|---|
| normalizeCashBookingCompatibility | `ac043d1187e7918da50125875858281eb882bd37` |
| approveDriverRegistration | `bd1326c7693c53c51a38f9a2a9d86323bc4ef608` |

**UNRELATED FUNCTIONS UPDATED: 0**

---

## F — No production test booking

**SAFE QA HARNESS: NO** (unchanged from C1D)  
**PRODUCTION TEST BOOKING CREATED: NO**  
**AGENT SNAPSHOT RUNTIME BOOKING: NOT_RUN_NO_SAFE_QA_HARNESS**

---

## G — Deployed source verification

- New shared hash `d430216…` ≠ prior C1D hash `4818e92…`
- Deploy package size grew (agent module included)
- Audit labels on UpdateFunction show new hash
- Approved branch source contains: `buildBookingAgentSnapshot`, `computeAgentAmountMinor`, `agent_attribution_status`, `agent_rate`, `agent_rate_type`, `agent_amount`, `agent_amount_minor`, `agent_snapshot_at`

**DEPLOYED SOURCE: VERIFIED** (hash + labels + packaged source markers; no secret dump)

---

## H — Read-only active agent census

Scan: `user` where `Isagent==true`, then FIN-9/C2 `isActiveAgent` window (`actev_user`, optional date bounds). Group by `Rev_dloh_agent`.

| Bucket | Count | Detail |
|---|---|---|
| **0 active** | **4** | `countries/chad`, `countries/niger`, `countries/nigeria`, `countries/cp5_country_1787562918003` |
| **1 active** | **9** | india, indonesia, kyrgyzstan, malaysia, morocco, portugal, saudi_arabia, spain, tunisia |
| **2+ active** | **0** | — |

Agents scanned (`Isagent`): 12 · Active after window: 9 · Countries docs: 13  
**CURRENT CONFLICTS: 0** · **AGENT_ASSIGNMENT_CONFLICT: none**

---

## I — Historical safety

| Order | Money mndob* | Agent fields |
|---|---|---|
| `03392f80…` / CASH-03392F80A1 | still null | still null |
| `7b9a80c3…` / CASH-7B9A80C306 | still null | still null |

**HISTORICAL ORDERS MODIFIED: 0** · **BACKFILL: 0** · **SETTLEMENTS: 0**

---

## J — Logs

Post-C2D window: UpdateFunction audit events only for the two targets.  
No new runtime agent-query / transaction / undefined-field errors after this deploy (no post-deploy invocations).

**NEW TARGET FUNCTION ERRORS: 0**

---

## K — Next legitimate booking checklist

When the **next real** Cash or Online booking is created after C2D, QA must inspect the order doc:

### Core money (F3-C1)
- [ ] `total_mndob2`, `total_app`, `total_vat`, `total_mndob`, `total` all present numeric
- [ ] Values match verified quote (not fabricated zeros)
- [ ] Financial money snapshot → **COMPLETE**

### Agent (F3-C2)
- [ ] `agent_attribution_status` present (`attributed` | `none` | `ambiguous` | `rate_missing` | `platform_missing`)
- [ ] If **one** valid country agent: `agent_id`, `agent_rate`, `agent_rate_type=percent_of_platform_fee`, `agent_amount`, `agent_amount_minor`, `agent_snapshot_at`
- [ ] If **none**: status `none` · no invented `agent_id` / amount
- [ ] If **ambiguous**: status `ambiguous` · no `agent_id` / amount · optional `agent_ambiguous_agent_ids`
- [ ] Agent amount ≈ share of **that order’s** `total_app` (not a later rate)
- [ ] Customer `total` / driver `total_mndob` unchanged by agent fields
- [ ] Changing current country agent **after** booking does **not** rewrite these fields

**OBSERVABILITY CHECKLIST: READY**

---

## L — One active agent invariant / C3

| Layer | State |
|---|---|
| DB | NO unique enforcement |
| Admin | PARTIAL (create does not hard-block second agent) |
| Functions | PARTIAL (`ambiguous` on booking; no assignment mutation) |

Live scan: **no 2+ conflicts today**.  
Zero-agent countries (chad/niger/nigeria + QA cp5) will get explicit `none` on new bookings — accounting-safe.

**C3 REQUIRED: YES** — preventive hard enforcement still recommended before trusting F3-B agent rollups at scale (Admin can still create a second agent; C2 only protects attribution).

---

## FINAL

```
F3-C2D DEPLOY: PASS
FUTURE AGENT SNAPSHOT: DEPLOYED_CODE_VERIFIED
READY_FOR_F3-C3: YES
READY_FOR_F3-B: NO
```

**STOP.**
