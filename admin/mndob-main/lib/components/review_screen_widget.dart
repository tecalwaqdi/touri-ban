import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'review_screen_model.dart';
export 'review_screen_model.dart';

/// شاشة تقييم العميل
class ReviewScreenWidget extends StatefulWidget {
  const ReviewScreenWidget({
    super.key,
    required this.revClent,
    this.imgUser,
    this.naim,
    required this.idOrder,
  });

  final DocumentReference? revClent;
  final String? imgUser;
  final String? naim;
  final DocumentReference? idOrder;

  @override
  State<ReviewScreenWidget> createState() => _ReviewScreenWidgetState();
}

class _ReviewScreenWidgetState extends State<ReviewScreenWidget> {
  late ReviewScreenModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewScreenModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: DsSpacing.pagePadding,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: DsRadius.pill,
                      border: Border.all(color: colors.primary, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: DsRadius.pill,
                      child: Image.network(
                        widget.imgUser!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  DsSpacing.gapSm,
                  Text(
                    valueOrDefault<String>(widget.naim, '- '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.headlineMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              DsSpacing.gapLg,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'lo233y80',
                    ),
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  DsSpacing.gapXs,
                  RatingBar.builder(
                    onRatingUpdate: (newValue) =>
                        safeSetState(() => _model.ratingBarValue = newValue),
                    itemBuilder: (context, index) => Icon(
                      Icons.stars,
                      color: colors.primary,
                    ),
                    direction: Axis.horizontal,
                    initialRating: _model.ratingBarValue ??= 5.0,
                    unratedColor: colors.primaryMuted,
                    itemCount: 5,
                    itemSize: 24,
                    glowColor: colors.primary,
                  ),
                ],
              ),
              DsSpacing.gapLg,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText('jrljt3nl'),
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  DsSpacing.gapXs,
                  DsTextField(
                    controller: _model.textController,
                    focusNode: _model.textFieldFocusNode,
                    hint: FFLocalizations.of(context).getText('bums683l'),
                    maxLines: 6,
                    minLines: 4,
                  ),
                ],
              ),
              DsSpacing.gapLg,
              DsButton.primary(
                label: FFLocalizations.of(context).getText('2o2dmbbp'),
                icon: Icons.auto_awesome_rounded,
                expanded: true,
                onPressed: () async {
                  final orderRef = widget.idOrder;
                  final clientRef = widget.revClent;
                  if (orderRef == null || clientRef == null) {
                    if (!context.mounted) return;
                    DsSnackBar.show(
                      context,
                      message: 'تعذر إرسال التقييم: بيانات ناقصة',
                      tone: DsSnackTone.error,
                    );
                    return;
                  }
                  await ReviewsUserRecord.collection
                      .doc()
                      .set(createReviewsUserRecordData(
                        revUser: clientRef,
                        rEVIEWSmsg: _model.textController.text,
                        ret: _model.ratingBarValue?.round(),
                        date: getCurrentTimestamp,
                        userAlSend: currentUserReference,
                        orderRev: orderRef,
                      ));
                  if (!context.mounted) return;
                  DsSnackBar.show(
                    context,
                    message: 'تم إرسال التقييم بنجاح',
                    tone: DsSnackTone.success,
                  );

                  await orderRef.update(createOrderRecordData(
                    reviewMndobsend: true,
                  ));

                  await clientRef.update({
                    ...mapToFirestore(
                      {
                        'Reteng': FieldValue.arrayUnion(
                            [_model.ratingBarValue?.round()]),
                      },
                    ),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(DsIcons.close, color: colors.primaryStrong),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
