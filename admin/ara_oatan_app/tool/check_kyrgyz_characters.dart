// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('${Directory.current.path}/assets/langs/ky.json');
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final text = map.values.map((e) => e.toString()).join('\n');
  final required = ['ң', 'ө', 'ү', 'Ң', 'Ө', 'Ү'];
  final errors = <String>[];
  for (final ch in required) {
    if (!text.contains(ch)) {
      // Ң may be rare; require via kyrgyz_char_sample key at minimum.
      if (ch == 'Ң' || ch == 'Ө' || ch == 'Ү') {
        final sample = map['kyrgyz_char_sample']?.toString() ?? '';
        if (!sample.contains(ch)) {
          errors.add('Missing Kyrgyz character $ch (including sample key)');
        }
      } else {
        errors.add('Missing Kyrgyz character $ch');
      }
    }
  }
  if (text.contains('\uFFFD')) {
    errors.add('Contains Unicode replacement character');
  }

  final ru = jsonDecode(
    File('${Directory.current.path}/assets/langs/ru.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final en = jsonDecode(
    File('${Directory.current.path}/assets/langs/en.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  var copiedFromRu = 0;
  for (final key in map.keys) {
    final ky = map[key]?.toString() ?? '';
    final ruV = ru[key]?.toString() ?? '';
    final enV = en[key]?.toString() ?? '';
    if (ky.length > 12 && ky == ruV && ky != enV) {
      copiedFromRu++;
    }
  }
  if (copiedFromRu > 40) {
    errors.add('Too many Kyrgyz strings identical to Russian: $copiedFromRu');
  }

  if (errors.isEmpty) {
    print('check_kyrgyz_characters: OK (ru-copies=$copiedFromRu)');
    exit(0);
  }
  print('check_kyrgyz_characters: FAIL');
  for (final e in errors) {
    print(' - $e');
  }
  exit(1);
}
