import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/i18n/admin_geo_names.dart';

void ensureAdminGeoControllers(Map<String, TextEditingController> controllers) {
  for (final lang in adminGeoLocales) {
    controllers.putIfAbsent(lang, TextEditingController.new);
  }
}

void disposeAdminGeoControllers(Map<String, TextEditingController> controllers) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
}

Map<String, String> adminGeoControllerValues(
  Map<String, TextEditingController> controllers,
) {
  return {
    for (final lang in adminGeoLocales)
      if ((controllers[lang]?.text.trim() ?? '').isNotEmpty)
        lang: controllers[lang]!.text.trim(),
  };
}

class AdminGeoLocaleFields extends StatelessWidget {
  const AdminGeoLocaleFields({super.key, required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final lang in adminGeoLocales)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminUi.fieldGap),
            child: AdminTextField(
              controller: controllers[lang]!,
              label: 'names_i18n.$lang',
              icon: Icons.translate_rounded,
            ),
          ),
      ],
    );
  }
}
