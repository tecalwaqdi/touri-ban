import 'package:flutter/material.dart';

import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_vehicle_type_editor.dart';
import '/core/admin_currency.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Responsive vehicle-type row: stacked card on narrow widths, no crushed text.
class AdminTypeCarListCard extends StatelessWidget {
  const AdminTypeCarListCard({
    super.key,
    required this.record,
    required this.onChanged,
  });

  final TypeCarRecord record;
  final VoidCallback onChanged;

  Widget _thumb(BuildContext context) {
    final placeholder = Container(
      width: 88,
      height: 66,
      color: FlutterFlowTheme.of(context).alternate,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 28,
      ),
    );
    final clean = record.img.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: clean.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: clean,
              width: 88,
              height: 66,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (context, _) => placeholder,
              errorWidget: (context, _, __) => placeholder,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final arName = record.namesI18n['ar'] ?? record.naim;
    final enName = record.namesI18n['en'] ?? '';
    final price = valueOrDefault<String>(
      formatNumber(
        record.sr,
        formatType: FormatType.decimal,
        decimalType: DecimalType.automatic,
        currency: AdminCurrency.asFormatPrefix(
          AdminCurrency.symbolForIso(record.countryIso2),
        ),
      ),
      uiTr(context, 'غير معرفة'),
    );
    final hoursLabel =
        '${record.aglSaat} ${uiTr(context, 'ساعات')} — ${uiTr(context, 'الحد الأدنى للطلب')}';
    final active = record.actev;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                      if (enName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          enName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            letterSpacing: 0,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                      ],
                      if (record.codeCar.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'code: ${record.codeCar}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: theme.secondaryText,
                            letterSpacing: 0,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (active ? theme.success : theme.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    active ? uiTr(context, 'مفعّل') : uiTr(context, 'موقوف'),
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: active ? theme.success : theme.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.payments_outlined,
                  label: '$price ${uiTr(context, 'للساعة الواحدة')}',
                  color: theme.error,
                ),
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: hoursLabel,
                  color: theme.secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FFButtonWidget(
                  onPressed: () async {
                    final changed =
                        await AdminVehicleTypeEditor.open(context, record);
                    if (changed == true) onChanged();
                  },
                  text: FFLocalizations.of(context).getText('i8wvudcy'),
                  options: FFButtonOptions(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: theme.success,
                    textStyle: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.info,
                      letterSpacing: 0,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FFButtonWidget(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(uiTr(context, 'حذف نوع السيارة')),
                        content: Text(
                          uiTr(
                            context,
                            'هل أنت متأكد من حذف هذا النوع؟ لا يمكن التراجع.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(uiTr(context, 'إلغاء')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(uiTr(context, 'حذف')),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !context.mounted) return;
                    try {
                      final docId = record.reference.id;
                      await AdminFirestoreDelete.deleteDocument(record.reference);
                      if (!context.mounted) return;
                      await AdminCrudFeedback.success(
                        context,
                        action: AdminCrudAction.delete,
                        message: uiTr(context, 'تم حذف نوع السيارة بنجاح'),
                        refreshScope: AdminListScope.typeCars,
                        removedDocumentId: docId,
                        invalidateStats: false,
                      );
                      onChanged();
                    } catch (e) {
                      if (!context.mounted) return;
                      AdminCrudFeedback.error(
                        context,
                        AdminCrudFeedback.deleteFailed(context, e),
                      );
                    }
                  },
                  text: uiTr(context, 'حذف'),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  options: FFButtonOptions(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: theme.error,
                    textStyle: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.info,
                      letterSpacing: 0,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FFButtonWidget(
                  onPressed: () async {
                    final next = !active;
                    await record.reference.update(
                      createTypeCarRecordData(actev: next),
                    );
                    await AdminAuditLog.recordToggle(
                      targetType: 'type_car',
                      targetId: record.reference.id,
                      activated: next,
                      targetLabel: record.naim,
                    );
                    onChanged();
                  },
                  text: active ? uiTr(context, 'إيقاف') : uiTr(context, 'تفعيل'),
                  options: FFButtonOptions(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: active ? theme.error : theme.tertiary,
                    textStyle: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.info,
                      letterSpacing: 0,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
      ],
    );
  }
}
