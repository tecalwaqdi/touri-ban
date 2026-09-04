# Phase 4 — Driver Profile UI Contract

## Target

Enterprise, compact, Cairo, RTL, restrained teal. No giant drawer hero. Clear sections. One owner per field/axis.

## Hierarchy (drawer)

1. Compact header (avatar, name, email, phone, reg+account badges)
2. Personal (cities only)
3. Vehicle
4. Documents (no lifecycle strip)
5. Operational status (connection/availability/trip)
6. Activity / earnings / review history
7. Actions
8. Technical (collapsed)

## Hierarchy (full page)

1. Compact header (identity + reg/account badges + optional trip chip)
2. Quick summary (trips/earnings chips — not statuses)
3. Personal geo fields (no identity duplicate)
4. Operational detail section
5. Vehicle
6. Documents (no lifecycle strip)
7. Activity / finance / review / actions

## Document cards

Compact row: name, presence, expiry, one open action. No surrounding duplicate status strips when parent owns lifecycle.

## Direction

Arabic RTL chrome; email/phone/IDs/plates remain LTR-friendly via existing helpers.
