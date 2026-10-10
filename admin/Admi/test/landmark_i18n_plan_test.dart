import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/i18n/landmark_i18n_plan.dart';

void main() {
  test('source hash matches the Cloud Function vector', () {
    expect(
      landmarkSourceHash('ar', 'قلعة'),
      '73a06fd68f8d96f73d6dd723b741f45830afd634e27c9078dba9628601f2badf',
    );
  });

  test('merge keeps the other locale keys and the source text', () {
    final merged = mergeLandmarkI18nPatch(
      {
        'ar': 'قلعة',
        'en': 'Hand edited',
        'zh_Hans': '城堡',
        'tr': 'Kale',
        'az': 'Qala',
        'ka': 'ციხე',
        'id': 'Benteng',
      },
      {
        'ar': 'should not replace source',
        'fr': 'Château',
        'zh_Hans': 'should not replace',
        'de': 'ignored',
      },
      sourceLocale: 'ar',
    );

    expect(merged['ar'], 'قلعة');
    expect(merged['en'], 'Hand edited');
    expect(merged['zh_Hans'], '城堡');
    expect(merged['tr'], 'Kale');
    expect(merged['az'], 'Qala');
    expect(merged['ka'], 'ციხე');
    expect(merged['id'], 'Benteng');
    expect(merged['fr'], 'Château');
    expect(merged.containsKey('de'), isFalse);
  });

  test('needs a call only for missing or stale machine text', () {
    expect(
      needsLandmarkAzure(
        sourceLocale: 'ar',
        sourceText: 'قلعة',
        existing: {
          'ar': 'قلعة',
          'en': 'Castle',
          'fr': 'Château',
          'ky': 'Сепил',
          'pt': 'Castelo',
          'ru': 'Крепость',
          'ur': 'قلعہ',
        },
      ),
      isFalse,
    );

    expect(
      needsLandmarkAzure(
        sourceLocale: 'ky',
        sourceText: 'Бишкек',
        existing: {'ky': 'Бишкек', 'en': 'Bishkek'},
      ),
      isTrue,
    );

    final previous = landmarkSourceHash('ar', 'قديم');
    expect(
      needsLandmarkAzure(
        sourceLocale: 'ar',
        sourceText: 'جديد',
        existing: {'ar': 'جديد', 'en': 'Old'},
        auto: {
          'sourceHash': previous,
          'values': {'en': 'Old'},
        },
      ),
      isTrue,
    );

    expect(
      needsLandmarkAzure(
        sourceLocale: 'ar',
        sourceText: 'جديد',
        existing: {'ar': 'جديد', 'en': 'Edited by hand'},
        auto: {
          'sourceHash': previous,
          'values': {'en': 'Machine old'},
        },
      ),
      isTrue,
    );
  });

  test('a hand edit is not treated as stale when every app language exists', () {
    final previous = landmarkSourceHash('ar', 'قديم');
    final filled = {
      'ar': 'جديد',
      'en': 'Edited by hand',
      'fr': 'Texte manuel',
      'ky': 'Кол менен',
      'pt': 'Manual',
      'ru': 'Вручную',
      'ur': 'دستی',
    };
    expect(
      needsLandmarkAzure(
        sourceLocale: 'ar',
        sourceText: 'جديد',
        existing: filled,
        auto: {
          'sourceHash': previous,
          'values': {'en': 'Machine old'},
        },
      ),
      isFalse,
    );
  });
}
