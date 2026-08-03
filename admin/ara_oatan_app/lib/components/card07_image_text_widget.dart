import '/backend/backend.dart';
import '/core/toury_mkan_i18n.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'card07_image_text_model.dart';
export 'card07_image_text_model.dart';

class Card07ImageTextWidget extends StatefulWidget {
  const Card07ImageTextWidget({
    super.key,
    required this.idmkan,
  });

  final MkanRecord? idmkan;

  @override
  State<Card07ImageTextWidget> createState() => _Card07ImageTextWidgetState();
}

class _Card07ImageTextWidgetState extends State<Card07ImageTextWidget> {
  late Card07ImageTextModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Card07ImageTextModel());

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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.sm),
      child: DsCard(
        elevated: true,
        bordered: false,
        padding: const EdgeInsets.all(DsSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ClipRRect(
              borderRadius: DsRadius.small,
              child: TouryNetworkImage(
                url: widget.idmkan!.img1,
                width: double.infinity,
                height: 100.0,
                fit: BoxFit.cover,
                placeName: widget.idmkan == null
                    ? null
                    : touryMkanName(context, widget.idmkan!),
                fallbackAsset: kTouryImageFallback,
                useBrandedFallback: true,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  0.0, DsSpacing.xs, 0.0, DsSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(
                        widget.idmkan == null
                            ? null
                            : touryMkanName(context, widget.idmkan!),
                        '0',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: typography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Text(
                    valueOrDefault<String>(
                      widget.idmkan == null
                          ? null
                          : touryMkanDescription(context, widget.idmkan!),
                      '-',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: typography.labelMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
