# Phase 2 — Dashboard UI Contract

## Structure

1. **Compact header strip** — greeting + date + notifications (no competing refresh clutter)  
2. **Operational alerts** — compact; no full-page blank for alerts load  
3. **Quick actions** — restrained tiles; role-filtered; canonical routes only  
4. **Stats header** — title/subtitle + single refresh  
5. **Primary summary strip** — landmarks / users / active bookings  
6. **Grouped KPI cards** — content / users / bookings  
7. **Sync note** — loadedAt + reliability hint  

## Visual rules

- Compact cards; light surface + teal accent (not giant gradient slabs)  
- Consistent card height/padding  
- Cairo via theme  
- Arabic RTL first  
- No oversized decorative hero icons  
- No triplicate refresh buttons  
- Unreliable metrics: غير مؤكد  

## Navigation

- Inactive drivers KPI → **`Admindrever`** (canonical), never `AdminDrivers`  
- Quick actions only if `AdminRoleService.canAccessRoute`  
- No legacy Home/home3/AdminHome shortcuts  

## Loading

- Prefer cache paint then soft refresh  
- Linear progress while refreshing with existing cards  
- Do not blank entire dashboard on background refresh  
