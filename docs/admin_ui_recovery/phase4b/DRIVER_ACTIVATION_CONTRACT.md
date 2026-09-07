# Phase 4B — Driver Activation Contract

## CRITICAL SEPARATION

| Axis | Field(s) | Owner |
|------|----------|-------|
| Registration | `registration_status` (+ `submission_status`) | Registration review (`DriverActivation` / `reviewDriver*`) |
| Operational account | `actev_mndob` (+ `account_status`) | Operational activate/deactivate |
| Online | `ngl` / `is_online` / `operational_status` | Driver App |
| Suspension | `registration_status=suspended` + `account_status=suspended` + `actev_mndob=false` | Profile Suspend |

**Never** treat `registration_status=approved` alone as active. Driver App requires `actev_mndob` for online eligibility.

## Canonical operational field

- **ACTIVATION FIELD:** `actev_mndob`
- **VALUES:** `true` | `false` | missing (unknown / needs review)

## Patches (`AdminDriverReviewActions`)

| Action | Patch | Touches registration? |
|--------|-------|------------------------|
| Operational activate | `operationalActivatePatch` | **No** |
| Operational deactivate | `operationalDeactivatePatch` | **No** |
| Suspend | `suspendPatch` | **Yes** → suspended |
| Registration approve | `approvePatch` | **Yes** → approved + actev true |

## Eligibility (`operationalActivationBlockers`)

Blocks when:

- suspended / blocked
- registration not approved (pending / needs_changes / rejected / …)
- missing work area or vehicle type
- open change requests

**INVALID ACTIVATION:** BLOCKED with visible Arabic reasons via `appTr`.

## UI owners

| Surface | Activate | Deactivate | Suspend | Registration review |
|---------|----------|------------|---------|---------------------|
| Profile | yes | yes | yes | pending/needs_changes |
| List `/drever` | yes | yes (not suspend) | no | menu |
| Legacy `/adminDrivers` | via review page | operational deactivate | — | open activation |
| `DriverActivation` | approve CF/path | — | — | approve/reject/changes |

## Authoritative write for operational toggle

- Direct Firestore patch via `operationalActivatePatch` / `operationalDeactivatePatch`
- List + profile + legacy pending list aligned
- Registration approve remains CF/`reviewDriver` + `approvePatch` path

## Side effects

- Sets `account_status`, forces `operational_status=offline`, `ngl=false`
- Does **not** set custom claims (Driver App reads `actev_mndob` from profile)
- Audit: list toggle uses `AdminAuditLog.recordToggle`
- List soft refresh: `AdminListRefresh.notify(representatives)`
- Profile reload: `onChanged` → `_load`

## Driver App contract (READ_ONLY verified)

- `DriverOperationalEligibilityResolver`: requires `actevMndob` and not suspended
- `driver_online_state.dart`: never self-activate without `actev_mndob`
- **MATCH** with Admin operational field

## Roles

- Same as edit: Super Admin / Country Agent scoped / Transport company scoped
- Cross-country edit/activation: blocked by `AdminResourceGuard.canEditDriver`
