import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_document_access.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only documents section for Driver Details / Review.
///
/// V2 docs resolve via authenticated Storage SDK ([storagePath] SoT).
/// Legacy HTTPS URLs labeled internally as LEGACY_DOCUMENT_ACCESS.
class AdminDriverDocumentsPanel extends StatelessWidget {
  const AdminDriverDocumentsPanel({
    super.key,
    required this.user,
  });

  final UserRecord user;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final docs = AdminDriverProfileView.documents(user);
    final authStatus =
        AdminDriverProfileView.authoritativeDocumentsStatus(user);
    final complete = authStatus == 'complete' ||
        (authStatus.isEmpty &&
            AdminDriverProfileView.documentsComplete(user));
    final scopeOk = AdminDriverDocumentAccess.canAccessDriverDocuments(user);
    final statusLabel = switch (authStatus) {
      'complete' => uiTr(context, 'مكتملة'),
      'missing' => uiTr(context, 'ناقصة'),
      'needs_reupload' => uiTr(context, 'تحتاج إعادة رفع'),
      'unknown_legacy' => uiTr(context, 'غير معروفة (Legacy)'),
      _ => complete
          ? uiTr(context, 'مكتملة')
          : uiTr(context, 'ناقصة / Legacy'),
    };

    return AdminContentCard(
      padding: const EdgeInsets.all(14),
      child: Semantics(
        identifier: 'qa-driver-documents',
        label: 'qa-driver-documents',
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  uiTr(context, 'الوثائق'),
                  softWrap: true,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (complete ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ),
            ],
          ),
          if (!scopeOk) ...[
            const SizedBox(height: 8),
            Text(
              uiTr(context, 'Document access denied for your admin scope.'),
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.error,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            uiTr(
              context,
              'Personal · Driver · Vehicle documents (no expiry invented)',
            ),
            softWrap: true,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
          const SizedBox(height: 12),
          for (final d in docs) ...[
            _DocRow(user: user, slot: d, scopeOk: scopeOk),
            const SizedBox(height: 8),
          ],
        ],
      ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.user,
    required this.slot,
    required this.scopeOk,
  });

  final UserRecord user;
  final AdminDriverDocumentSlot slot;
  final bool scopeOk;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final presenceLabel = switch (slot.presence) {
      AdminDriverDocPresence.present => uiTr(context, 'متوفرة'),
      AdminDriverDocPresence.missing => uiTr(context, 'ناقصة'),
      AdminDriverDocPresence.legacy => uiTr(
          context,
          AdminDriverDocumentAccess.legacyAccessLabel,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            slot.accessMode != AdminDriverDocAccessMode.missing
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: slot.accessMode != AdminDriverDocAccessMode.missing
                ? Colors.green.shade700
                : theme.secondaryText,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AdminDriverProfileView.docKindLabel(context, slot.kind),
                  softWrap: true,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                Text(
                  presenceLabel,
                  style: theme.labelSmall,
                ),
              ],
            ),
          ),
          if (slot.canView && scopeOk)
            TextButton(
              onPressed: () => _openSecureViewer(context),
              child: Text(uiTr(context, 'عرض')),
            ),
        ],
      ),
    );
  }

  Future<void> _openSecureViewer(BuildContext context) async {
    final url = await AdminDriverDocumentAccess.resolveViewUrl(
      driver: user,
      storagePath: slot.storagePath,
      legacyHttpsUrl: slot.legacyUrl,
    );
    if (!context.mounted) return;
    if (url == null || url.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(uiTr(ctx, 'Error')),
          content: Text(uiTr(ctx, 'تعذر عرض الوثيقة')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(uiTr(ctx, 'إغلاق')),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            AdminDriverProfileView.docKindLabel(ctx, slot.kind),
            softWrap: true,
          ),
          content: SizedBox(
            width: 420,
            height: 420,
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(uiTr(ctx, 'تعذر عرض الوثيقة')),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(uiTr(ctx, 'إغلاق')),
            ),
          ],
        );
      },
    );
  }
}
