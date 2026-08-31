import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/admin/adminuser/admin_customers_table.dart';
import '/admin/adminuser/admin_customer_active_order.dart';
import '/admin/adminuser/admin_customers_adapter.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Future<void> showAdminCustomerDetailsDrawer({
  required BuildContext context,
  required UserRecord user,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'customer-details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Material(
            color: FlutterFlowTheme.of(ctx).primaryBackground,
            elevation: 4,
            child: SizedBox(
              width: 460,
              height: MediaQuery.sizeOf(ctx).height,
              child: AdminCustomerDetailsPanel(user: user),
            ),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: AdminCustomerDetailsPanel(user: user),
    ),
  );
}

class AdminCustomerDetailsPanel extends StatefulWidget {
  const AdminCustomerDetailsPanel({super.key, required this.user});

  final UserRecord user;

  @override
  State<AdminCustomerDetailsPanel> createState() =>
      _AdminCustomerDetailsPanelState();
}

class _AdminCustomerDetailsPanelState extends State<AdminCustomerDetailsPanel> {
  late Future<AdminCustomerActiveOrderTruth> _activeFuture;
  late Future<_CustomerBookingStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _activeFuture = AdminCustomerActiveOrderTruth.resolveForUser(widget.user);
    _statsFuture = _loadStats(widget.user);
  }

  Future<_CustomerBookingStats> _loadStats(UserRecord user) async {
    try {
      final docs = await queryOrderRecordOnce(
        queryBuilder: (q) => q
            .where('USER', isEqualTo: user.reference)
            .orderBy('data_order', descending: true),
        limit: 40,
      );
      var completed = 0;
      var cancelled = 0;
      var active = 0;
      final recent = <AdminBookingRow>[];
      for (final o in docs) {
        final row = AdminBookingRow.fromOrder(o);
        recent.add(row);
        final tone = AdminBookingStatusLabel.toneOf(o);
        if (tone == AdminBookingStatusTone.completed) {
          completed++;
        } else if (tone == AdminBookingStatusTone.canceled ||
            tone == AdminBookingStatusTone.expired) {
          cancelled++;
        } else {
          active++;
        }
      }
      return _CustomerBookingStats(
        totalFetched: docs.length,
        completed: completed,
        cancelled: cancelled,
        activeish: active,
        recent: recent.take(6).toList(growable: false),
      );
    } catch (_) {
      return const _CustomerBookingStats.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = AdminCustomerRow.fromUser(widget.user);
    final theme = FlutterFlowTheme.of(context);
    final phone = AdminCustomerRow.formatPhoneDisplay(row.phone);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uiTr(context, 'ملف العميل'),
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _ProfileHeader(row: row, phone: phone),
              const SizedBox(height: 14),
              _AccountSection(row: row),
              const SizedBox(height: 10),
              _CurrentTripSection(future: _activeFuture),
              const SizedBox(height: 10),
              _BookingsSummarySection(future: _statsFuture),
              const SizedBox(height: 10),
              _ActionsSection(user: widget.user),
              const SizedBox(height: 6),
              _TechnicalPanel(user: widget.user, row: row),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.row, required this.phone});

  final AdminCustomerRow row;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 400;

    final avatar = AdminCustomerAvatar(
      photoUrl: row.photoUrl,
      displayName: row.displayName,
      size: wide ? 72 : 64,
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.titleLarge.override(
            fontFamily: theme.titleLargeFamily,
            fontWeight: FontWeight.w800,
            useGoogleFonts: !theme.titleLargeIsCustom,
          ),
        ),
        if (row.email != '—') ...[
          const SizedBox(height: 4),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                row.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                phone,
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ),
            if (phone != '—') ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(Icons.copy_rounded, size: 16, color: theme.secondaryText),
                tooltip: uiTr(context, 'نسخ'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: row.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(uiTr(context, 'تم النسخ')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _StatusChip(row: row),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration(context, elevated: false),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: info),
              ],
            )
          : Column(
              children: [
                avatar,
                const SizedBox(height: 12),
                info,
              ],
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.row});
  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final (label, bg, fg) = switch (row.accountStatus) {
      AdminCustomerAccountStatus.active => (
          uiTr(context, 'نشط'),
          theme.success.withValues(alpha: 0.12),
          theme.success,
        ),
      AdminCustomerAccountStatus.suspended => (
          uiTr(context, 'موقوف'),
          theme.error.withValues(alpha: 0.1),
          theme.error,
        ),
      AdminCustomerAccountStatus.unknown => (
          uiTr(context, 'غير محدد'),
          theme.alternate.withValues(alpha: 0.35),
          theme.secondaryText,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.labelMedium.override(
          fontFamily: theme.labelMediumFamily,
          color: fg,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelMediumIsCustom,
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.row});
  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: uiTr(context, 'الحساب'),
      children: [
        _Kv(
          label: uiTr(context, 'تاريخ التسجيل'),
          value: row.createdAt != null
              ? dateTimeFormat('d/M/y', row.createdAt, locale: 'ar')
              : '—',
        ),
        _Kv(
          label: uiTr(context, 'آخر نشاط'),
          value: row.lastLoginAt != null
              ? dateTimeFormat('d/M/y – HH:mm', row.lastLoginAt, locale: 'ar')
              : '—',
        ),
        if (row.city != '—')
          _Kv(label: uiTr(context, 'المدينة'), value: row.city),
        _Kv(
          label: uiTr(context, 'إجمالي الرحلات'),
          value: row.bookingsCountLabel,
        ),
      ],
    );
  }
}

class _CurrentTripSection extends StatelessWidget {
  const _CurrentTripSection({required this.future});
  final Future<AdminCustomerActiveOrderTruth> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminCustomerActiveOrderTruth>(
      future: future,
      builder: (context, snap) {
        final theme = FlutterFlowTheme.of(context);
        final truth = snap.data;

        if (snap.connectionState != ConnectionState.done) {
          return _SectionCard(
            title: uiTr(context, 'الرحلة الحالية'),
            children: [
              LinearProgressIndicator(
                minHeight: 2,
                color: AdminUi.brandTeal.withValues(alpha: 0.5),
              ),
            ],
          );
        }

        if (truth == null || !truth.hasLiveTrip || truth.orderId.isEmpty) {
          return _SectionCard(
            title: uiTr(context, 'الرحلة الحالية'),
            children: [
              Text(
                truth != null && truth.isStaleLock
                    ? uiTr(context, 'لا توجد رحلة حالية')
                    : uiTr(context, 'لا توجد رحلة حالية'),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          );
        }

        return _SectionCard(
          title: uiTr(context, 'الرحلة الحالية'),
          children: [
            _Kv(
              label: uiTr(context, 'رقم الحجز'),
              value: truth.orderId,
              ltr: true,
            ),
            _Kv(
              label: uiTr(context, 'الحالة'),
              value: truth.statusLabel.isNotEmpty ? truth.statusLabel : '—',
            ),
            if (truth.row != null &&
                truth.row!.driverName.isNotEmpty)
              _Kv(
                label: uiTr(context, 'المندوب'),
                value: truth.row!.driverName,
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).maybePop();
                  context.pushNamed(
                    AdminBookingDetailsWidget.routeName,
                    queryParameters: {
                      'idbokeng': serializeParam(
                        OrderRecord.collection.doc(truth.orderId),
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Text(uiTr(context, 'عرض الحجز')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingsSummarySection extends StatelessWidget {
  const _BookingsSummarySection({required this.future});
  final Future<_CustomerBookingStats> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CustomerBookingStats>(
      future: future,
      builder: (context, snap) {
        final theme = FlutterFlowTheme.of(context);
        if (snap.connectionState != ConnectionState.done) {
          return _SectionCard(
            title: uiTr(context, 'النشاط'),
            children: [
              LinearProgressIndicator(
                minHeight: 2,
                color: AdminUi.brandTeal.withValues(alpha: 0.5),
              ),
            ],
          );
        }

        final s = snap.data;
        if (s == null || s.totalFetched == 0) {
          return _SectionCard(
            title: uiTr(context, 'النشاط'),
            children: [
              Text(
                uiTr(context, 'لا توجد حجوزات'),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          );
        }

        return _SectionCard(
          title: uiTr(context, 'النشاط'),
          children: [
            Row(
              children: [
                _miniStat(context, uiTr(context, 'عينة'), '${s.totalFetched}'),
                const SizedBox(width: 12),
                _miniStat(context, uiTr(context, 'مكتملة'), '${s.completed}'),
                const SizedBox(width: 12),
                _miniStat(context, uiTr(context, 'ملغاة'), '${s.cancelled}'),
              ],
            ),
            if (s.recent.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                uiTr(context, 'آخر الحجوزات'),
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelMediumIsCustom,
                ),
              ),
              const SizedBox(height: 6),
              for (final b in s.recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              b.orderId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                fontFamily: theme.bodySmallFamily,
                                fontWeight: FontWeight.w500,
                                useGoogleFonts: !theme.bodySmallIsCustom,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          b.statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.titleSmall.override(
            fontFamily: theme.titleSmallFamily,
            fontWeight: FontWeight.w700,
            color: AdminUi.brandTeal,
            useGoogleFonts: !theme.titleSmallIsCustom,
          ),
        ),
        Text(
          label,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.user});
  final UserRecord user;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: uiTr(context, 'إجراءات'),
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () {
            Navigator.of(context).maybePop();
            context.pushNamed(
              DriverProfileWidget.routeName,
              queryParameters: {
                'iduser': serializeParam(
                  user.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            );
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(uiTr(context, 'تعديل البيانات')),
        ),
      ],
    );
  }
}

class _TechnicalPanel extends StatelessWidget {
  const _TechnicalPanel({required this.user, required this.row});
  final UserRecord user;
  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fields = <(String, String)>[
      ('doc_id', user.reference.id),
      if (user.uid.trim().isNotEmpty) ('uid', user.uid.trim()),
      if (row.activeOrderId.isNotEmpty)
        ('active_order_id', row.activeOrderId),
      if (user.hasActevUser()) ('actev_user', '${user.actevUser}'),
      if (user.revDolh != null) ('Rev_dolh', user.revDolh!.id),
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        title: Text(
          uiTr(context, 'معلومات تقنية'),
          style: theme.labelLarge.override(
            fontFamily: theme.labelLargeFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.labelLargeIsCustom,
          ),
        ),
        children: fields
            .map(
              (e) => _Kv(label: e.$1, value: e.$2, ltr: true),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdminUi.cardDecoration(context, elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final display = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection:
                  ltr ? ui.TextDirection.ltr : ui.TextDirection.rtl,
              child: Text(
                display,
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w500,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBookingStats {
  const _CustomerBookingStats({
    required this.totalFetched,
    required this.completed,
    required this.cancelled,
    required this.activeish,
    required this.recent,
  });

  const _CustomerBookingStats.empty()
      : totalFetched = 0,
        completed = 0,
        cancelled = 0,
        activeish = 0,
        recent = const [];

  final int totalFetched;
  final int completed;
  final int cancelled;
  final int activeish;
  final List<AdminBookingRow> recent;
}
