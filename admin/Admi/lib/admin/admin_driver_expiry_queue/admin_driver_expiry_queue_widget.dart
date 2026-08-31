import 'package:flutter/material.dart';

import '/admin/admindrever/admin_driver_expiry_adapter.dart';
import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_document_access.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Document expiry queue for drivers (`doc_expiry_bucket` SoT).
class AdminDriverExpiryQueueWidget extends StatefulWidget {
  const AdminDriverExpiryQueueWidget({
    super.key,
    this.initialBucket = 'expiring_soon',
  });

  final String initialBucket;

  static String routeName = 'AdminDriverExpiryQueue';
  static String routePath = '/driverDocExpiry';

  @override
  State<AdminDriverExpiryQueueWidget> createState() =>
      _AdminDriverExpiryQueueWidgetState();
}

class _AdminDriverExpiryQueueWidgetState
    extends State<AdminDriverExpiryQueueWidget> {
  bool _loading = true;
  String _error = '';
  List<AdminDriverExpiryRow> _expired = const [];
  List<AdminDriverExpiryRow> _expiringSoon = const [];
  String _search = '';
  String _docTypeFilter = '';
  String _statusFilter = 'all';
  String _windowFilter = 'all';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AdminDriverExpiryRow>> _queryBucket(String bucket) async {
    final country = AdminRoleService.isCountryAgent
        ? AdminOpsFilterState.empty.effectiveCountryRef
        : null;
    Query q;
    if (country != null) {
      q = UserRecord.collection
          .where('ismndob', isEqualTo: true)
          .where('Rev_dolh', isEqualTo: country)
          .where('doc_expiry_bucket', isEqualTo: bucket)
          .limit(200);
    } else {
      q = UserRecord.collection
          .where('ismndob', isEqualTo: true)
          .where('doc_expiry_bucket', isEqualTo: bucket)
          .limit(200);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => AdminDriverExpiryRow.fromUser(
              UserRecord.fromSnapshot(d),
              bucket: bucket,
            ))
        .toList(growable: false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        _queryBucket('expired'),
        _queryBucket('expiring_soon'),
      ]);
      if (!mounted) return;
      setState(() {
        _expired = results[0];
        _expiringSoon = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _expired = const [];
        _expiringSoon = const [];
      });
    }
  }

  List<AdminDriverExpiryRow> get _all => [..._expired, ..._expiringSoon];

  List<AdminDriverExpiryRow> get _filtered {
    var rows = _all;
    if (_statusFilter == 'expired') {
      rows = rows
          .where((r) => r.status == AdminDriverExpiryDisplayStatus.expired)
          .toList();
    } else if (_statusFilter == 'expiring_soon') {
      rows = rows
          .where((r) => r.status == AdminDriverExpiryDisplayStatus.expiringSoon)
          .toList();
    } else if (_statusFilter == 'valid') {
      rows = rows
          .where((r) => r.status == AdminDriverExpiryDisplayStatus.valid)
          .toList();
    } else if (_statusFilter == 'unknown') {
      rows = rows
          .where((r) => r.status == AdminDriverExpiryDisplayStatus.unknown)
          .toList();
    }

    if (_docTypeFilter.isNotEmpty) {
      rows = rows
          .where((r) => r.documentTypeRaw == _docTypeFilter)
          .toList();
    }

    if (_windowFilter != 'all') {
      final maxDays = switch (_windowFilter) {
        '7' => 7,
        '30' => 30,
        '60' => 60,
        _ => null,
      };
      if (maxDays != null) {
        rows = rows.where((r) {
          final e = r.expiryDate;
          if (e == null) return false;
          final d = e.difference(DateTime.now()).inDays;
          return d >= 0 && d <= maxDays;
        }).toList();
      }
    }

    final q = _search.trim();
    if (q.isNotEmpty) {
      rows = rows.where((r) => r.matchesSearch(q)).toList();
    }
    return rows;
  }

  int _countStatus(AdminDriverExpiryDisplayStatus s) =>
      _all.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final filtered = _filtered;

    return AdminDriverModuleScaffold(
      title: uiTr(context, 'انتهاء وثائق المناديب'),
      subtitle: uiTr(
        context,
        'متابعة الوثائق المنتهية أو التي اقترب موعد انتهائها.',
      ),
      isLoading: _loading,
      body: _loading
          ? const SizedBox.shrink()
          : ListView(
              padding: AdminUi.pagePadding(context).copyWith(top: 12, bottom: 24),
              children: [
                _SummaryStrip(
                  expired: _countStatus(AdminDriverExpiryDisplayStatus.expired),
                  expiringSoon:
                      _countStatus(AdminDriverExpiryDisplayStatus.expiringSoon),
                  valid: _countStatus(AdminDriverExpiryDisplayStatus.valid),
                  unknown:
                      _countStatus(AdminDriverExpiryDisplayStatus.unknown),
                ),
                const SizedBox(height: 12),
                _FilterBar(
                  searchController: _searchController,
                  docTypeFilter: _docTypeFilter,
                  statusFilter: _statusFilter,
                  windowFilter: _windowFilter,
                  onSearchChanged: (v) => setState(() => _search = v),
                  onDocTypeChanged: (v) =>
                      setState(() => _docTypeFilter = v ?? ''),
                  onStatusChanged: (v) =>
                      setState(() => _statusFilter = v ?? 'all'),
                  onWindowChanged: (v) =>
                      setState(() => _windowFilter = v ?? 'all'),
                  onRefresh: _load,
                ),
                const SizedBox(height: 10),
                if (_error.isNotEmpty)
                  Text(_error, style: TextStyle(color: theme.error))
                else if (filtered.isEmpty)
                  AdminContentCard(
                    child: Text(uiTr(context, 'لا توجد صفوف مطابقة')),
                  )
                else
                  Semantics(
                    identifier: 'qa-driver-expiry-table',
                    label: 'rows:${filtered.length}',
                    child: _ExpiryTable(rows: filtered),
                  ),
              ],
            ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.expired,
    required this.expiringSoon,
    required this.valid,
    required this.unknown,
  });

  final int expired;
  final int expiringSoon;
  final int valid;
  final int unknown;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget chip(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.labelSmall),
            const SizedBox(width: 6),
            Text(
              value,
              style: theme.labelLarge.override(
                fontFamily: theme.labelLargeFamily,
                fontWeight: FontWeight.w800,
                color: color,
                useGoogleFonts: !theme.labelLargeIsCustom,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(uiTr(context, 'منتهية'), '$expired', Colors.red.shade700),
        chip(
          uiTr(context, 'تنتهي قريبًا'),
          '$expiringSoon',
          Colors.deepOrange.shade700,
        ),
        chip(uiTr(context, 'سارية'), '$valid', Colors.green.shade700),
        chip(uiTr(context, 'غير محدد'), '$unknown', theme.secondaryText),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.docTypeFilter,
    required this.statusFilter,
    required this.windowFilter,
    required this.onSearchChanged,
    required this.onDocTypeChanged,
    required this.onStatusChanged,
    required this.onWindowChanged,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final String docTypeFilter;
  final String statusFilter;
  final String windowFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDocTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onWindowChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AdminUi.cardDecoration(context),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: uiTr(context, 'بحث بالمندوب'),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          _dropdown<String?>(
            context,
            value: docTypeFilter.isEmpty ? null : docTypeFilter,
            hint: uiTr(context, 'نوع الوثيقة'),
            items: {
              null: uiTr(context, 'الكل'),
              'national_id': uiTr(context, 'الهوية'),
              'driver_license': uiTr(context, 'رخصة القيادة'),
              'vehicle_registration': uiTr(context, 'استمارة المركبة'),
            },
            onChanged: (v) => onDocTypeChanged(v ?? ''),
          ),
          _dropdown<String?>(
            context,
            value: statusFilter,
            hint: uiTr(context, 'الحالة'),
            items: {
              'all': uiTr(context, 'الكل'),
              'expired': uiTr(context, 'منتهية'),
              'expiring_soon': uiTr(context, 'تنتهي قريبًا'),
              'valid': uiTr(context, 'سارية'),
              'unknown': uiTr(context, 'غير محدد'),
            },
            onChanged: (v) => onStatusChanged(v ?? 'all'),
          ),
          _dropdown<String?>(
            context,
            value: windowFilter,
            hint: uiTr(context, 'النافذة'),
            items: {
              'all': uiTr(context, 'الكل'),
              '7': uiTr(context, 'خلال 7 أيام'),
              '30': uiTr(context, 'خلال 30 يومًا'),
              '60': uiTr(context, 'خلال 60 يومًا'),
            },
            onChanged: (v) => onWindowChanged(v ?? 'all'),
          ),
          IconButton(
            tooltip: uiTr(context, 'تحديث'),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    BuildContext context, {
    required T? value,
    required String hint,
    required Map<T?, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<T?>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(isDense: true, labelText: hint),
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T?>(
                value: e.key,
                child: Text(e.value),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ExpiryTable extends StatelessWidget {
  const _ExpiryTable({required this.rows});
  final List<AdminDriverExpiryRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (!wide) {
      return Column(
        children: rows.map((r) => _ExpiryCard(row: r)).toList(),
      );
    }

    return Container(
      decoration: AdminUi.cardDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(uiTr(context, 'المندوب'), style: _hdr(theme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(uiTr(context, 'نوع الوثيقة'), style: _hdr(theme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(uiTr(context, 'تاريخ الانتهاء'), style: _hdr(theme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(uiTr(context, 'الأيام'), style: _hdr(theme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(uiTr(context, 'الحالة'), style: _hdr(theme)),
                ),
                SizedBox(
                  width: 96,
                  child: Text(uiTr(context, 'الإجراءات'), style: _hdr(theme)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.alternate.withValues(alpha: 0.5)),
          for (final row in rows) _ExpiryDataRow(row: row),
        ],
      ),
    );
  }

  TextStyle _hdr(FlutterFlowTheme theme) => theme.labelMedium.override(
        fontFamily: theme.labelMediumFamily,
        fontWeight: FontWeight.w700,
        color: theme.secondaryText,
        useGoogleFonts: !theme.labelMediumIsCustom,
      );
}

class _ExpiryDataRow extends StatelessWidget {
  const _ExpiryDataRow({required this.row});
  final AdminDriverExpiryRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final expiryStr = row.expiryDate == null
        ? uiTr(context, 'غير محدد')
        : dateTimeFormat('yMMMd', row.expiryDate!);

    AdminStatusKind kind;
    switch (row.status) {
      case AdminDriverExpiryDisplayStatus.expired:
        kind = AdminStatusKind.inactive;
      case AdminDriverExpiryDisplayStatus.expiringSoon:
        kind = AdminStatusKind.medium;
      case AdminDriverExpiryDisplayStatus.valid:
        kind = AdminStatusKind.active;
      case AdminDriverExpiryDisplayStatus.unknown:
        kind = AdminStatusKind.unknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: _DriverCell(row: row.driverRow)),
          Expanded(
            flex: 2,
            child: Text(
              AdminDriverExpiryRow.documentTypeLabel(
                context,
                row.documentTypeRaw,
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(expiryStr)),
          Expanded(
            flex: 2,
            child: Text(AdminDriverExpiryRow.daysDisplay(context, row)),
          ),
          Expanded(
            flex: 2,
            child: AdminStatusBadgeUnified(
              kind: kind,
              label: AdminDriverExpiryRow.statusLabel(context, row.status),
            ),
          ),
          SizedBox(
            width: 96,
            child: _ExpiryActions(row: row),
          ),
        ],
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.row});
  final AdminDriverExpiryRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DriverCell(row: row.driverRow),
            const SizedBox(height: 8),
            AdminDriverKvRow(
              label: uiTr(context, 'نوع الوثيقة'),
              value: AdminDriverExpiryRow.documentTypeLabel(
                context,
                row.documentTypeRaw,
              ),
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'تاريخ الانتهاء'),
              value: row.expiryDate == null
                  ? uiTr(context, 'غير محدد')
                  : dateTimeFormat('yMMMd', row.expiryDate!),
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'الأيام'),
              value: AdminDriverExpiryRow.daysDisplay(context, row),
            ),
            const SizedBox(height: 6),
            _ExpiryActions(row: row),
          ],
        ),
      ),
    );
  }
}

class _DriverCell extends StatelessWidget {
  const _DriverCell({required this.row});
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        AdminDriverAvatar(
          photoUrl: row.photoUrl,
          displayName: row.displayName,
          size: 36,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
              Text(
                row.phone,
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpiryActions extends StatelessWidget {
  const _ExpiryActions({required this.row});
  final AdminDriverExpiryRow row;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: uiTr(context, 'إجراءات'),
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (v) {
        switch (v) {
          case 'profile':
            context.pushNamed(
              DriverProfileWidget.routeName,
              queryParameters: {
                'iduser': serializeParam(
                  row.user.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            );
          case 'doc':
            _previewDocument(context);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'profile',
          child: Text(uiTr(context, 'عرض المندوب')),
        ),
        PopupMenuItem(
          value: 'doc',
          enabled: row.documentSlot?.canView == true,
          child: Text(uiTr(context, 'عرض الوثيقة')),
        ),
      ],
    );
  }

  Future<void> _previewDocument(BuildContext context) async {
    final slot = row.documentSlot;
    if (slot == null || !slot.canView) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );

    final result = await AdminDriverDocumentAccess.resolveView(
      driver: row.user,
      storagePath: slot.storagePath,
      legacyHttpsUrl: slot.legacyUrl,
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.userMessageAr)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AdminDriverProfileView.docKindLabel(ctx, slot.kind),
        ),
        content: SizedBox(
          width: 420,
          child: result.bytes != null && result.bytes!.isNotEmpty
              ? Image.memory(result.bytes!, fit: BoxFit.contain)
              : Text(uiTr(ctx, 'تم فتح الوثيقة')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(uiTr(ctx, 'إغلاق')),
          ),
        ],
      ),
    );
  }
}
