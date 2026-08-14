import '/backend/schema/cities_record.dart';

/// ترتيب عرض المدن السعودية في شاشة اختيار المنطقة / المدينة.
abstract final class TouryCityDisplayOrder {
  /// 1 مكة … 9 أبها. أي مدينة غير معروفة تُعرض بعدها.
  static const List<List<String>> rankedAliases = [
    ['مكة المكرمة', 'مكه المكرمه', 'مكة', 'مكه', 'makkah', 'mecca'],
    [
      'المدينة المنورة',
      'المدينه المنوره',
      'المدينة',
      'المدينه',
      'madinah',
      'medina',
    ],
    ['الطائف', 'الطايف', 'طائف', 'taif'],
    ['جدة', 'جده', 'jeddah', 'jiddah', 'jedda'],
    ['الرياض', 'riyadh'],
    ['الدمام', 'dammam'],
    ['تبوك', 'tabuk'],
    ['الخبر', 'khobar', 'al khobar', 'al-khobar'],
    ['أبها', 'ابها', 'abha'],
  ];

  static const int unranked = 1000;

  static int rankForName(String raw) {
    final hay = _norm(raw);
    if (hay.isEmpty) return unranked;
    var best = unranked;
    for (var i = 0; i < rankedAliases.length; i++) {
      final aliases = List<String>.from(rankedAliases[i])
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final alias in aliases) {
        final needle = _norm(alias);
        if (needle.isEmpty) continue;
        if (hay == needle || hay.contains(needle)) {
          if (i < best) best = i;
          break;
        }
      }
    }
    return best;
  }

  static int rankForCity(CitiesRecord city) {
    final names = <String>[
      city.naim,
      ...city.namesI18n.values,
    ];
    var best = unranked;
    for (final name in names) {
      final rank = rankForName(name);
      if (rank < best) best = rank;
    }
    return best;
  }

  static List<CitiesRecord> sort(List<CitiesRecord> cities) {
    final copy = List<CitiesRecord>.from(cities);
    copy.sort((a, b) {
      final byRank = rankForCity(a).compareTo(rankForCity(b));
      if (byRank != 0) return byRank;
      final bySort = a.sorting.compareTo(b.sorting);
      if (bySort != 0) return bySort;
      return a.naim.toLowerCase().compareTo(b.naim.toLowerCase());
    });
    return copy;
  }

  static String _norm(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    s = s.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}
