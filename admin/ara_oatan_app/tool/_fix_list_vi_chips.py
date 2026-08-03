# -*- coding: utf-8 -*-
from pathlib import Path

p = Path('lib/app/list_vi/list_vi_widget.dart')
t = p.read_text(encoding='utf-8')

if "toury_landmark_filter" not in t:
    t = t.replace(
        "import '/core/toury_mkan_i18n.dart';",
        "import '/core/toury_mkan_i18n.dart';\n"
        "import '/core/toury_landmark_filter.dart';\n"
        "import '/core/toury_landmark_categories.dart';",
    )

t = t.replace('"معالم دينية"', "'landmark_cat_religious'.tr()")
t = t.replace('"معالم تاريخية"', "'landmark_cat_historical'.tr()")

# Filter by storage category after chip selection
old_filter = """final listViewMkanRecordList =
                                                                listViMkanRecordList
                                                                    .where((r) =>
                                                                        r.tsnef ==
                                                                        category)
                                                                    .toList();"""
new_filter = """final storageCategory =
                                                                TouryLandmarkCategories
                                                                    .toStorage(category);
                                                            final listViewMkanRecordList =
                                                                touryFilterLandmarksForUi(
                                                              listViMkanRecordList.where((r) =>
                                                                  TouryLandmarkCategories.isAll(category) ||
                                                                  r.tsnef == storageCategory ||
                                                                  r.tsnef == category),
                                                              touryContentLocaleFromContext(context),
                                                            );"""

if old_filter in t:
    t = t.replace(old_filter, new_filter)
    print('filter patched')
else:
    print('filter pattern not found')

# Ads carousel filter
old_ads = """final listViewMkanRecordList =
                                                                listViMkanRecordList
                                                                    .where((r) =>
                                                                        r.asAds)
                                                                    .toList();"""
new_ads = """final listViewMkanRecordList =
                                                                touryFilterLandmarksForUi(
                                                              listViMkanRecordList.where((r) => r.asAds),
                                                              touryContentLocaleFromContext(context),
                                                            );"""
if old_ads in t:
    t = t.replace(old_ads, new_ads)
    print('ads filter patched')

# All-chip check
t = t.replace(
    "(_model.choiceChipsValue ==\n                                                            'filter_all'.tr())",
    "(TouryLandmarkCategories.isAll(_model.choiceChipsValue))",
)

p.write_text(t, encoding='utf-8')
print('religious left', 'معالم دينية' in t)
print('done')
