const adminGeoLocales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];

/// Overlay the seven geo locales onto an existing names_i18n map.
/// Locales that are not being edited stay as stored. An edited locale is
/// written only from its own field, so Arabic is never copied into another
/// locale.
Map<String, String> adminGeoNamesForSave({
  required Map<String, String> existing,
  required Map<String, String> editedByLocale,
}) {
  final out = <String, String>{};
  existing.forEach((key, value) {
    final text = value.trim();
    if (text.isNotEmpty) out[key] = text;
  });
  for (final lang in adminGeoLocales) {
    if (!editedByLocale.containsKey(lang)) continue;
    final text = editedByLocale[lang]!.trim();
    if (text.isEmpty) {
      out.remove(lang);
    } else {
      out[lang] = text;
    }
  }
  return out;
}
