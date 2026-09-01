import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Fail-closed UI when canonical V2 finance totals are unavailable.
class AdminFinanceCanonicalUnavailablePanel extends StatelessWidget {
  const AdminFinanceCanonicalUnavailablePanel({
    super.key,
    required this.onRetry,
    this.compact = false,
  });

  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: theme.error, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  uiTr(
                    context,
                    'تعذر تحميل البيانات المحاسبية الموثوقة حاليًا.',
                  ),
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            uiTr(context, 'يرجى إعادة المحاولة.'),
            style: theme.bodyMedium,
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              uiTr(context, 'مصدر البيانات المحاسبي غير متاح'),
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AdminPrimaryButton(
              label: uiTr(context, 'إعادة المحاولة'),
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty KPI placeholder — not zero, not a fake total.
class AdminFinanceUnavailableValue extends StatelessWidget {
  const AdminFinanceUnavailableValue({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      uiTr(context, 'غير متاح'),
      style: FlutterFlowTheme.of(context).titleMedium.override(
            fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
            color: FlutterFlowTheme.of(context).secondaryText,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !FlutterFlowTheme.of(context).titleMediumIsCustom,
          ),
    );
  }
}
