import 'package:flutter/material.dart';

import '/admin/admin_suport/admin_support_stats_loader.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/dashboard_stats_loader.dart';
import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

enum _AlertSeverity { info, warning, critical }

class _AlertCounts {
  const _AlertCounts({
    this.pendingReview = 0,
    this.expiringSoon = 0,
    this.expired = 0,
    this.supportOpen = 0,
    this.activeBookings = 0,
  });

  final int pendingReview;
  final int expiringSoon;
  final int expired;
  final int supportOpen;
  final int activeBookings;

  bool get isEmpty =>
      pendingReview == 0 &&
      expiringSoon == 0 &&
      expired == 0 &&
      supportOpen == 0 &&
      activeBookings == 0;
}

/// Compact dashboard alert strip using existing aggregate loaders only.
class AdminOperationalAlerts extends StatefulWidget {
  const AdminOperationalAlerts({super.key});

  @override
  State<AdminOperationalAlerts> createState() => _AdminOperationalAlertsState();
}

class _AdminOperationalAlertsState extends State<AdminOperationalAlerts> {
  _AlertCounts? _counts;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final countryRef = AdminRoleService.isCountryAgent
          ? AdminRoleService.scopedCountryRef
          : null;
      final driverStats = await DriverAdminStatsLoader.load(
        countryRef: countryRef,
      );
      final supportStats = await AdminSupportStatsLoader.load(
        filters: AdminOpsFilterState(countryRef: countryRef),
      );
      final dash = peekDashboardStats();

      if (!mounted) return;
      setState(() {
        _counts = _AlertCounts(
          pendingReview: driverStats.pendingReview,
          expiringSoon: driverStats.expiringSoon,
          expired: driverStats.expired,
          supportOpen: supportStats.totalOpenish,
          activeBookings: dash?.activeBookings ?? 0,
        );
        _loading = false;
      });
    } catch (e, st) {
      AdminUi.logDiagnostic('dashboard_alerts', e, st);
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<({String label, int count, String route, _AlertSeverity severity})>
  _buildAlerts(BuildContext context) {
    final c = _counts ?? const _AlertCounts();
    final out =
        <({String label, int count, String route, _AlertSeverity severity})>[];
    if (c.pendingReview > 0) {
      out.add((
        label: uiTr(context, 'مراجعات مندوبين معلقة'),
        count: c.pendingReview,
        route: AdmindreverWidget.routeName,
        severity: _AlertSeverity.info,
      ));
    }
    if (c.expiringSoon > 0) {
      out.add((
        label: uiTr(context, 'وثائق قاربت على الانتهاء'),
        count: c.expiringSoon,
        route: AdminDriverExpiryQueueWidget.routeName,
        severity: _AlertSeverity.warning,
      ));
    }
    if (c.expired > 0) {
      out.add((
        label: uiTr(context, 'وثائق منتهية'),
        count: c.expired,
        route: AdminDriverExpiryQueueWidget.routeName,
        severity: _AlertSeverity.critical,
      ));
    }
    if (c.supportOpen > 0) {
      out.add((
        label: uiTr(context, 'تذاكر دعم مفتوحة'),
        count: c.supportOpen,
        route: AdminSuportWidget.routeName,
        severity: _AlertSeverity.info,
      ));
    }
    if (c.activeBookings > 0) {
      out.add((
        label: uiTr(context, 'حجوزات نشطة'),
        count: c.activeBookings,
        route: AdminALLhgZWidget.routeName,
        severity: _AlertSeverity.info,
      ));
    }
    return out;
  }

  Color _color(_AlertSeverity s, FlutterFlowTheme theme) {
    return switch (s) {
      _AlertSeverity.info => AdminUi.brandTeal,
      _AlertSeverity.warning => const Color(0xFFB06A00),
      _AlertSeverity.critical => theme.error,
    };
  }

  AdminBadgeTone _tone(_AlertSeverity s) {
    return switch (s) {
      _AlertSeverity.info => AdminBadgeTone.info,
      _AlertSeverity.warning => AdminBadgeTone.warning,
      _AlertSeverity.critical => AdminBadgeTone.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loading) {
      return AdminContentCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AdminUi.brandTeal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                uiTr(context, 'جاري تحميل التنبيهات…'),
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelMediumIsCustom,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return AdminContentCard(
        child: AdminErrorState(
          title: uiTr(context, 'تعذر تحميل التنبيهات التشغيلية'),
          onRetry: _load,
          compact: true,
        ),
      );
    }

    final alerts = _buildAlerts(context);
    if (alerts.isEmpty) {
      return AdminContentCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.secondaryText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uiTr(context, 'لا توجد تنبيهات تشغيلية'),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            title: uiTr(context, 'تنبيهات تشغيلية'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: uiTr(context, 'تحديث'),
              onPressed: _load,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in alerts)
                InkWell(
                  onTap: () {
                    closeDrawerIfOpen(context);
                    context.goNamed(a.route);
                  },
                  borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _color(
                          a.severity,
                          theme,
                        ).withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminStatusBadge(
                          label: '${a.count}',
                          tone: _tone(a.severity),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          a.label,
                          style: theme.labelMedium.override(
                            fontFamily: theme.labelMediumFamily,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: !theme.labelMediumIsCustom,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: theme.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
