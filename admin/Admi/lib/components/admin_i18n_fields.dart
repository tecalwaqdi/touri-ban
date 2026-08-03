import 'package:flutter/material.dart';

import '/components/admin_edit_shell.dart';
import '/components/admin_ui.dart';
import '/core/admin_content_locale.dart';
import '/core/i18n/admin_i18n_translate_service.dart';
import '/core/i18n/toury_i18n_locales.dart';
import '/core/i18n/toury_i18n_text.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// متحكم حقول نص متعدد اللغات.
class AdminI18nFieldsController {
  AdminI18nFieldsController({String? primaryLocale}) {
    final primary = primaryLocale ?? 'ar';
    for (final key in touryI18nLocaleKeys) {
      controllers[key] = TextEditingController();
    }
    selectedLocale = touryI18nLocaleKeys.contains(primary)
        ? primary
        : touryI18nLocaleKeys.first;
  }

  final Map<String, TextEditingController> controllers = {};
  late String selectedLocale;

  TextEditingController get activeController =>
      controllers[selectedLocale]!;

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  Map<String, String> toMap() {
    final out = <String, String>{};
    controllers.forEach((key, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) out[key] = text;
    });
    return out;
  }

  void setFromMap(Map<String, String> values) {
    for (final key in touryI18nLocaleKeys) {
      controllers[key]?.text = values[key] ?? '';
    }
  }

  void syncPrimary(String localeKey, String text) {
    if (controllers.containsKey(localeKey)) {
      controllers[localeKey]!.text = text;
    }
  }

  String get primaryValue => activeController.text.trim();
}

/// قسم إدخال نص بلغات متعددة + زر ترجمة تلقائية.
class AdminI18nFieldsSection extends StatefulWidget {
  const AdminI18nFieldsSection({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    this.legacyController,
    this.minLines = 1,
    this.maxLines = 3,
  });

  final String title;
  final String hint;
  final AdminI18nFieldsController controller;
  final TextEditingController? legacyController;
  final int minLines;
  final int maxLines;

  @override
  State<AdminI18nFieldsSection> createState() => _AdminI18nFieldsSectionState();
}

class _AdminI18nFieldsSectionState extends State<AdminI18nFieldsSection> {
  bool _expanded = false;
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    widget.legacyController?.addListener(_syncFromLegacy);
  }

  @override
  void dispose() {
    widget.legacyController?.removeListener(_syncFromLegacy);
    super.dispose();
  }

  void _syncFromLegacy() {
    final legacy = widget.legacyController;
    if (legacy == null) return;
    final key = adminContentLocaleKey(context);
    widget.controller.syncPrimary(key, legacy.text);
    widget.controller.selectedLocale = key;
  }

  Future<void> _autoTranslate() async {
    final sourceLocale = adminContentLocaleKey(context);
    final sourceText = widget.legacyController?.text.trim().isNotEmpty == true
        ? widget.legacyController!.text.trim()
        : widget.controller.controllers[sourceLocale]?.text.trim() ?? '';

    if (sourceText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'أدخل النص أولاً ثم اضغط ترجم'))),
      );
      return;
    }

    setState(() => _translating = true);
    try {
      final translated = await AdminI18nTranslateService.translateText(
        context: context,
        sourceLocale: sourceLocale,
        sourceText: sourceText,
        fieldLabel: widget.title,
      );
      if (!mounted) return;
      if (translated == null || translated.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'فشلت الترجمة التلقائية'))),
        );
        return;
      }
      widget.controller.setFromMap(translated);
      final legacy = touryPrimaryLegacyText(translated, sourceText);
      widget.legacyController?.text = legacy;
      setState(() => _expanded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تمت الترجمة لجميع اللغات'))),
      );
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceLocale = adminContentLocaleKey(context);

    return AdminEditFormCard(
      sectionTitle: widget.title,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _translating ? null : _autoTranslate,
                icon: _translating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate_rounded),
                label: Text(uiTr(context, 'ترجم تلقائياً لجميع اللغات')),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: uiTr(context, 'عرض جميع اللغات'),
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.language_rounded,
              ),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: touryI18nLocaleKeys.map((key) {
              final selected = widget.controller.selectedLocale == key;
              return ChoiceChip(
                label: Text(touryI18nLabel(key)),
                selected: selected,
                onSelected: (_) {
                  setState(() => widget.controller.selectedLocale = key);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller.activeController,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            onChanged: (v) {
              if (keyMatches(sourceLocale, widget.controller.selectedLocale)) {
                widget.legacyController?.text = v;
              }
            },
            decoration: InputDecoration(
              labelText:
                  '${widget.hint} (${touryI18nLabel(widget.controller.selectedLocale)})',
              hintText: widget.hint,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              uiTr(context,
                  'اضغط «ترجم تلقائياً» أو أيقونة اللغات لإدخال/مراجعة كل اللغات'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  bool keyMatches(String a, String b) => a == b;
}
