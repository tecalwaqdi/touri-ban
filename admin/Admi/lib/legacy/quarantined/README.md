# Quarantined legacy Admin sources

## profits_stats_loader.dart (removed ADMIN-2)

Dead code — zero production consumers. Used legacy `aggregateFinancialSummary`
client fallback. Authoritative finance uses `FinancialAccountingLoader` with
`requireCanonicalServer: true` (ADMIN-1).

Do not reintroduce client-side accounting fallbacks for Hub / Profits / Reports.
