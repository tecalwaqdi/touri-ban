import '/auth/firebase_auth/auth_util.dart';
import 'package:easy_localization/easy_localization.dart';
import '/backend/backend.dart';
import '/core/toury_customer_cancel_policy.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'details24_quiz_page_model.dart';
export 'details24_quiz_page_model.dart';

class Details24QuizPageWidget extends StatefulWidget {
  const Details24QuizPageWidget({
    super.key,
    required this.usermndob,
    required this.idordeer,
    required this.naimMndob,
  });

  final DocumentReference? usermndob;
  final DocumentReference? idordeer;
  final String? naimMndob;

  static String routeName = 'Details24QuizPage';
  static String routePath = '/details24QuizPage';

  @override
  State<Details24QuizPageWidget> createState() =>
      _Details24QuizPageWidgetState();
}

class _Details24QuizPageWidgetState extends State<Details24QuizPageWidget> {
  late Details24QuizPageModel _model;
  bool _submitting = false;
  bool _ownershipChecked = false;
  bool _ownershipDenied = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _poorIcon =
      'https://cdn-icons-png.flaticon.com/512/6637/6637186.png';
  static const String _averageIcon =
      'https://cdn-icons-png.flaticon.com/512/6637/6637207.png';
  static const String _greatIcon =
      'https://cdn-icons-png.flaticon.com/512/6637/6637168.png';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Details24QuizPageModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureOrderOwnership();
      if (mounted) safeSetState(() {});
    });
  }

  /// Rating is only for the customer who owns the order.
  Future<void> _ensureOrderOwnership() async {
    final orderRef = widget.idordeer;
    if (orderRef == null || currentUserUid.isEmpty) {
      _ownershipDenied = true;
      _ownershipChecked = true;
      if (mounted) context.safePop();
      return;
    }
    try {
      final snap = await orderRef.get();
      if (!snap.exists) {
        _ownershipDenied = true;
        _ownershipChecked = true;
        if (mounted) context.safePop();
        return;
      }
      final data = snap.data() as Map<String, dynamic>?;
      final ok = TouryCustomerCancelPolicy.isBookingOwner(
        userField: data?['USER'],
        authUid: currentUserUid,
        currentUserRef: currentUserReference,
      );
      _ownershipDenied = !ok;
      _ownershipChecked = true;
      if (!ok && mounted) {
        DsSnackBar.show(
          context,
          message: 'booking_permission_denied'.tr(),
          tone: DsSnackTone.error,
        );
        context.safePop();
      }
    } catch (_) {
      _ownershipDenied = true;
      _ownershipChecked = true;
      if (mounted) context.safePop();
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Business logic — unchanged behaviour, DS-styled surfaces only.
  // ---------------------------------------------------------------------------

  /// Submits the review then flags the order as rated — same call order as before.
  Future<void> _submitReview() async {
    if (_submitting) return;
    safeSetState(() => _submitting = true);
    try {
      await ReviewsUserRecord.collection.doc().set(createReviewsUserRecordData(
            revUser: widget.usermndob,
            rEVIEWSmsg: _model.textController.text,
            ret: _model.ratingBarValue?.round(),
            date: getCurrentTimestamp,
            userAlSend: currentUserReference,
            orderRev: widget.idordeer,
          ));

      if (mounted) {
        DsSnackBar.show(
          context,
          message: 'ui_text_e93e07976e'.tr(),
          tone: DsSnackTone.success,
        );
      }

      await widget.idordeer!.update(createOrderRecordData(
        revewSendClent: true,
      ));

      if (!mounted) return;
      context.safePop();
    } finally {
      if (mounted) safeSetState(() => _submitting = false);
    }
  }

  /// Slider is a 0-3 range with two divisions, so each mood owns one third.
  int get _selectedMood {
    final value = _model.sliderValue ?? 1.5;
    if (value <= 0.75) return 0;
    if (value >= 2.25) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_ownershipChecked || _ownershipDenied) {
      return DsScreenScaffold(
        scaffoldKey: scaffoldKey,
        appBar: DsAppBar(
          automaticallyImplyLeading: true,
          title: 'rating_driver_title'.tr(namedArgs: {
            'driver': widget.naimMndob ?? '',
          }),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: 'rating_driver_title'.tr(namedArgs: {
          'driver': widget.naimMndob ?? '',
        }),
        actions: [
          DsIconButton(
            icon: DsIcons.close,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () async {
              context.safePop();
            },
          ),
          const SizedBox(width: DsSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.xs,
            DsSpacing.md,
            DsSpacing.xxxl,
          ),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsFadeSlide(child: _buildIntro(context)),
              const SizedBox(height: DsSpacing.lg),
              DsFadeSlide(
                delay: DsDurations.fast,
                child: _buildMoodCard(context),
              ),
              const SizedBox(height: DsSpacing.md),
              DsFadeSlide(
                delay: DsDurations.normal,
                child: _buildRatingCard(context),
              ),
              const SizedBox(height: DsSpacing.md),
              DsFadeSlide(
                delay: DsDurations.slow,
                child: _buildReviewCard(context),
              ),
              const SizedBox(height: DsSpacing.xxl),
              DsFadeSlide(
                delay: DsDurations.slow,
                child: DsButton.primary(
                  expanded: true,
                  size: DsButtonSize.lg,
                  icon: Icons.send_rounded,
                  label: FFLocalizations.of(context).getText(
                    'fxd4nmkl' /* send the rating */,
                  ),
                  loading: _submitting,
                  enabled: !_submitting,
                  onPressed: _submitReview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FFLocalizations.of(context).getText(
            'aajxw3mu' /* what do you think of this tour... */,
          ),
          style: typography.displaySmall.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          FFLocalizations.of(context).getText(
            '56lflpxo' /* On a scale of 1 - 3 how are yo... */,
          ),
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMoodCard(BuildContext context) {
    final colors = context.dsColors;
    final selected = _selectedMood;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoodOption(
                imageUrl: _poorIcon,
                label: FFLocalizations.of(context).getText(
                  '219qn2n5' /* Poor  */,
                ),
                selected: selected == 0,
                onTap: () => safeSetState(() => _model.sliderValue = 0.0),
              ),
              _MoodOption(
                imageUrl: _averageIcon,
                label: FFLocalizations.of(context).getText(
                  'rhk8t4wu' /* Average */,
                ),
                selected: selected == 1,
                onTap: () => safeSetState(() => _model.sliderValue = 1.5),
              ),
              _MoodOption(
                imageUrl: _greatIcon,
                label: FFLocalizations.of(context).getText(
                  'aq9ybgpl' /* ممتازة */,
                ),
                selected: selected == 2,
                onTap: () => safeSetState(() => _model.sliderValue = 3.0),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.border,
              thumbColor: colors.primary,
              overlayColor: colors.primary.withValues(alpha: 0.14),
              activeTickMarkColor: colors.onPrimary,
              inactiveTickMarkColor: colors.iconMuted,
              trackHeight: 5,
            ),
            child: Slider(
              min: 0.0,
              max: 3.0,
              value: _model.sliderValue ??= 1.5,
              divisions: 2,
              onChanged: (newValue) {
                safeSetState(() => _model.sliderValue = newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              '1acrk2p0' /* ماهو تقييمك للمندوب  */,
            ),
            textAlign: TextAlign.center,
            style: typography.titleMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            'rating_driver_question'.tr(namedArgs: {
              'driver': widget.naimMndob ?? '',
            }),
            textAlign: TextAlign.center,
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Align(
            child: RatingBar.builder(
              onRatingUpdate: (newValue) =>
                  safeSetState(() => _model.ratingBarValue = newValue),
              itemBuilder: (context, index) => Icon(
                Icons.star_rounded,
                color: colors.warning,
              ),
              direction: Axis.horizontal,
              initialRating: _model.ratingBarValue ??= 3.0,
              unratedColor: colors.border,
              itemCount: 5,
              itemSize: DsIcons.xl,
              glowColor: colors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              '3uxbhzby' /* Review */,
            ),
            style: typography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.xs),
          DsTextField(
            controller: _model.textController,
            focusNode: _model.textFieldFocusNode,
            label: FFLocalizations.of(context).getText(
              'zw2w2ljz' /* Leave a comment (optional) */,
            ),
            hint: FFLocalizations.of(context).getText(
              'vp4ryyza' /* TextField */,
            ),
            maxLines: 3,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            variant: DsFieldVariant.filled,
          ),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.imageUrl,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String imageUrl;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DsDurations.fast,
        curve: DsCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.sm,
          vertical: DsSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : Colors.transparent,
          borderRadius: DsRadius.large,
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 0.92,
              duration: DsDurations.fast,
              curve: DsCurves.emphasized,
              child: TouryNetworkImage(
                url: imageUrl,
                width: DsConstants.avatarLg,
                height: DsConstants.avatarLg,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: DsSpacing.xxs),
            Text(
              label,
              style: typography.labelMedium.copyWith(
                color: selected ? colors.primaryStrong : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
