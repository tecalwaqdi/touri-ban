# Phase 3 — Driver List UI Contract

## Target

- Enterprise, compact, Cairo, RTL, restrained teal
- Stable row/card height; no giant whitespace/cards/buttons
- Clear filters; compact status badges; obvious primary actions
- Minimal animation

## Layout

- `AdminLayoutWidget` + `AdminPageBody` (`padContent: false` — page owns padding)
- Filter bar → summary strip → content card (table or cards)
- Desktop/tablet: table via `AdminUi.useTableLayout`
- Mobile: card list only (XOR — not both)

## Status presentation (list-local)

- Registration: `AdminStatusBadgeUnified` via `AdminDriverRegistrationStatusCell`
- Operational: connection/availability via `AdminDriverOperationalStatus`
- Do not show duplicate registration badges on the same row axis
- Global badge API unification **deferred**

## Actions (list-level)

- Open details drawer (out-of-scope content changes)
- Edit / Review / Documents / Activate-Deactivate
- Add driver primary button in page header

## Non-goals

- Driver profile redesign
- Finance widgets on list
- Legacy route deletion
