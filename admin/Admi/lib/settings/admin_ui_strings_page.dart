import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminUiStringsPage extends StatefulWidget {
  const AdminUiStringsPage({super.key});

  @override
  State<AdminUiStringsPage> createState() => _AdminUiStringsPageState();
}

class _AdminUiStringsPageState extends State<AdminUiStringsPage> {
  static const _apps = ['customer', 'driver'];
  static const _locales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];

  String _app = 'customer';
  String _locale = 'ar';
  String _query = '';
  bool _loading = true;
  Map<String, String> _bundled = const {};
  Map<String, String> _remote = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await rootBundle.loadString(
        'assets/mobile_langs/$_app/$_locale.json',
      );
      final decoded = jsonDecode(raw);
      final bundled = <String, String>{};
      if (decoded is Map) {
        decoded.forEach((key, value) {
          final text = value?.toString() ?? '';
          if (text.isNotEmpty) bundled[key.toString()] = text;
        });
      }
      final snap = await FirebaseFirestore.instance
          .collection('app_ui_i18n')
          .doc('${_app}_$_locale')
          .get();
      final remote = <String, String>{};
      final strings = snap.data()?['strings'];
      if (strings is Map) {
        strings.forEach((key, value) {
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) remote[key.toString()] = text;
        });
      }
      if (!mounted) return;
      setState(() {
        _bundled = bundled;
        _remote = remote;
        _loading = false;
      });
    } catch (e, st) {
      AdminUi.logDiagnostic('ui_strings_load', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String key, String value) async {
    final bundled = _bundled[key] ?? '';
    final next = value.trim();
    final ref =
        FirebaseFirestore.instance.collection('app_ui_i18n').doc('${_app}_$_locale');
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = <String, String>{};
      final strings = snap.data()?['strings'];
      if (strings is Map) {
        strings.forEach((rawKey, rawValue) {
          final text = rawValue?.toString().trim() ?? '';
          if (text.isNotEmpty) current[rawKey.toString()] = text;
        });
      }
      if (next.isEmpty || next == bundled) {
        current.remove(key);
      } else {
        current[key] = next;
      }
      tx.set(ref, {
        'app': _app,
        'locale': _locale,
        'strings': current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if (!mounted) return;
    setState(() {
      final updated = Map<String, String>.from(_remote);
      if (next.isEmpty || next == bundled) {
        updated.remove(key);
      } else {
        updated[key] = next;
      }
      _remote = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uiTr(context, 'تم الحفظ. يصل التعديل للتطبيق بدون نسخة متجر جديدة.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = <String>[];
    if (!_loading) {
      for (final key in _bundled.keys) {
        if (matches.length >= 40) break;
        final bundled = _bundled[key] ?? '';
        final remote = _remote[key] ?? '';
        final haystack = '$key $bundled $remote'.toLowerCase();
        if (query.isEmpty || haystack.contains(query)) {
          matches.add(key);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(uiTr(context, 'ترجمات التطبيقات')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              uiTr(
                context,
                'عدّل النص ثم احفظ. تطبيق العميل وتطبيق السائق يأخذان التعديل عند الفتح التالي، بدون تحديث من المتجر.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('ui-app-$_app'),
              initialValue: _app,
              decoration: InputDecoration(
                labelText: uiTr(context, 'التطبيق'),
              ),
              items: [
                for (final app in _apps)
                  DropdownMenuItem(
                    value: app,
                    child: Text(
                      app == 'customer'
                          ? uiTr(context, 'تطبيق العميل')
                          : uiTr(context, 'تطبيق السائق'),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null || value == _app) return;
                setState(() => _app = value);
                _load();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('ui-locale-$_locale'),
              initialValue: _locale,
              decoration: InputDecoration(
                labelText: uiTr(context, 'اللغة'),
              ),
              items: [
                for (final code in _locales)
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (value) {
                if (value == null || value == _locale) return;
                setState(() => _locale = value);
                _load();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: uiTr(context, 'بحث'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (!AdminRoleService.isSuperAdmin)
              Text(uiTr(context, 'الحفظ متاح لسوبر أدمن فقط.'))
            else ...[
              Text(
                uiTr(context, 'أول 40 نتيجة. ابحث لتضييق القائمة.'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final key in matches)
                _PhraseEditor(
                  phraseKey: key,
                  bundled: _bundled[key] ?? '',
                  remote: _remote[key],
                  onSave: (value) => _save(key, value),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhraseEditor extends StatefulWidget {
  const _PhraseEditor({
    required this.phraseKey,
    required this.bundled,
    required this.remote,
    required this.onSave,
  });

  final String phraseKey;
  final String bundled;
  final String? remote;
  final Future<void> Function(String value) onSave;

  @override
  State<_PhraseEditor> createState() => _PhraseEditorState();
}

class _PhraseEditorState extends State<_PhraseEditor> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.remote ?? widget.bundled);
  }

  @override
  void didUpdateWidget(covariant _PhraseEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.remote ?? widget.bundled;
    if (oldWidget.phraseKey != widget.phraseKey ||
        (oldWidget.remote != widget.remote && _controller.text != next)) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overridden =
        widget.remote != null && widget.remote != widget.bundled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.phraseKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
          if (overridden)
            Text(
              uiTr(context, 'معدّل على السيرفر'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AdminPrimaryButton(
              label: uiTr(context, 'حفظ'),
              icon: Icons.save_outlined,
              isLoading: _saving,
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await widget.onSave(_controller.text);
                      } catch (e, st) {
                        AdminUi.logDiagnostic('ui_strings_save', e, st);
                        if (context.mounted) {
                          AdminCrudFeedback.error(
                            context,
                            uiTr(context, 'تعذر حفظ الترجمة'),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
