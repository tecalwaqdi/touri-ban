import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/core/toury_ngenius_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_extra_hours2_model.dart';

export 'add_extra_hours2_model.dart';

class AddExtraHours2Widget extends StatefulWidget {
  const AddExtraHours2Widget({
    super.key,
    required this.idorder,
    required this.srsaah,
    required this.idMndob,
    this.numperOrder,
  });

  final DocumentReference? idorder;
  final double? srsaah;
  final DocumentReference? idMndob;
  final String? numperOrder;

  @override
  State<AddExtraHours2Widget> createState() => _AddExtraHours2WidgetState();
}

class _AddExtraHours2WidgetState extends State<AddExtraHours2Widget> {
  late AddExtraHours2Model _model;
  int _hours = 1;
  bool _submitting = false;

  double get _hourlyRate => widget.srsaah ?? 0;
  double get _total => _hourlyRate * _hours;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddExtraHours2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (_submitting || widget.idorder == null || _hourlyRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_verify_error'.tr())),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      FFAppState().clearSensitivePaymentSession();
      final response = await NGeniusPaymentCall.call(
        description:
            'Touri Taxi extra hours - ${widget.numperOrder ?? widget.idorder!.id}',
        amount: (_total * 100).round(),
        paymentPurpose: 'extra_hours',
        orderPath: widget.idorder!.path,
        extraHours: _hours,
      );
      if (!TouryNGeniusService.createReady(response)) {
        throw StateError('payment_not_ready');
      }

      final sessionId = NGeniusPaymentCall.id(response.jsonBody);
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('missing_payment_session');
      }
      FFAppState().update(() {
        FFAppState().NumberSaatExtra = _hours;
        FFAppState().totalSaatEXTRA = _total;
        FFAppState().paymentOrderId = sessionId;
        FFAppState().paymentFlowKind = TypeHgz.Saat;
        FFAppState().revOrderSaatExtr = widget.idorder;
        FFAppState().RevMndonSaatExtra = widget.idMndob;
        FFAppState().idOrderSaatEXtra = widget.numperOrder ?? '';
        FFAppState().paymentInProgress = true;
        FFAppState().DonePay = false;
      });

      final paymentUrl = NGeniusPaymentCall.url(response.jsonBody);
      if (!mounted) return;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        final finalized = await TouryNGeniusService.finalizeExtraHours(
          sessionId: sessionId,
        );
        if (!TouryNGeniusService.httpOk(finalized)) {
          throw StateError('payment_not_finalized');
        }
        if (mounted) Navigator.pop(context);
        return;
      }

      context.pushNamed(
        WebviewWidget.routeName,
        queryParameters: {
          'url': serializeParam(paymentUrl, ParamType.String),
        }.withoutNulls,
      );
    } catch (_) {
      FFAppState().clearSensitivePaymentSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('payment_verify_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return SafeArea(
      top: false,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.lg,
            DsSpacing.sm,
            DsSpacing.lg,
            DsSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Need extra hours?'.tr(),
                      style: typography.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DsIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(context),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Text(
                'Number of Extra Hours'.tr(),
                style: typography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: DsSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DsIconButton(
                    icon: Icons.remove_rounded,
                    filled: true,
                    onPressed:
                        _hours > 1 ? () => setState(() => _hours--) : null,
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '$_hours',
                      textAlign: TextAlign.center,
                      style: typography.headlineSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DsIconButton(
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed:
                        _hours < 168 ? () => setState(() => _hours++) : null,
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: colors.primary,
                ),
                title: Text(
                  'ux_card_payment_network'.tr(),
                  style: typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${'Total Amount:'.tr()} ${_total.toStringAsFixed(2)} SAR',
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              DsButton.primary(
                label: 'Add'.tr(),
                icon: Icons.lock_outline_rounded,
                expanded: true,
                loading: _submitting,
                enabled: !_submitting,
                onPressed: _startPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
