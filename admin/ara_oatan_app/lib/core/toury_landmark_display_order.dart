import '/backend/schema/mkan_record.dart';

/// ترتيب عرض المعالم: المسجد الحرام أولاً في قائمة مكة.
abstract final class TouryLandmarkDisplayOrder {
  static const int unranked = 1000;

  static const List<String> masjidAlHaramAliases = [
    'المسجد الحرام',
    'المسجدالحرام',
    'masjid al-haram',
    'masjid al haram',
    'al-masjid al-haram',
    'al masjid al haram',
    'al-masjid al haram',
  ];

  static const List<String> masjidAlHaramDocIds = [
    'lm_sa_makkah_masjid-al-haram',
    'lm_sa_makkah_masjid_al_haram',
  ];

  static bool isMasjidAlHaramName(String raw) {
    final hay = _norm(raw);
    if (hay.isEmpty) return false;
    for (final alias in masjidAlHaramAliases) {
      if (hay == _norm(alias)) return true;
    }
    return hay.contains('المسجد الحرام') ||
        hay.contains('masjid al-haram') ||
        hay.contains('masjid al haram');
  }

  static bool isMasjidAlHaram(MkanRecord record) {
    if (masjidAlHaramDocIds.contains(record.reference.id)) return true;
    final id = record.reference.id.toLowerCase();
    if (id.contains('masjid-al-haram') || id.contains('masjid_al_haram')) {
      return true;
    }
    if (isMasjidAlHaramName(record.naim)) return true;
    for (final name in record.namesI18n.values) {
      if (isMasjidAlHaramName(name)) return true;
    }
    return false;
  }

  static int rank(MkanRecord record) =>
      isMasjidAlHaram(record) ? 0 : unranked;

  static List<MkanRecord> sort(Iterable<MkanRecord> items) {
    final copy = List<MkanRecord>.from(items);
    sortInPlace(copy);
    return copy;
  }

  static void sortInPlace(List<MkanRecord> items) {
    items.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.naim.compareTo(b.naim);
    });
  }

  static String _norm(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    s = s.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
    s = s.replaceAll('-', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}
