import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/admin_suport/admin_support_adapter.dart';
import '/admin/adminuser/admin_customer_active_order.dart';
import '/admin/adminuser/admin_customers_adapter.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_status_truth.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Future<void> showAdminSupportDetailsDrawer({
  required BuildContext context,
  required AdminSupportRow row,
  required bool canEdit,
  required Future<void> Function(AdminSupportDisplayStatus) onStatusChange,
  required Future<void> Function(String note) onInternalNote,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'support-details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Material(
          color: FlutterFlowTheme.of(ctx).primaryBackground,
          elevation: 8,
          child: SizedBox(
            width: 480,
            height: MediaQuery.sizeOf(ctx).height,
            child: AdminSupportDetailsPanel(
              row: row,
              canEdit: canEdit,
              onStatusChange: onStatusChange,
              onInternalNote: onInternalNote,
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: AdminSupportDetailsPanel(
        row: row,
        canEdit: canEdit,
        onStatusChange: onStatusChange,
        onInternalNote: onInternalNote,
      ),
    ),
  );
}

class AdminSupportDetailsPanel extends StatefulWidget {
  const AdminSupportDetailsPanel({
    super.key,
    required this.row,
    required this.canEdit,
    required this.onStatusChange,
    required this.onInternalNote,
  });

  final AdminSupportRow row;
  final bool canEdit;
  final Future<void> Function(AdminSupportDisplayStatus) onStatusChange;
  final Future<void> Function(String note) onInternalNote;

  @override
  State<AdminSupportDetailsPanel> createState() =>
      _AdminSupportDetailsPanelState();
}

class _AdminSupportDetailsPanelState extends State<AdminSupportDetailsPanel> {
  late Future<_SupportContext> _contextFuture;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext(widget.row);
  }

  Future<_SupportContext> _loadContext(AdminSupportRow row) async {
    UserRecord? user;
    OrderRecord? order;
    AdminBookingRow? bookingRow;
    AdminCustomerActiveOrderTruth? activeTrip;
    AdminDriverStatusTruth? driverTruth;

    if (row.userRef != null) {
      try {
        user = await UserRecord.getDocumentOnce(row.userRef!);
        if (!user.ismndob && !user.ismndom && !user.isagent) {
          activeTrip = await AdminCustomerActiveOrderTruth.resolveForUser(user);
        } else if (user.ismndob || user.ismndom) {
          driverTruth = AdminDriverStatusTruth.fromMap(user.snapshotData);
        }
      } catch (_) {}
    }

    if (row.orderRef != null) {
      try {
        order = await OrderRecord.getDocumentOnce(row.orderRef!);
        bookingRow = AdminBookingRow.fromOrder(order);
      } catch (_) {}
    }

    final notes = _readInternalNotes(row.ticket.snapshotData);
    final ownerType = user != null
        ? AdminSupportRow.ownerTypeFromUser(user)
        : row.ownerType;

    return _SupportContext(
      user: user,
      order: order,
      bookingRow: bookingRow,
      activeTrip: activeTrip,
      driverTruth: driverTruth,
      ownerType: ownerType,
      internalNotes: notes,
    );
  }

  static List<Map<String, String>> _readInternalNotes(Map<String, dynamic> data) {
    final raw = data['admin_internal_notes'];
    if (raw is! List) return const [];
    final out = <Map<String, String>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add({
          'text': '${item['text'] ?? ''}',
          'adminId': '${item['adminId'] ?? ''}',
          'at': '${item['at'] ?? ''}',
        });
      }
    }
    return out.reversed.toList();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = widget.row;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uiTr(context, 'تفاصيل التذكرة'),
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<_SupportContext>(
            future: _contextFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final ctx = snap.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _section(
                    context,
                    uiTr(context, 'معلومات التذكرة'),
                    [
                      _kv(
                        context,
                        uiTr(context, 'رقم التذكرة'),
                        row.legacyNumericId > 0
                            ? '#${row.legacyNumericId}'
                            : row.ticketId,
                      ),
                      _kv(context, uiTr(context, 'العنوان'), row.subject),
                      _kv(context, uiTr(context, 'التصنيف'), row.category),
                      _StatusBadge(status: row.displayStatus),
                      _kv(
                        context,
                        uiTr(context, 'تاريخ الإنشاء'),
                        row.createdAt != null
                            ? dateTimeFormat('yMMMd – HH:mm', row.createdAt)
                            : '—',
                      ),
                    ],
                  ),
                  _section(
                    context,
                    uiTr(context, 'صاحب التذكرة'),
                    [
                      _kv(context, uiTr(context, 'الاسم'), row.ownerName),
                      _kv(
                        context,
                        uiTr(context, 'النوع'),
                        _ownerLabel(context, ctx?.ownerType ?? row.ownerType),
                      ),
                      if (row.phoneLabel.isNotEmpty)
                        _kv(context, uiTr(context, 'الهاتف'), row.phoneLabel),
                      if (row.email.isNotEmpty)
                        _kv(context, uiTr(context, 'البريد'), row.email),
                      if (ctx?.user != null) ...[
                        if (ctx!.ownerType == AdminSupportOwnerType.customer)
                          _kv(
                            context,
                            uiTr(context, 'حالة الحساب'),
                            AdminCustomerRow.accountStatusOf(ctx.user!)
                                .name,
                          ),
                        if (ctx.ownerType == AdminSupportOwnerType.driver &&
                            ctx.driverTruth != null)
                          _kv(
                            context,
                            uiTr(context, 'حالة التسجيل'),
                            ctx.driverTruth!.registrationRaw.isNotEmpty
                                ? ctx.driverTruth!.registrationRaw
                                : ctx.driverTruth!.registration.name,
                          ),
                      ],
                    ],
                  ),
                  if (ctx?.ownerType == AdminSupportOwnerType.customer &&
                      ctx?.activeTrip != null)
                    _section(
                      context,
                      uiTr(context, 'رحلة العميل الحالية'),
                      [
                        if (ctx!.activeTrip!.hasLiveTrip)
                          Text(
                            '${ctx.activeTrip!.statusLabel} · ${ctx.activeTrip!.orderId}',
                          )
                        else
                          Text(uiTr(context, 'لا توجد رحلة نشطة')),
                      ],
                    ),
                  if (ctx?.bookingRow != null || row.hasOrderLink)
                    _section(
                      context,
                      uiTr(context, 'الحجز المرتبط'),
                      [
                        if (ctx?.bookingRow != null) ...[
                          _kv(
                            context,
                            'Order ID',
                            ctx!.bookingRow!.orderId,
                          ),
                          _kv(
                            context,
                            uiTr(context, 'الحالة'),
                            ctx.bookingRow!.statusLabel,
                          ),
                          _kv(
                            context,
                            uiTr(context, 'الانطلاق'),
                            ctx.bookingRow!.pickupLabel,
                          ),
                          _kv(
                            context,
                            uiTr(context, 'الوجهة'),
                            ctx.bookingRow!.destinationLabel,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                              context.pushNamed(
                                AdminBookingDetailsWidget.routeName,
                                queryParameters: {
                                  'orderRef': serializeParam(
                                    row.orderRef ?? ctx.bookingRow!.order.reference,
                                    ParamType.DocumentReference,
                                  ),
                                }.withoutNulls,
                              );
                            },
                            child: Text(uiTr(context, 'فتح تفاصيل الحجز')),
                          ),
                        ] else
                          Text(row.orderRef?.id ?? '—'),
                      ],
                    ),
                  _section(
                    context,
                    uiTr(context, 'الرسالة'),
                    [
                      Text(
                        AdminSupportRow.messageOf(row.ticket.snapshotData),
                        style: theme.bodyMedium,
                      ),
                    ],
                  ),
                  if (row.attachmentUrl.isNotEmpty)
                    _section(
                      context,
                      uiTr(context, 'المرفقات'),
                      [
                        AdminRecordThumbnail(
                          imageUrl: row.attachmentUrl,
                          width: 120,
                          height: 120,
                          borderRadius: BorderRadius.circular(8),
                          fallback: Text(uiTr(context, 'ملف غير متاح')),
                        ),
                      ],
                    ),
                  _section(
                    context,
                    uiTr(context, 'ملاحظات داخلية (إدارية)'),
                    [
                      if (ctx != null && ctx.internalNotes.isNotEmpty)
                        for (final n in ctx.internalNotes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${n['text']}\n${n['adminId']} · ${n['at']}',
                              style: theme.bodySmall,
                            ),
                          )
                      else
                        Text(
                          uiTr(context, 'لا توجد ملاحظات'),
                          style: theme.bodySmall,
                        ),
                      if (widget.canEdit) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: uiTr(context, 'أضف ملاحظة داخلية'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final text = _noteController.text.trim();
                                    if (text.isEmpty) return;
                                    setState(() => _submitting = true);
                                    await widget.onInternalNote(text);
                                    if (!mounted) return;
                                    _noteController.clear();
                                    setState(() {
                                      _submitting = false;
                                      _contextFuture = _loadContext(widget.row);
                                    });
                                  },
                            child: Text(uiTr(context, 'حفظ الملاحظة')),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.canEdit)
                    _section(
                      context,
                      uiTr(context, 'إجراءات الحالة'),
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _actionChip(
                              context,
                              uiTr(context, 'بدء المعالجة'),
                              AdminSupportDisplayStatus.inProgress,
                            ),
                            _actionChip(
                              context,
                              uiTr(context, 'بانتظار العميل'),
                              AdminSupportDisplayStatus.waitingUser,
                            ),
                            _actionChip(
                              context,
                              uiTr(context, 'تم الحل'),
                              AdminSupportDisplayStatus.resolved,
                            ),
                            _actionChip(
                              context,
                              uiTr(context, 'إغلاق'),
                              AdminSupportDisplayStatus.closed,
                            ),
                            if (row.isTerminal)
                              _actionChip(
                                context,
                                uiTr(context, 'إعادة فتح'),
                                AdminSupportDisplayStatus.open,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${uiTr(context, 'المسؤول')}: ${row.assignedAdminId.isNotEmpty ? row.assignedAdminId : uiTr(context, 'غير معيّن')}',
                          style: theme.bodySmall,
                        ),
                        if (currentUserUid.isNotEmpty)
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    setState(() => _submitting = true);
                                    await widget.row.ticket.reference.update({
                                      'admin_assigned_to': currentUserUid,
                                      'updated_at': FieldValue.serverTimestamp(),
                                    });
                                    if (mounted) {
                                      setState(() => _submitting = false);
                                    }
                                  },
                            child: Text(uiTr(context, 'تعيين لي')),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionChip(
    BuildContext context,
    String label,
    AdminSupportDisplayStatus status,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: _submitting
          ? null
          : () async {
              setState(() => _submitting = true);
              await widget.onStatusChange(status);
              if (!mounted) return;
              Navigator.of(context).maybePop();
            },
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w800,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: theme.labelMedium)),
          Expanded(child: Text(v, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

String _ownerLabel(BuildContext context, AdminSupportOwnerType type) =>
    switch (type) {
      AdminSupportOwnerType.customer => uiTr(context, 'عميل'),
      AdminSupportOwnerType.driver => uiTr(context, 'مندوب'),
      AdminSupportOwnerType.unknown => uiTr(context, 'غير محدد'),
    };

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AdminSupportDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      AdminSupportDisplayStatus.newTicket => uiTr(context, 'جديدة'),
      AdminSupportDisplayStatus.open => uiTr(context, 'مفتوحة'),
      AdminSupportDisplayStatus.inProgress => uiTr(context, 'قيد المعالجة'),
      AdminSupportDisplayStatus.waitingUser => uiTr(context, 'بانتظار العميل'),
      AdminSupportDisplayStatus.resolved => uiTr(context, 'تم الحل'),
      AdminSupportDisplayStatus.closed => uiTr(context, 'مغلقة'),
      AdminSupportDisplayStatus.unknown => uiTr(context, 'غير معروف'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AdminStatusBadgeUnified(
        kind: AdminStatusKind.pending,
        label: label,
      ),
    );
  }
}

class _SupportContext {
  const _SupportContext({
    this.user,
    this.order,
    this.bookingRow,
    this.activeTrip,
    this.driverTruth,
    required this.ownerType,
    required this.internalNotes,
  });

  final UserRecord? user;
  final OrderRecord? order;
  final AdminBookingRow? bookingRow;
  final AdminCustomerActiveOrderTruth? activeTrip;
  final AdminDriverStatusTruth? driverTruth;
  final AdminSupportOwnerType ownerType;
  final List<Map<String, String>> internalNotes;
}
