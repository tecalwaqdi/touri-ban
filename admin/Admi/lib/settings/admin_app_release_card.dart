import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminAppReleaseCard extends StatefulWidget {
  const AdminAppReleaseCard({super.key});

  @override
  State<AdminAppReleaseCard> createState() => _AdminAppReleaseCardState();
}

class _ReleaseForm {
  _ReleaseForm({
    required this.id,
    required this.title,
    required this.androidFallback,
    required this.iosFallback,
  });

  final String id;
  final String title;
  final String androidFallback;
  final String iosFallback;
  bool enabled = false;
  bool saving = false;
  final version = TextEditingController();
  final build = TextEditingController();
  final androidUrl = TextEditingController();
  final iosUrl = TextEditingController();

  void dispose() {
    version.dispose();
    build.dispose();
    androidUrl.dispose();
    iosUrl.dispose();
  }
}

class _AdminAppReleaseCardState extends State<AdminAppReleaseCard> {
  late final List<_ReleaseForm> _forms;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _forms = [
      _ReleaseForm(
        id: 'customer',
        title: 'تطبيق العميل',
        androidFallback:
            'https://play.google.com/store/apps/details?id=com.mycompany.araoatanapp',
        iosFallback: 'https://apps.apple.com/app/id6754410562',
      ),
      _ReleaseForm(
        id: 'driver',
        title: 'تطبيق السائق',
        androidFallback:
            'https://play.google.com/store/apps/details?id=com.mycompany.mndob2',
        iosFallback: 'https://apps.apple.com/app/id6754537170',
      ),
    ];
    _load();
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snaps = await Future.wait(
        _forms.map(
          (form) => FirebaseFirestore.instance
              .collection('app_release')
              .doc(form.id)
              .get(),
        ),
      );
      if (!mounted) return;
      for (var i = 0; i < _forms.length; i++) {
        final data = snaps[i].data() ?? const <String, dynamic>{};
        final form = _forms[i];
        form.enabled = data['enabled'] == true;
        form.version.text = '${data['minVersion'] ?? ''}'.trim();
        final build = data['minBuild'];
        form.build.text = build == null ? '' : '$build';
        final android = '${data['androidUrl'] ?? ''}'.trim();
        form.androidUrl.text = android.isEmpty ? form.androidFallback : android;
        final ios = '${data['iosUrl'] ?? ''}'.trim();
        form.iosUrl.text = ios.isEmpty ? form.iosFallback : ios;
      }
    } catch (e, st) {
      AdminUi.logDiagnostic('app_release_load', e, st);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(_ReleaseForm form) async {
    final build = int.tryParse(form.build.text.trim()) ?? 0;
    if (form.enabled && build <= 0) {
      AdminCrudFeedback.error(
        context,
        uiTr(context, 'اكتب رقم البناء المطلوب قبل التفعيل'),
      );
      return;
    }
    setState(() => form.saving = true);
    try {
      await FirebaseFirestore.instance.collection('app_release').doc(form.id).set(
        {
          'enabled': form.enabled,
          'minBuild': build,
          'minVersion': form.version.text.trim(),
          'androidUrl': form.androidUrl.text.trim(),
          'iosUrl': form.iosUrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم حفظ إشعار التحديث'))),
      );
    } catch (e, st) {
      AdminUi.logDiagnostic('app_release_save', e, st);
      if (mounted) {
        AdminCrudFeedback.error(context, uiTr(context, 'تعذر حفظ إشعار التحديث'));
      }
    } finally {
      if (mounted) setState(() => form.saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminRoleService.isSuperAdmin) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return AdminContentCard(
      title: uiTr(context, 'إشعار التحديث الإجباري'),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uiTr(
                    context,
                    'بعد نشر نسخة في المتجر، اكتب رقم بنائها وفعّل الإشعار. أي نسخة أقدم تتوقف حتى يضغط المستخدم تحديث الآن.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final form in _forms) ...[
                  const SizedBox(height: 8),
                  Text(
                    uiTr(context, form.title),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(uiTr(context, 'تفعيل الإشعار')),
                    value: form.enabled,
                    onChanged: (value) => setState(() => form.enabled = value),
                  ),
                  AdminTextField(
                    controller: form.version,
                    label: uiTr(context, 'الإصدار الظاهر'),
                    hint: '9.1.46',
                    icon: Icons.sell_outlined,
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminTextField(
                    controller: form.build,
                    label: uiTr(context, 'رقم البناء المطلوب'),
                    hint: '68',
                    icon: Icons.tag,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminTextField(
                    controller: form.androidUrl,
                    label: uiTr(context, 'رابط Google Play'),
                    icon: Icons.shop_outlined,
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminTextField(
                    controller: form.iosUrl,
                    label: uiTr(context, 'رابط App Store'),
                    hint: 'https://apps.apple.com/app/id…',
                    icon: Icons.phone_iphone,
                  ),
                  const SizedBox(height: 12),
                  AdminPrimaryButton(
                    label: uiTr(context, 'حفظ'),
                    icon: Icons.save_outlined,
                    isLoading: form.saving,
                    onPressed: form.saving ? null : () => _save(form),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}
