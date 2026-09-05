import 'package:flutter/widgets.dart';

import '/backend/backend.dart';
import '/core/i18n/toury_i18n_text.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Localized display label for `type_car` using existing [names_i18n] + [naim].
/// Does not mutate stored Firestore values — presentation only.
abstract final class AdminTypeCarLabel {
  AdminTypeCarLabel._();

  static String localeKeyOf(BuildContext context) {
    try {
      return FFLocalizations.of(context).languageCode.split('_').first;
    } catch (_) {
      return Localizations.localeOf(context).languageCode;
    }
  }

  static String fromRecord(TypeCarRecord type, BuildContext context) {
    return touryLocalizedText(
      type.namesI18n,
      type.naim,
      localeKey: localeKeyOf(context),
    );
  }

  /// Prefer live type_car i18n when a ref is available; else keep [legacy].
  static Future<String> resolve({
    required BuildContext context,
    DocumentReference? typeCarRef,
    String legacy = '',
  }) async {
    if (typeCarRef != null) {
      try {
        final type = await TypeCarRecord.getDocumentOnce(typeCarRef);
        final label = fromRecord(type, context).trim();
        if (label.isNotEmpty) return label;
      } catch (_) {}
    }
    return legacy.trim();
  }
}
