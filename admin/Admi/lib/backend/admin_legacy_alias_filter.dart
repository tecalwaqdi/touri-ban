/// Filters out temporary legacy alias docs created so old customer builds
/// could resolve remapped `region_sa_{iso}_*` paths.
///
/// Real Saudi hubs use ids like `city_sa_makkah` / `region_sa_makkah` (no
/// second ISO segment) and must remain visible.
abstract final class AdminLegacyAliasFilter {
  AdminLegacyAliasFilter._();

  static final RegExp _intlAlias = RegExp(
    r'^(?:region|city|lm)_sa_(?:es|ma|pt|tn|id|my|in)_',
    caseSensitive: false,
  );

  static bool isLegacyIntlAliasId(String documentId) =>
      _intlAlias.hasMatch(documentId);

  static bool keepDocumentId(String documentId) =>
      !isLegacyIntlAliasId(documentId);

  static List<T> keepWhereId<T>(
    Iterable<T> items,
    String Function(T) idOf,
  ) {
    return items.where((item) => keepDocumentId(idOf(item))).toList();
  }
}
