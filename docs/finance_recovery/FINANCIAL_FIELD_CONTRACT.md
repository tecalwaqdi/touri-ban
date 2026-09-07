# Financial field contract (F0)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Collection:** `order` (plus optional embedded `financial_snapshot`, settlement docs).

Units: major currency units unless `*_minor` (integer minor units).

---

## Operational / payment status fields

| Field | Meaning | Unit | Writer | Reader | When written | Mutable? | Legacy/current | Canonical? | Recomputable? | Country/VAT dependency |
|---|---|---|---|---|---|---|---|---|---|---|
| `status_code` | Operational trip lifecycle | enum-like string | Driver/Customer apps + CF trip flows | Ops + Finance | Trip transitions | Yes until terminal | CURRENT | **YES (ops)** | No (history) | No |
| `halh` | Legacy status string | string | Legacy clients | Labels / weak finance fallback | Historical | Often yes | LEGACY | No | Partial | No |
| `halh_order` | Legacy enum (`Paid`/`Cash`/…) | enum/string | Legacy | OrderRecord / weak helpers | Historical | Yes | LEGACY | No | Partial | No |
| `halh_text` | Arabic display status | string | Clients | UI labels | Display sync | Yes | LEGACY display | No | Yes from code | No |
| `PaymentMethod` | Cash / Online / … | string/enum | Checkout | Finance channel | At pay choose | Rarely | CURRENT | YES (method) | No | No |
| `payment_status` | unpaid / pending_cash / cash_collected / paid / … | string | Payments / cash CF | Finance payment state | Payment events | Yes | CURRENT | YES (payment) | No | No |
| `cash_collection_status` | pending / collected | string | Cash confirmation CF | Finance | Cash confirm | Yes | CURRENT (when present) | YES for cash collect axis | No | No |

---

## Money snapshot fields on order

| Field | Meaning | Unit | Writer | Reader | When written | Mutable? | Legacy/current | Canonical? | Recomputable? | Country/VAT dependency |
|---|---|---|---|---|---|---|---|---|---|---|
| `total` | Customer total (often used when `total_mndob2` missing) | major | Pricing at create/complete | Adapter / UI | Trip pricing | Should be immutable after complete | CURRENT/LEGACY overlap | Soft canonical gross fallback | Risky | VAT policy at write |
| `total_mndob2` | Gross base fare (engine label: gross) | major | Pricing / finance writers | Accounting engine | Preferred at complete | Should be immutable | CURRENT preferred gross | **YES preferred gross** | Risky | Yes |
| `total_app` | Platform / company commission | major | Pricing | Accounting / settlements | At complete | Should be immutable | CURRENT | **YES commission** | Risky | Rate at write |
| `total_vat` | VAT amount | major | Pricing | Accounting | At complete | Should be immutable | CURRENT | **YES VAT** | Risky | Country VAT |
| `total_mndob` | Driver net (stored) | major | Pricing | Accounting normalizeDriverNet | At complete | Should be immutable | CURRENT | Soft (also derived) | Yes from components | Yes |
| `ksm` | Legacy/alternate amount | major | Legacy | Adapter | Historical | Unknown | LEGACY | No | Unknown | Unknown |
| `currency` / `currency_code` | ISO currency | string | Pricing | MoneyAmount | At create | Rarely | CURRENT | YES | No | Defines minor scale |
| `financial_snapshot` | Structured immutable trip finance blob | map / minors | V3 writers (when enabled) | `TripFinancialSnapshot` | At complete | Immutable intent | CURRENT v3 | YES when present | No | Embedded |

---

## Agent attribution fields

| Field | Meaning | Unit | Writer | Reader | When written | Mutable? | Legacy/current | Canonical? | Notes |
|---|---|---|---|---|---|---|---|---|---|
| `agent_id` | Agent at trip time | uid | Snapshot writers (sparse on live) | Adapter | Complete | Immutable intent | Emerging | Desired | Often null on live cash completes |
| `agent_scope` | Scope id | string | Snapshot | Adapter | Complete | Immutable intent | Emerging | Desired | |
| `agent_rate` / `agent_rate_type` | Rate | % or amount | Snapshot | Adapter | Complete | Immutable intent | Emerging | Desired | |
| `agent_amount_minor` | Agent due | minor | Snapshot | Adapter | Complete | Immutable intent | Emerging | Desired when present | |
| `agent_currency` | Currency | string | Snapshot | Adapter | Complete | Immutable intent | Emerging | | |
| `agent_snapshot_at` | Timestamp | ISO | Snapshot | Adapter | Complete | Immutable | Emerging | | |
| `agent_attribution_status` | Quality | string | Snapshot | Adapter | Complete | | Emerging | | |
| User `Agent_total` | Agent % of platform fee (prospective) | percent | Admin agent profile | Agent finance | Profile edit | Mutable | CURRENT for prospective | Not per-trip canonical | Used when exclusive country agent |

Order country: `Rev_dolh`. Agent country: user `Rev_dloh_agent`.

---

## Settlement entities

| Field / collection | Meaning | Writer | Reader | Canonical? |
|---|---|---|---|---|
| `financial_settlements` | Settlement header (status, currency, amounts) | `settlement_ledger.js` / payments CF | Settlements UI | YES for settlement axis |
| Settlement payment docs | Partial/full payments | `settlement_payments.js` | Details UI | YES |

---

## Conflicts

1. Live completed cash trips frequently have `total` set but `total_mndob2` / `total_mndob` null → engine confidence drops / falls back.
2. `halh_order: Cash` vs `PaymentMethod: Cash` vs `payment_status: pending_cash` — three axes; must not collapse.
3. `OrderStatusHelper` treating Arabic complete as paid contradicts field contract.
4. Fixtures populate fuller money fields than many production cash completes — **do not** use fixture totals as live truth.
