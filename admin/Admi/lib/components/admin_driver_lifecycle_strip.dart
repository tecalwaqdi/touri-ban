import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Compact registration / docs / activation / expiry chips for driver surfaces.
class AdminDriverLifecycleStrip extends StatelessWidget {
  const AdminDriverLifecycleStrip({
    super.key,
    required this.user,
  });

  final UserRecord user;

  String _label(BuildContext context, String chip) {
    if (chip.startsWith('reg:')) {
      final raw = chip.substring(4);
      return '${uiTr(context, 'المراجعة')}: ${AdminDriverProfileView.reviewLabel(context, AdminDriverProfileView.reviewBucketFromRaw(raw))}';
    }
    if (chip.startsWith('docs:')) {
      final raw = chip.substring(5);
      final docsLabel = switch (raw) {
        'complete' => uiTr(context, 'مكتملة'),
        'missing' => uiTr(context, 'ناقصة'),
        'needs_reupload' => uiTr(context, 'تحتاج إعادة رفع'),
        'unknown_legacy' => uiTr(context, 'غير معروفة (Legacy)'),
        _ => raw,
      };
      return '${uiTr(context, 'الوثائق')}: $docsLabel';
    }
    if (chip == 'act:on') {
      return uiTr(context, 'مفعّل');
    }
    if (chip == 'act:off') {
      return uiTr(context, 'غير مفعّل');
    }
    if (chip.startsWith('exp:')) {
      final raw = chip.substring(4);
      final expLabel = switch (raw) {
        'expiring_soon' => uiTr(context, 'تنتهي قريبًا'),
        'expired' => uiTr(context, 'منتهية'),
        _ => raw,
      };
      return '${uiTr(context, 'انتهاء')}: $expLabel';
    }
    return chip;
  }

  Color _color(String chip) {
    if (chip.startsWith('reg:')) {
      final b = AdminDriverProfileView.reviewBucketFromRaw(chip.substring(4));
      return switch (b) {
        AdminDriverReviewBucket.approved => Colors.green.shade700,
        AdminDriverReviewBucket.pendingReview => Colors.orange.shade800,
        AdminDriverReviewBucket.rejected ||
        AdminDriverReviewBucket.suspended =>
          Colors.red.shade700,
        AdminDriverReviewBucket.needsChanges => Colors.deepOrange.shade700,
        _ => Colors.blueGrey,
      };
    }
    if (chip.startsWith('docs:')) {
      final raw = chip.substring(5);
      if (raw == 'complete') return Colors.green.shade700;
      if (raw == 'missing' || raw == 'needs_reupload') {
        return Colors.orange.shade800;
      }
      return Colors.blueGrey;
    }
    if (chip == 'act:on') return Colors.green.shade700;
    if (chip == 'act:off') return Colors.blueGrey;
    if (chip == 'exp:expired') return Colors.red.shade700;
    if (chip == 'exp:expiring_soon') return Colors.deepOrange.shade700;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final chips = AdminDriverProfileView.lifecycleChips(user);
    return Semantics(
      identifier: 'qa-driver-lifecycle-strip',
      label: chips.join('|'),
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in chips)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _color(c).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _color(c).withValues(alpha: 0.35)),
                ),
                child: Text(
                  _label(context, c),
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    fontWeight: FontWeight.w700,
                    color: _color(c),
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
