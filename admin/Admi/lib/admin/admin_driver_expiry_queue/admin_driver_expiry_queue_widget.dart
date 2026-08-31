import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Dedicated Expiring Soon / Expired driver document queues.
class AdminDriverExpiryQueueWidget extends StatefulWidget {
  const AdminDriverExpiryQueueWidget({
    super.key,
    this.initialBucket = 'expiring_soon',
  });

  /// `expiring_soon` | `expired`
  final String initialBucket;

  static String routeName = 'AdminDriverExpiryQueue';
  static String routePath = '/driverDocExpiry';

  @override
  State<AdminDriverExpiryQueueWidget> createState() =>
      _AdminDriverExpiryQueueWidgetState();
}

class _AdminDriverExpiryQueueWidgetState
    extends State<AdminDriverExpiryQueueWidget> {
  late String _bucket;
  int _rawCount = 0;
  int _renderedCount = 0;
  bool _loading = true;
  String _error = '';
  List<UserRecord> _rows = const [];

  @override
  void initState() {
    super.initState();
    _bucket = widget.initialBucket == 'expired' ? 'expired' : 'expiring_soon';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final country = AdminRoleService.isCountryAgent
          ? AdminOpsFilterState.empty.effectiveCountryRef
          : null;
      Query q;
      if (country != null) {
        q = UserRecord.collection
            .where('ismndob', isEqualTo: true)
            .where('Rev_dolh', isEqualTo: country)
            .where('doc_expiry_bucket', isEqualTo: _bucket)
            .limit(200);
      } else {
        q = UserRecord.collection
            .where('ismndob', isEqualTo: true)
            .where('doc_expiry_bucket', isEqualTo: _bucket)
            .limit(200);
      }
      final snap = await q.get();
      if (!mounted) return;
      setState(() {
        _rawCount = snap.size;
        _rows = snap.docs
            .map((d) => UserRecord.fromSnapshot(d))
            .toList(growable: false);
        _renderedCount = _rows.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _rows = const [];
        _rawCount = 0;
        _renderedCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mismatch = _rawCount != _renderedCount;
    return AdminEditScaffold(
      title: uiTr(context, 'طوابير انتهاء الوثائق'),
      subtitle: uiTr(context, 'Expiring Soon / Expired'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(uiTr(context, 'تنتهي قريبًا')),
                selected: _bucket == 'expiring_soon',
                onSelected: (_) {
                  setState(() => _bucket = 'expiring_soon');
                  _load();
                },
              ),
              ChoiceChip(
                label: Text(uiTr(context, 'منتهية')),
                selected: _bucket == 'expired',
                onSelected: (_) {
                  setState(() => _bucket = 'expired');
                  _load();
                },
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(uiTr(context, 'تحديث')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            identifier: 'qa-driver-expiry-counters',
            label:
                'bucket:$_bucket raw:$_rawCount postFilter:$_rawCount '
                'rendered:$_renderedCount displayed:$_renderedCount '
                'mismatch:${mismatch ? 1 : 0}',
            child: AdminContentCard(
              padding: const EdgeInsets.all(12),
              child: Text(
                'RAW=$_rawCount · POST_FILTER=$_rawCount · '
                'RENDERED=$_renderedCount · DISPLAYED=$_renderedCount'
                '${mismatch ? ' · MISMATCH' : ''}',
                style: theme.labelMedium,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const LinearProgressIndicator(minHeight: 3)
          else if (_error.isNotEmpty)
            Text(_error, style: TextStyle(color: theme.error))
          else if (_rows.isEmpty)
            AdminContentCard(
              child: Text(uiTr(context, 'لا توجد صفوف في هذا الطابور')),
            )
          else
            ..._rows.map((u) => _ExpiryRow(user: u, bucket: _bucket)),
        ],
      ),
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({required this.user, required this.bucket});

  final UserRecord user;
  final String bucket;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final data = user.snapshotData;
    final docType = '${data['doc_expiry_document_type'] ?? ''}'.trim();
    final impact = '${data['doc_expiry_operational_impact'] ?? ''}'.trim();
    final days = data['doc_expiry_days'];
    final expiryRaw = data['doc_expiry_date'];
    DateTime? expiry;
    if (expiryRaw is DateTime) {
      expiry = expiryRaw;
    } else {
      try {
        expiry = (expiryRaw as dynamic)?.toDate() as DateTime?;
      } catch (_) {}
    }
    final review = AdminDriverProfileView.reviewLabel(
      context,
      AdminDriverProfileView.reviewBucket(user),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user.displayName.isEmpty ? user.uid : user.displayName,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
            Text(
              '${uiTr(context, 'الدولة')}: ${AdminDriverProfileView.countryLabel(user)}',
            ),
            Text(
              '${uiTr(context, 'نوع الوثيقة')}: ${docType.isEmpty ? '—' : docType}',
            ),
            Text(
              '${uiTr(context, 'تاريخ الانتهاء')}: '
              '${expiry == null ? '—' : dateTimeFormat('yMMMd', expiry)}',
            ),
            Text(
              bucket == 'expired'
                  ? '${uiTr(context, 'أيام الانتهاء')}: ${days ?? '—'}'
                  : '${uiTr(context, 'الأيام المتبقية')}: ${days ?? '—'}',
            ),
            Text(
              '${uiTr(context, 'الأثر التشغيلي')}: '
              '${impact.isEmpty ? (bucket == 'expired' ? 'blocked' : 'allowed') : impact}',
            ),
            Text('${uiTr(context, 'حالة المراجعة')}: $review'),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () {
                  context.pushNamed(
                    DriverActivationWidget.routeName,
                    queryParameters: {
                      'dre': serializeParam(
                        user.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Text(uiTr(context, 'مراجعة / إجراء')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
