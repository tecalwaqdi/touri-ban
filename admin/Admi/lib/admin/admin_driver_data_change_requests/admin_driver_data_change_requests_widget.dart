import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Admin queue for approved-driver profile data-change requests.
class AdminDriverDataChangeRequestsWidget extends StatefulWidget {
  const AdminDriverDataChangeRequestsWidget({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static const String routeName = 'AdminDriverDataChangeRequests';
  static const String routePath = '/adminDriverDataChangeRequests';

  @override
  State<AdminDriverDataChangeRequestsWidget> createState() =>
      _AdminDriverDataChangeRequestsWidgetState();
}

class _AdminDriverDataChangeRequestsWidgetState
    extends State<AdminDriverDataChangeRequestsWidget> {
  late Menu2Model _menu2Model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>>? _queryOrNull() {
    if (!AdminRoleService.isSuperAdmin && !AdminRoleService.isCountryAgent) {
      return null;
    }
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('driver_data_change_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .limit(100);
    return q;
  }

  Future<void> _review({
    required String requestId,
    required String decision,
  }) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          uiTr(
            ctx,
            decision == 'approve' ? 'الموافقة على الطلب' : 'رفض الطلب',
          ),
        ),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: uiTr(ctx, 'ملاحظة (اختياري)'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(uiTr(ctx, 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              uiTr(ctx, decision == 'approve' ? 'موافقة' : 'رفض'),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result =
          await CloudFunctionsClient.reviewDriverProfileChangeRequest(
        requestId: requestId,
        decision: decision,
        reason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      final success = result['ok'] == true || result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(
              context,
              success
                  ? (decision == 'approve'
                      ? 'تمت الموافقة وتطبيق التعديلات'
                      : 'تم رفض الطلب')
                  : 'تعذر إتمام المراجعة',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تعذر إتمام المراجعة'))),
      );
    } finally {
      reasonCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> data, String id) async {
    final proposed = Map<String, dynamic>.from(
      (data['proposedValues'] as Map?) ??
          (data['requestedFields'] as Map?) ??
          const {},
    );
    final current = Map<String, dynamic>.from(
      (data['currentSnapshot'] as Map?) ?? const {},
    );
    final docs = Map<String, dynamic>.from(
      (data['documentUploads'] as Map?) ?? const {},
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = FlutterFlowTheme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    uiTr(ctx, 'تفاصيل طلب التعديل'),
                    style: theme.titleMedium.override(
                      fontFamily: theme.titleMediumFamily,
                      fontWeight: FontWeight.w800,
                      useGoogleFonts: !theme.titleMediumIsCustom,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data['driverDisplayName'] ?? ''} · ${data['driverPhone'] ?? ''}',
                    style: theme.bodyMedium,
                  ),
                  Text(
                    'UID: ${data['driverUid'] ?? ''}',
                    style: theme.bodySmall,
                  ),
                  if ((data['reason'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${uiTr(ctx, 'السبب')}: ${data['reason']}',
                      style: theme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    uiTr(ctx, 'القيم المقترحة'),
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final e in proposed.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              fontWeight: FontWeight.w700,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                          Text(
                            '${uiTr(ctx, 'الحالي')}: ${current[e.key] ?? '—'}',
                            style: theme.bodySmall,
                          ),
                          Text(
                            '${uiTr(ctx, 'الجديد')}: ${e.value}',
                            style: theme.bodyMedium,
                          ),
                          if (_looksLikeUrl(e.value.toString()))
                            TextButton(
                              onPressed: () => _openUrl(e.value.toString()),
                              child: Text(uiTr(ctx, 'فتح المرفق')),
                            ),
                        ],
                      ),
                    ),
                  if (docs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      uiTr(ctx, 'المرفقات'),
                      style: theme.titleSmall,
                    ),
                    for (final e in docs.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.key),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () {
                            final m = e.value;
                            final url = m is Map
                                ? (m['url'] ?? m['previewUrl'] ?? '').toString()
                                : '';
                            if (url.isNotEmpty) _openUrl(url);
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _review(
                                    requestId: id,
                                    decision: 'reject',
                                  );
                                },
                          child: Text(uiTr(ctx, 'رفض')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _review(
                                    requestId: id,
                                    decision: 'approve',
                                  );
                                },
                          child: Text(uiTr(ctx, 'موافقة وتطبيق')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _looksLikeUrl(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _body() {
    final q = _queryOrNull();
    if (q == null) {
      return Center(
        child: Text(uiTr(context, 'ليس لديك صلاحية لعرض هذه الطلبات')),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                uiTr(
                  context,
                  'تعذر تحميل الطلبات. قد تحتاج فهرس Firestore.',
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs.where((doc) {
          if (!AdminRoleService.isCountryAgent) return true;
          final country = AdminRoleService.scopedCountryRef;
          if (country == null) return false;
          final ref = doc.data()['countryRef'];
          if (ref is DocumentReference) return ref.path == country.path;
          return false;
        }).toList();
        if (docs.isEmpty) {
          return Center(
            child: Text(uiTr(context, 'لا توجد طلبات تعديل معلّقة')),
          );
        }
        return ListView.separated(
          padding: AdminUi.pagePadding(context),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            final name =
                (d['driverDisplayName'] ?? d['driverUid'] ?? '').toString();
            final sections = (d['sections'] is List)
                ? (d['sections'] as List).join(', ')
                : '';
            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text(
                  [
                    if (sections.isNotEmpty) sections,
                    if ((d['reason'] ?? '').toString().isNotEmpty)
                      d['reason'].toString(),
                  ].join('\n'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : () => _openDetail(d, doc.id),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          Padding(
            padding: AdminUi.pagePadding(context).copyWith(bottom: 8),
            child: AdminPageHeader(
              title: uiTr(context, 'طلبات تعديل بيانات السائقين'),
              subtitle: uiTr(
                context,
                'مراجعة طلبات السائقين المعتمدين لتحديث الهوية أو المركبة أو الوثائق.',
              ),
            ),
          ),
        Expanded(child: _body()),
      ],
    );

    if (widget.embedded) return content;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: uiTr(context, 'طلبات تعديل بيانات السائقين'),
      child: content,
    );
  }
}
