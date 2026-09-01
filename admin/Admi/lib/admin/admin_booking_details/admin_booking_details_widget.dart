import '/admin/admin_booking_details/admin_booking_details_adapter.dart';
import '/admin/admin_booking_details/admin_booking_journey_section.dart';
import '/admin/admin_booking_details/admin_booking_details_sections.dart';
import '/backend/admin_resource_guard.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_currency.dart';
import '/core/finance/financial_engine.dart';
import '/core/payments/admin_payment_api_client.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_booking_details_model.dart';
export 'admin_booking_details_model.dart';

class AdminBookingDetailsWidget extends StatefulWidget {
  const AdminBookingDetailsWidget({
    super.key,
    required this.idbokeng,
  });

  final DocumentReference? idbokeng;

  static String routeName = 'AdminBookingDetails';
  static String routePath = '/adminBookingDetails';

  @override
  State<AdminBookingDetailsWidget> createState() =>
      _AdminBookingDetailsWidgetState();
}

class _AdminBookingDetailsWidgetState extends State<AdminBookingDetailsWidget> {
  late AdminBookingDetailsModel _model;
  bool _refundSubmitting = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminBookingDetailsModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _confirmRefund(OrderRecord order) async {
    final reasonController = TextEditingController();
    final paidMinor = (order.snapshotData['amount_halalas'] as num?)?.toInt() ??
        (order.total * 100).round();
    final alreadyMinor =
        (order.snapshotData['refund_amount_halalas'] as num?)?.toInt() ?? 0;
    final remainingMinor = (paidMinor - alreadyMinor).clamp(0, paidMinor);
    final currency = AdminCurrency.codeForOrder(order);
    final currencySymbol = AdminCurrency.displaySymbolForOrder(order);
    final currencyLabel = currencySymbol.isNotEmpty
        ? currencySymbol
        : (currency.isNotEmpty ? currency : '—');
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(uiTr(context, 'استرداد')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${uiTr(context, 'المبلغ المدفوع')}: '
                  '${(paidMinor / 100).toStringAsFixed(2)} $currencyLabel',
                ),
                Text(
                  '${uiTr(context, 'تم الاسترداد')}: '
                  '${(alreadyMinor / 100).toStringAsFixed(2)} $currencyLabel',
                ),
                Text(
                  '${uiTr(context, 'المتبقي')}: '
                  '${(remainingMinor / 100).toStringAsFixed(2)} $currencyLabel',
                ),
                const SizedBox(height: 12),
                Text(uiTr(context, 'تأكيد استرداد المبلغ المدفوع؟')),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'الوصف'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(uiTr(context, 'إلغاء')),
              ),
              FilledButton(
                onPressed:
                    remainingMinor <= 0 ? null : () => Navigator.pop(ctx, true),
                child: Text(uiTr(context, 'تأكيد')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted || remainingMinor <= 0) return;

    setState(() => _refundSubmitting = true);
    try {
      final sessionId =
          (order.snapshotData['payment_session_id'] ?? order.reference.id)
              .toString();
      await AdminPaymentApiClient().refund(
        sessionId: sessionId,
        idempotencyKey:
            'admin_refund_${order.reference.id}_${DateTime.now().millisecondsSinceEpoch}',
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uiTr(context, 'تم بنجاح')),
          duration: const Duration(seconds: 2),
        ),
      );
      safeSetState(() {});
    } catch (e) {
      if (!mounted) return;
      final code = e is StateError ? e.message : 'UNKNOWN_ERROR';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'REFUND_NOT_CONFIGURED'
                ? uiTr(context, 'الاسترداد غير مهيأ')
                : uiTr(context, 'فشل'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _refundSubmitting = false);
    }
  }

  bool _canRefund(OrderRecord order) =>
      AdminRoleService.isFinance &&
      AdminPaymentApiClient.baseUrl.isNotEmpty &&
      OrderStatusHelper.statusOf(order) == OrderPaymentStatus.paid &&
      order.paymentMethod == PaymentMethod.OnlinePayment;

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      foregroundColor: FlutterFlowTheme.of(context).primaryText,
      elevation: 0,
      leading: FlutterFlowIconButton(
        buttonSize: 44,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: FlutterFlowTheme.of(context).primaryText,
          size: 22,
        ),
        onPressed: () => context.safePop(),
      ),
      title: Text(
        uiTr(context, 'تفاصيل الحجز'),
        style: FlutterFlowTheme.of(context).titleMedium.override(
              fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
              fontWeight: FontWeight.w600,
              useGoogleFonts: !FlutterFlowTheme.of(context).titleMediumIsCustom,
            ),
      ),
      centerTitle: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.idbokeng == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: _appBar(context),
        body: Center(child: Text(uiTr(context, 'تعذر تحميل بيانات الحجز'))),
      );
    }

    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(widget.idbokeng!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: _appBar(context),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  uiTr(
                    context,
                    'تعذر تحميل بيانات الحجز. تحقق من الاتصال وحاول مرة أخرى.',
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: _appBar(context),
            body: const AdminBookingDetailsSkeleton(),
          );
        }

        final order = snapshot.data!;

        return FutureBuilder<bool>(
          future: AdminResourceGuard.canViewOrderAsync(order),
          builder: (context, accessSnap) {
            if (!accessSnap.hasData) {
              return Scaffold(
                backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
                appBar: _appBar(context),
                body: const AdminBookingDetailsSkeleton(),
              );
            }

            if (accessSnap.data != true) {
              return Scaffold(
                backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
                appBar: _appBar(context),
                body: Center(
                  child: Text(uiTr(context, 'لا تملك صلاحية عرض هذا الحجز')),
                ),
              );
            }

            return _buildDetails(context, order);
          },
        );
      },
    );
  }

  Widget _buildDetails(BuildContext context, OrderRecord order) {
    final view = AdminBookingDetailsView.fromOrder(order);
    final pickupLocation = order.lokeshn;
    final driverLocation = order.mapuser;
    final mapLocation = driverLocation ?? pickupLocation;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: _appBar(context),
        body: Column(
          children: [
            AdminBookingDetailsHeader(view: view),
            AdminBookingDetailsSummaryStrip(view: view),
            Expanded(
              child: AdminSafeScrollBody(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final leftColumn = <Widget>[
                      AdminBookingDetailsPaymentCard(
                        view: view,
                        refundSubmitting: _refundSubmitting,
                        onRefund: _canRefund(order)
                            ? () => _confirmRefund(order)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AdminBookingDetailsCancellationCard(view: view),
                      if (view.row.statusTone !=
                              AdminBookingStatusTone.canceled &&
                          view.row.statusTone != AdminBookingStatusTone.expired)
                        const SizedBox(height: 12),
                      AdminBookingDetailsTimeline(view: view),
                    ];

                    final rightColumn = <Widget>[
                      AdminBookingDetailsCustomerCard(view: view),
                      const SizedBox(height: 12),
                      AdminBookingDetailsDriverCard(view: view),
                      const SizedBox(height: 12),
                      AdminBookingDetailsTripCard(view: view),
                      const SizedBox(height: 12),
                      AdminBookingJourneySection(order: order),
                    ];

                    final bottom = <Widget>[
                      const SizedBox(height: 12),
                      AdminBookingDetailsRouteSection(
                        view: view,
                        mapLocation: mapLocation,
                        googleMapsController: _model.googleMapsController,
                        googleMapsCenter: _model.googleMapsCenter,
                        onCameraIdle: (latLng) =>
                            _model.googleMapsCenter = latLng,
                      ),
                      const SizedBox(height: 8),
                      AdminBookingDetailsTechnicalPanel(view: view),
                    ];

                    if (wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: rightColumn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: leftColumn,
                                ),
                              ),
                            ],
                          ),
                          ...bottom,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...rightColumn,
                        const SizedBox(height: 12),
                        ...leftColumn,
                        ...bottom,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
