import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'empty_state_simple_model.dart';
export 'empty_state_simple_model.dart';

class EmptyStateSimpleWidget extends StatefulWidget {
  const EmptyStateSimpleWidget({
    super.key,
    this.icon,
    String? title,
    String? body,
  })  : title = title ?? 'No Comments',
        body = body ?? 'There are no comments associated with this post.';

  final Widget? icon;
  final String title;
  final String body;

  @override
  State<EmptyStateSimpleWidget> createState() => _EmptyStateSimpleWidgetState();
}

class _EmptyStateSimpleWidgetState extends State<EmptyStateSimpleWidget> {
  late EmptyStateSimpleModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmptyStateSimpleModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      annotateSystemUi: false,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Align(
            alignment: const AlignmentDirectional(0.0, -1.0),
            child: DsFadeSlide(
              child: widget.icon == null
                  ? DsEmptyState(
                      title: widget.title,
                      message: widget.body,
                      icon: DsIcons.chat,
                    )
                  : Padding(
                      padding: DsSpacing.pagePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.icon!,
                          const SizedBox(height: DsSpacing.md),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: typography.titleLarge.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xs),
                          Text(
                            widget.body,
                            textAlign: TextAlign.center,
                            style: typography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
