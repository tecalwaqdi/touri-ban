import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_legacy_alias_filter.dart';
import '/backend/backend.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'adminregion_model.dart';
export 'adminregion_model.dart';

class AdminregionWidget extends StatefulWidget {
  const AdminregionWidget({super.key});

  static String routeName = 'Adminregion';
  static String routePath = '/adminregion';

  @override
  State<AdminregionWidget> createState() => _AdminregionWidgetState();
}

class _AdminregionWidgetState extends State<AdminregionWidget> {
  late AdminregionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminregionModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<CitiesRecord> _filterRegions(List<CitiesRecord> items) {
    final visible = AdminLegacyAliasFilter.keepWhereId(
      items,
      (r) => r.reference.id,
    );
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return visible;
    return visible.where((r) {
      return r.naim.toLowerCase().contains(q) ||
          r.osf.toLowerCase().contains(q);
    }).toList();
  }

  void _editRegion(CitiesRecord record) {
    context.pushNamed(
      EdetRegWidget.routeName,
      queryParameters: {
        'idreg': serializeParam(
          record.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _deleteRegion(CitiesRecord record) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: appTr(context, 'adm_delete_confirm_title'),
      whatHappens: uiTr(
        context,
        'Deleting this region removes linked landmarks. This may break historical order references.',
      ),
      subject: record.naim.isNotEmpty ? record.naim : record.reference.id,
      impact: uiTr(context, 'Cascade delete on region and landmarks.'),
      destructive: true,
      irreversible: true,
      confirmLabel: appTr(context, 'adm_yes_delete'),
      cancelLabel: appTr(context, 'adm_no'),
    );

    if (!confirmed) return;

    try {
      await AdminCrudFeedback.runWithBlockingProgress(
        context: context,
        message: uiTr(context, 'جاري الحذف… لا تغلق التطبيق'),
        action: () => deleteRegionCascade(record.reference),
      );
      await AdminAuditLog.recordDelete(
        targetType: 'region',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف المنطقة وكل البيانات المرتبطة'),
        refreshScope: AdminListScope.regions,
        removedDocumentId: record.reference.id,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    }
  }

  Future<void> _toggleActive(CitiesRecord record, bool activate) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: activate
          ? uiTr(context, 'تأكيد التنشيط')
          : uiTr(context, 'تأكيد إخفاء المنطقة'),
      whatHappens: activate
          ? uiTr(
              context,
              'عند تنشيط هذه المنطقة سيتم إظهار كل المعالم المرتبطة. هل أنت متأكد؟',
            )
          : uiTr(
              context,
              'عند إخفاء هذه المنطقة سيتم إخفاء كل المعالم المرتبطة. هل أنت متأكد؟',
            ),
      subject: record.naim.isNotEmpty ? record.naim : record.reference.id,
      impact: uiTr(context, 'Visibility change for region and landmarks.'),
      destructive: !activate,
      confirmLabel:
          activate ? uiTr(context, 'نعم، فعّل') : uiTr(context, 'نعم، أخفِ'),
      cancelLabel: appTr(context, 'adm_no'),
    );

    if (!confirmed) return;

    try {
      await record.reference.update(
        createCitiesRecordData(acctev: activate),
      );
      await setRegionLandmarksActive(record.reference, activate);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activate ? uiTr(context, 'تم تنشيط المنطقة والمعالم') : uiTr(context, 'تم إخفاء المنطقة والمعالم')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: l10n.getText('epnbxa8s'),
        child: AdminPageBody(
          title: l10n.getText('epnbxa8s'),
          subtitle: appTr(context, 'scr_regions_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                              children: [
                          Expanded(child: _buildSearch()),
                          const SizedBox(width: 12),
                          _buildAddButton(l10n),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearch(),
                          const SizedBox(height: 12),
                          _buildAddButton(l10n),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<CitiesRecord>(
                refreshScope: AdminListScope.regions,
                query: CitiesRecord.collection,
                recordBuilder: CitiesRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminCountryScope.applyRegionQuery(q).orderBy('naim'),
                builder: (context, allRegions, listState) {
                  final regions = _filterRegions(allRegions);

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            adminListCountLabel(context, listState, visibleCount: regions.length, pageFetched: allRegions.length),
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                                    ),
                                  ),
                                ),
                        if (regions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                Icon(
                                  Icons.filter_hdr_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                                                  Text(
                                  _searchQuery.isEmpty
                                      ? uiTr(context, 'لا توجد مناطق مسجلة')
                                      : uiTr(context, 'لا توجد نتائج للبحث'),
                                  style: theme.titleMedium,
                                                                    ),
                                                                ],
                                                              ),
                          )
                        else if (isWide)
                          _RegionsGrid(
                            regions: regions,
                            onEdit: _editRegion,
                            onDelete: _deleteRegion,
                            onToggleActive: _toggleActive,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: regions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _RegionCard(
                              record: regions[index],
                              onEdit: () => _editRegion(regions[index]),
                              onDelete: () => _deleteRegion(regions[index]),
                              onToggleActive: (active) =>
                                  _toggleActive(regions[index], active),
                            ),
                          ),
                        AdminListLoadMoreFooter(state: listState),
                      ],
                    ),
                                                                    );
                                                                  },
                                                                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admin_region_search',
        const Duration(milliseconds: 300),
        () {
          if (mounted) {
            setState(() {
              _searchQuery = _model.textController?.text ?? '';
            });
                                                                    }
                                                                  },
                                                                ),
      decoration: AdminUi.inputDecoration(
                                                                                context,
        label: uiTr(context, 'بحث'),
        hint: uiTr(context, 'ابحث باسم المنطقة أو الوصف...'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('fo5l0uyc'),
      icon: Icons.add_rounded,
      onPressed: () => context.pushNamed(AddRegWidget.routeName),
    );
  }
}

class _RegionsGrid extends StatelessWidget {
  const _RegionsGrid({
    required this.regions,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final List<CitiesRecord> regions;
  final void Function(CitiesRecord) onEdit;
  final Future<void> Function(CitiesRecord) onDelete;
  final Future<void> Function(CitiesRecord, bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final region in regions)
              SizedBox(
                width: itemWidth,
                child: _RegionCard(
                  record: region,
                  onEdit: () => onEdit(region),
                  onDelete: () => onDelete(region),
                  onToggleActive: (active) => onToggleActive(region, active),
                ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final CitiesRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(bool activate) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      padding: const EdgeInsets.all(14),
                                                      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
          _RegionImage(url: record.img),
          const SizedBox(width: 14),
                                                          Expanded(
                                                            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                  record.naim.isNotEmpty ? record.naim : '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.brandTeal,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
                if (record.osf.isNotEmpty) ...[
                  const SizedBox(height: 4),
                                                                Text(
                    record.osf,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _StatusBadge(active: record.acctev),
                                                              ],
                                                            ),
                                                          ),
          Column(
                                                            children: [
                                                              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 36,
                fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AdminUi.brandTeal,
                  size: 18,
                ),
                onPressed: onEdit,
              ),
              const SizedBox(height: 6),
              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 36,
                fillColor: record.acctev
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                                                                icon: Icon(
                  record.acctev ? Icons.visibility_off_rounded : Icons.check_rounded,
                  color: record.acctev
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E7D32),
                  size: 18,
                ),
                onPressed: () => onToggleActive(!record.acctev),
              ),
              const SizedBox(height: 6),
                                                              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 36,
                fillColor: const Color(0xFFFFEBEE),
                                                                icon: Icon(
                  Icons.delete_rounded,
                  color: theme.error,
                  size: 18,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionImage extends StatelessWidget {
  const _RegionImage({required this.url});

  final String url;

  static const double size = 64;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminUi.brandTeal.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
      clipBehavior: Clip.antiAlias,
      child: AdminRecordThumbnail(
        imageUrl: url,
        width: size,
        height: size,
        fallback: const _ImageFallback(icon: Icons.filter_hdr_rounded),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminUi.brandTeal.withValues(alpha: 0.08),
      child: Center(
        child: Icon(icon, color: AdminUi.brandTeal, size: 28),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        active ? uiTr(context, 'نشطة') : uiTr(context, 'غير نشطة'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: active ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}
