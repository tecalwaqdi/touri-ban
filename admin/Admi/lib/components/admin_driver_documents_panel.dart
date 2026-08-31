import '/backend/admin_media_resolver.dart';
import '/backend/backend.dart';
import '/components/admin_driver_lifecycle_strip.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_document_access.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Read-only documents section for Driver Details / Review.
///
/// V2 docs resolve via authenticated Storage SDK ([storagePath] SoT).
/// Bytes are preferred over download URLs so Flutter Web works without CORS.
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
    final complete = AdminDriverProfileView.documentsComplete(user);
    final scopeOk = AdminDriverDocumentAccess.canAccessDriverDocuments(user);
    final statusLabel = switch (authStatus) {
      'complete' => uiTr(context, 'مكتملة'),
      'missing' => uiTr(context, 'ناقصة'),
      'needs_reupload' => uiTr(context, 'تحتاج إعادة رفع'),
      'unknown_legacy' => uiTr(context, 'غير معروفة (Legacy)'),
      _ => complete
          ? uiTr(context, 'مكتملة')
          : uiTr(context, 'ناقصة'),
    };

    return AdminContentCard(
      padding: const EdgeInsets.all(14),
      child: Semantics(
        identifier: 'qa-driver-documents',
        label: 'qa-driver-documents',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDriverLifecycleStrip(user: user),
            const SizedBox(height: 12),
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
            if (authStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${uiTr(context, 'حالة النظام')}: $authStatus',
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
            ],
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
    final present = slot.presence != AdminDriverDocPresence.missing;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            present
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: present ? Colors.green.shade700 : theme.secondaryText,
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
                if (slot.expiryDate != null)
                  Text(
                    slot.isExpired
                        ? '${uiTr(context, 'منتهية')}: ${dateTimeFormat('yMMMd', slot.expiryDate)}'
                        : slot.isExpiringSoon
                            ? '${uiTr(context, 'تنتهي قريبًا')}: ${dateTimeFormat('yMMMd', slot.expiryDate)}'
                            : '${uiTr(context, 'تنتهي')}: ${dateTimeFormat('yMMMd', slot.expiryDate)}',
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: slot.isExpired
                          ? Colors.red.shade700
                          : slot.isExpiringSoon
                              ? Colors.deepOrange.shade700
                              : theme.secondaryText,
                      fontWeight: (slot.isExpired || slot.isExpiringSoon)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
    );

    final result = await AdminDriverDocumentAccess.resolveView(
      driver: user,
      storagePath: slot.storagePath,
      legacyHttpsUrl: slot.legacyUrl,
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // loading

    if (!result.ok) {
      await _showError(context, result);
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
            width: 480,
            height: 480,
            child: _buildPreview(ctx, result),
          ),
          actions: [
            if (result.url != null && result.url!.startsWith('https://'))
              TextButton(
                onPressed: () async {
                  final uri = Uri.tryParse(result.url!);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(uiTr(ctx, 'فتح الرابط')),
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

  Widget _buildPreview(BuildContext context, AdminDriverDocViewResult result) {
    if (result.isPdf) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                uiTr(context, 'ملف PDF — استخدم فتح الرابط إن وُجد'),
                textAlign: TextAlign.center,
              ),
              if (result.errorDetail != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.userMessageAr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (result.bytes != null && result.bytes!.isNotEmpty) {
      return InteractiveViewer(
        child: Image.memory(
          result.bytes!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(uiTr(context, 'تعذر فك صورة الوثيقة')),
          ),
        ),
      );
    }

    final url = result.url ?? '';
    if (url.isEmpty) {
      return Center(child: Text(result.userMessageAr));
    }

    // Prefer Auth SDK bytes over anonymous HTTPS (avoids CORS / 403 noise).
    return FutureBuilder<AdminMediaResolved>(
      future: AdminMediaResolver.resolve(url),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final resolved = snap.data;
        if (resolved != null && resolved.hasBytes) {
          return InteractiveViewer(
            child: Image.memory(
              resolved.bytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(uiTr(context, 'تعذر فك صورة الوثيقة')),
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              uiTr(
                context,
                'تعذر تحميل الصورة. استخدم فتح الرابط إن وُجد.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showError(
    BuildContext context,
    AdminDriverDocViewResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AdminDriverProfileView.docKindLabel(ctx, slot.kind),
          softWrap: true,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(result.userMessageAr),
            if ((result.errorDetail ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                result.errorDetail!,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
            if (slot.storagePath.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                slot.storagePath,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if ((result.errorDetail ?? '').isNotEmpty ||
              slot.storagePath.isNotEmpty)
            TextButton(
              onPressed: () async {
                final buf = StringBuffer(result.userMessageAr);
                if ((result.errorDetail ?? '').isNotEmpty) {
                  buf.writeln();
                  buf.write(result.errorDetail);
                }
                if (slot.storagePath.isNotEmpty) {
                  buf.writeln();
                  buf.write(slot.storagePath);
                }
                await Clipboard.setData(ClipboardData(text: buf.toString()));
              },
              child: Text(uiTr(ctx, 'نسخ التفاصيل')),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(uiTr(ctx, 'إغلاق')),
          ),
        ],
      ),
    );
  }
}
