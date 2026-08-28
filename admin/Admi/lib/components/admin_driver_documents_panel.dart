import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/admin_driver_document_access.dart';
import '/core/admin_driver_profile_view.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Documents section for Driver Details / Review with per-document actions.
///
/// V2 docs resolve via authenticated Storage SDK ([storagePath] SoT).
/// Review mutations go through [CloudFunctionsClient.reviewDriverDocument].
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
                'مراجعة وثيقة بوثيقة — الاعتماد / طلب استبدال / رفض مع سبب',
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

class _DocRow extends StatefulWidget {
  const _DocRow({
    required this.user,
    required this.slot,
    required this.scopeOk,
  });

  final UserRecord user;
  final AdminDriverDocumentSlot slot;
  final bool scopeOk;

  @override
  State<_DocRow> createState() => _DocRowState();
}

class _DocRowState extends State<_DocRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final slot = widget.slot;
    final presenceLabel = switch (slot.presence) {
      AdminDriverDocPresence.present => uiTr(context, 'متوفرة'),
      AdminDriverDocPresence.missing => uiTr(context, 'ناقصة'),
      AdminDriverDocPresence.legacy => uiTr(
          context,
          AdminDriverDocumentAccess.legacyAccessLabel,
        ),
    };
    final reviewLabel = slot.reviewStatus.isEmpty
        ? uiTr(context, 'بانتظار المراجعة')
        : slot.reviewStatus;
    final expiryLabel = slot.expiryDate == null
        ? '—'
        : dateTimeFormat('yMMMd', slot.expiryDate);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      '$presenceLabel · $reviewLabel',
                      style: theme.labelSmall,
                    ),
                    if (slot.uploadedAt != null)
                      Text(
                        '${uiTr(context, 'تاريخ الرفع')}: '
                        '${dateTimeFormat('yMMMd', slot.uploadedAt)}',
                        style: theme.labelSmall,
                      ),
                    Text(
                      '${uiTr(context, 'تاريخ الانتهاء')}: $expiryLabel',
                      style: theme.labelSmall,
                    ),
                    if (slot.reviewReason.isNotEmpty)
                      Text(
                        '${uiTr(context, 'السبب')}: ${slot.reviewReason}',
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.error,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                  ],
                ),
              ),
              if (slot.canView && widget.scopeOk)
                TextButton(
                  onPressed: _busy ? null : () => _openSecureViewer(context),
                  child: Text(uiTr(context, 'عرض')),
                ),
            ],
          ),
          if (widget.scopeOk && slot.isReviewable) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _review(context, action: 'approve'),
                  child: Text(uiTr(context, 'اعتماد الوثيقة')),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _review(
                            context,
                            action: 'request_replacement',
                            reasonRequired: true,
                          ),
                  child: Text(uiTr(context, 'طلب استبدال')),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _review(
                            context,
                            action: 'reject',
                            reasonRequired: true,
                          ),
                  child: Text(uiTr(context, 'رفض الوثيقة')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context, {
    required String action,
    bool reasonRequired = false,
  }) async {
    var reason = '';
    if (reasonRequired) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(uiTr(ctx, 'سبب المراجعة')),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: uiTr(ctx, 'مثال: الصورة غير واضحة'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(uiTr(ctx, 'إلغاء')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(uiTr(ctx, 'تأكيد')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = ctrl.text.trim();
      if (reason.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'السبب مطلوب'))),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await CloudFunctionsClient.reviewDriverDocument(
        driverId: widget.user.uid.isNotEmpty
            ? widget.user.uid
            : widget.user.reference.id,
        documentType: widget.slot.reviewDocumentType,
        action: action,
        reason: reason,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم حفظ مراجعة الوثيقة'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${uiTr(context, 'فشل')}: ${AdminUserFacingErrors.from(context, e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSecureViewer(BuildContext context) async {
    final url = await AdminDriverDocumentAccess.resolveViewUrl(
      driver: widget.user,
      storagePath: widget.slot.storagePath,
      legacyHttpsUrl: widget.slot.legacyUrl,
    );
    if (!context.mounted) return;
    if (url == null || url.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(uiTr(ctx, 'Error')),
          content: Text(uiTr(ctx, 'تعذر فتح الوثيقة')),
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

    final lower = url.toLowerCase();
    final isPdf = lower.contains('.pdf') || lower.contains('application/pdf');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            AdminDriverProfileView.docKindLabel(ctx, widget.slot.kind),
            softWrap: true,
          ),
          content: SizedBox(
            width: 420,
            height: 420,
            child: isPdf
                ? Center(
                    child: SelectableText(
                      uiTr(
                        ctx,
                        'ملف PDF — افتح الرابط الموثّق أدناه للمعاينة',
                      ),
                    ),
                  )
                : InteractiveViewer(
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
            if (isPdf)
              TextButton(
                onPressed: () async {
                  await launchURL(url);
                },
                child: Text(uiTr(ctx, 'فتح PDF')),
              ),
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
