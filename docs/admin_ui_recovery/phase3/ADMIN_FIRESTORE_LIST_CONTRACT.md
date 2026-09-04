# Phase 3 — AdminFirestoreList Reload / Loading Contract

## Semantic reload (MUST)

Reload (hard `_resetAndLoad`: clear rows + skeleton) **only** when:

1. `query` collection identity changes
2. `pageSize` changes
3. `reloadKey` changes (filters / search signature / explicit key)
4. Explicit invalidate where caller changes `reloadKey` or remounts with new key

## Must NOT reload

- Parent rebuilt
- `queryBuilder` / `countQueryBuilder` **lambda identity** changed but equivalent behavior
- Unrelated stats / cosmetic `setState`
- Drawer open/close
- Widget rebuilt with equivalent `reloadKey` + `pageSize` + `query`

## Gate API

```dart
bool adminFirestoreListShouldReset({
  required Object? oldQuery,
  required Object? newQuery,
  required int oldPageSize,
  required int newPageSize,
  required String? oldReloadKey,
  required String? newReloadKey,
});
```

**Backward compatible:** screens that omit `reloadKey` still reload only on query/pageSize change. Screens that previously relied on `countQueryBuilder` identity as a side-channel reload **must** already bump `reloadKey` when filters change (Drivers, Bookings, Landmarks do).

## Loading states

| STATE | UI |
|-------|-----|
| INITIAL_LOADING | `_loading && _items.isEmpty` → skeleton / `loading` slot |
| LOADED | builder with rows |
| REFRESHING | explicit `refresh()` / `_lightRefresh`: **keep rows**; no blank list |
| EMPTY | completed query, zero rows → empty widget from page |
| ERROR | empty+error → error state; rows+error → banner, keep rows |

## Hard vs soft

| Path | When | Clears rows? |
|------|------|--------------|
| `_resetAndLoad` | didUpdateWidget semantic gate | YES (query invalidated) |
| `_resetAndReload` / `refresh()` | explicit refresh | NO if rows present → `_lightRefresh` |
| `_lightRefresh` | CRUD scope notify | NO |

## Driver list wiring

```
reloadKey: '${_filters.signature}|${_pageSize}|${_extra.signature}'
ValueKey: 'drivers_${_filters.signature}_${_pageSize}_${_extra.signature}'
countQueryBuilder: applyDriverFiltersCore  // aggregate only; NOT a reload signal
```
