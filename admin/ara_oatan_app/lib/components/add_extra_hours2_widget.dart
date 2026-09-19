import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_extra_hours_service.dart';
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
    this.service,
  });

  final DocumentReference? idorder;
  // Retained for existing callers; the trusted quote comes from the order.
  final double? srsaah;
  final DocumentReference? idMndob;
  final String? numperOrder;
  final TouryExtraHoursService? service;

  @override
  State<AddExtraHours2Widget> createState() => _AddExtraHours2WidgetState();
}

class _AddExtraHours2WidgetState extends State<AddExtraHours2Widget> {
  late AddExtraHours2Model _model;
  late final TouryExtraHoursService _service;
  int _hours = 1;
  int _quoteGeneration = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  TouryExtraHoursQuote? _quote;
  String _requestKey = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddExtraHours2Model());
    _service = widget.service ?? TouryExtraHoursService();
    _loadQuote();
  }

  @override
  void dispose() {
    _quoteGeneration++;
    _model.maybeDispose();
    super.dispose();
  }

  String _message(Object error) {
    final code = error is TouryExtraHoursException ? error.code : '';
    if (code == 'EXTRA_HOURS_NOT_APPLIED') {
      return 'extra_hours_paid_not_applied'.tr();
    }
    if (code == 'EXTRA_HOURS_QUOTE_CHANGED') {
      return 'extra_hours_quote_changed'.tr();
    }
    if (code == 'EXTRA_HOURS_PAYMENT_PENDING') {
      return 'extra_hours_payment_pending'.tr();
    }
    if (code == 'EXTRA_HOURS_NOT_ACTIVE' ||
        code == 'EXTRA_HOURS_NOT_OWNER' ||
        code == 'EXTRA_HOURS_PAYMENT_NOT_ELIGIBLE') {
      return 'extra_hours_ineligible'.tr();
    }
    if (code.startsWith('EXTRA_HOURS_FINANCE') ||
        code == 'EXTRA_HOURS_PRICE_UNAVAILABLE' ||
        code == 'EXTRA_HOURS_CURRENCY_UNSUPPORTED') {
      return 'extra_hours_price_unavailable'.tr();
    }
    return 'payment_verify_error'.tr();
  }

  Future<void> _loadQuote() async {
    final ref = widget.idorder;
    if (ref == null) return;
    final generation = ++_quoteGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quote = await _service.quote(ref, _hours);
      if (!mounted || generation != _quoteGeneration) return;
      setState(() {
        if (_quote?.token != quote.token) {
          _requestKey =
              'extra_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
        }
        _quote = quote;
        _hours = quote.hours;
      });
    } catch (error) {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  String _summary(TouryExtraHoursQuote quote) => [
        '${'extra_hours_current'.tr()}: ${quote.currentHours}',
        '${'Number of Extra Hours'.tr()}: ${quote.hours}',
        '${'extra_hours_cost'.tr()}: ${quote.money('amountMinor')}',
        '${'extra_hours_new_total'.tr()}: ${quote.money('newTotalMinor')}',
        quote.isCash
            ? 'extra_hours_cash_notice'.tr()
            : 'extra_hours_online_notice'.tr(),
      ].join('\n');

  Future<void> _submit() async {
    final quote = _quote;
    final ref = widget.idorder;
    if (_submitting ||
        _loading ||
        _error != null ||
        quote == null ||
        ref == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final confirmed = await TouryDialogs.showConfirm(
        context,
        title: 'extra_hours_confirm_title'.tr(),
        message: _summary(quote),
        confirmLabel: quote.isCash
            ? 'dialog_confirm'.tr()
            : 'extra_hours_continue_payment'.tr(),
      );
      if (!confirmed || !mounted) return;
      if (quote.isCash) {
        final result = await _service.addCash(ref, quote, _requestKey);
        if (result['applied'] != true) {
          throw const TouryExtraHoursException('EXTRA_HOURS_NOT_APPLIED');
        }
        if (!mounted) return;
        TouryDialogs.showSnackBar(
            context, 'Extra hours have been added to the trip'.tr(),
            type: TouryMessageType.success);
        Navigator.pop(context, true);
        return;
      }

      final response = quote.resumeSessionId == null
          ? await _service.createPayment(ref, quote, _requestKey)
          : await TouryNGeniusService.getPayment(
              orderId: quote.resumeSessionId!);
      final sessionId = TouryNGeniusService.paymentId(response.jsonBody);
      if (sessionId == null || !TouryNGeniusService.httpOk(response)) {
        throw const TouryExtraHoursException('EXTRA_HOURS_PAYMENT_PENDING');
      }
      FFAppState().update(() {
        FFAppState().NumberSaatExtra = quote.hours;
        FFAppState().totalSaatEXTRA =
            quote.number('amountMinor') / quote.number('factor');
        FFAppState().paymentOrderId = sessionId;
        FFAppState().paymentFlowKind = TypeHgz.Saat;
        FFAppState().revOrderSaatExtr = ref;
        FFAppState().RevMndonSaatExtra = widget.idMndob;
        FFAppState().idOrderSaatEXtra = widget.numperOrder ?? '';
        FFAppState().paymentInProgress = true;
        FFAppState().DonePay = false;
      });
      if (TouryNGeniusService.isPaid(response.jsonBody)) {
        final result =
            await TouryNGeniusService.finalizeExtraHours(sessionId: sessionId);
        if (!TouryNGeniusService.httpOk(result) ||
            result.jsonBody['applied'] != true) {
          throw const TouryExtraHoursException('EXTRA_HOURS_NOT_APPLIED');
        }
        FFAppState().paymentInProgress = false;
        if (mounted) Navigator.pop(context, true);
        return;
      }
      final url = TouryNGeniusService.transactionUrl(response.jsonBody);
      if (url == null || url.isEmpty) {
        throw const TouryExtraHoursException('EXTRA_HOURS_PAYMENT_PENDING');
      }
      if (!mounted) return;
      // Reuse the existing extra-hours HPP, verification and finalization flow.
      await context.pushNamed(WebviewWidget.routeName,
          queryParameters:
              {'url': serializeParam(url, ParamType.String)}.withoutNulls);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      // Keep the request key on uncertain responses: retrying cannot charge or
      // extend twice. Server pending sessions are recoverable on reopening.
      if (!mounted) return;
      TouryDialogs.showSnackBar(context, _message(error),
          type: TouryMessageType.error);
      if (error is TouryExtraHoursException &&
          (error.code == 'EXTRA_HOURS_QUOTE_CHANGED' ||
              error.code == 'EXTRA_HOURS_PAYMENT_PENDING')) {
        await _loadQuote();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
        child: Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: DsSpacing.sm),
          Text(value)
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final quote = _quote;
    final canChoose =
        !_submitting && !_loading && quote?.resumeSessionId == null;
    return SafeArea(
        top: false,
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Need extra hours?'.tr(),
                            style: context.dsTypography.titleLarge)),
                    DsIconButton(
                        icon: Icons.close_rounded,
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip),
                  ]),
                  const SizedBox(height: DsSpacing.md),
                  Text('Number of Extra Hours'.tr()),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    DsIconButton(
                        icon: Icons.remove_rounded,
                        filled: true,
                        onPressed: canChoose && _hours > 1
                            ? () {
                                _hours--;
                                _loadQuote();
                              }
                            : null),
                    SizedBox(
                        width: 72,
                        child: Text('$_hours',
                            textAlign: TextAlign.center,
                            style: context.dsTypography.headlineSmall)),
                    DsIconButton(
                        icon: Icons.add_rounded,
                        filled: true,
                        onPressed: canChoose && _hours < 168
                            ? () {
                                _hours++;
                                _loadQuote();
                              }
                            : null),
                  ]),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(DsSpacing.md),
                        child: Center(child: CircularProgressIndicator())),
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: colors.error)),
                    TextButton(
                        onPressed: _submitting ? null : _loadQuote,
                        child: Text('ux_retry'.tr())),
                  ],
                  if (quote != null && !_loading && _error == null) ...[
                    _row('extra_hours_current'.tr(), '${quote.currentHours}'),
                    _row('Number of Extra Hours'.tr(), '${quote.hours}'),
                    _row('extra_hours_new_duration'.tr(), '${quote.newHours}'),
                    _row('extra_hours_cost'.tr(), quote.money('amountMinor')),
                    _row('extra_hours_new_total'.tr(),
                        quote.money('newTotalMinor')),
                    const SizedBox(height: DsSpacing.sm),
                    Text(quote.isCash
                        ? 'extra_hours_cash_notice'.tr()
                        : 'extra_hours_online_notice'.tr()),
                    if (quote.resumeSessionId != null)
                      Text('extra_hours_payment_pending'.tr()),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  DsButton.primary(
                      label: 'Add'.tr(),
                      icon: Icons.add_alarm_outlined,
                      expanded: true,
                      loading: _submitting,
                      enabled: !_submitting &&
                          !_loading &&
                          _error == null &&
                          quote != null,
                      onPressed: _submit),
                ]),
          ),
        ));
  }
}
