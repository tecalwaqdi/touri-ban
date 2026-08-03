import '/backend/admin_country_scope.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/backend.dart';
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
import 'adminvill_model.dart';
export 'adminvill_model.dart';

class AdminvillWidget extends StatefulWidget {
  const AdminvillWidget({super.key});

  static String routeName = 'Adminvill';
  static String routePath = '/adminvill';

  @override
  State<AdminvillWidget> createState() => _AdminvillWidgetState();
}

class _AdminvillWidgetState extends State<AdminvillWidget> {
  late AdminvillModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminvillModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<VillagesRecord> _filterCities(List<VillagesRecord> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) {
      return c.naim.toLowerCase().contains(q) ||
          c.osf.toLowerCase().contains(q);
    }).toList();
  }

  void _editCity(VillagesRecord record) {
    context.pushNamed(
      EdetVillWidget.routeName,
      queryParameters: {
        'idvill': serializeParam(
          record.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _deleteCity(VillagesRecord record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: Text(
              'هل أنت متأكد من حذف "${record.naim}"؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(appTr(context, 'adm_yes_delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await deleteCityCascade(record.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'city',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف المدينة والمعالم المرتبطة'),
        refreshScope: AdminListScope.cities,
        removedDocumentId: record.reference.id,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    }
  }

  Future<void> _toggleActive(VillagesRecord record, bool activate) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(activate ? 'تأكيد التنشيط' : 'تأكيد إيقاف التنشيط'),
            content: Text(
              activate
                  ? 'هل أنت متأكد من تنشيط "${record.naim}"؟'
                  : 'هل أنت متأكد من إيقاف تنشيط "${record.naim}"؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(activate ? 'نعم، فعّل' : 'نعم، أوقف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await record.reference.update(
        createVillagesRecordData(acctev: activate),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              activate ? 'تم تنشيط المدينة' : 'تم إيقاف تنشيط المدينة'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_update_city_status_failed')}: $e')),
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
        title: l10n.getText('vrkkakqc'),
        child: AdminPageBody(
          title: l10n.getText('rfnq2sy2'),
          subtitle: appTr(context, 'scr_cities_subtitle'),
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
              AdminFirestoreList<VillagesRecord>(
                refreshScope: AdminListScope.cities,
                query: VillagesRecord.collection,
                recordBuilder: VillagesRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminCountryScope.applyVillageQuery(q).orderBy('naim'),
                builder: (context, allCities, listState) {
                  final cities = _filterCities(allCities);

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            'العدد: ${cities.length}'
                            '${allCities.length != cities.length ? ' من ${allCities.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                                            ),
                                          ),
                                        ),
                        if (cities.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                                      child: Column(
                                        children: [
                                Icon(
                                  Icons.location_city_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                                Text(
                                  _searchQuery.isEmpty
                                      ? 'لا توجد مدن مسجلة'
                                      : 'لا توجد نتائج للبحث',
                                  style: theme.titleMedium,
                                                ),
                                              ],
                                            ),
                          )
                        else if (isWide)
                          _CitiesGrid(
                            cities: cities,
                            onEdit: _editCity,
                            onDelete: _deleteCity,
                            onToggleActive: _toggleActive,
                          )
                        else
                          ListView.separated(
                                                      shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cities.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _CityCard(
                              record: cities[index],
                              onEdit: () => _editCity(cities[index]),
                              onDelete: () => _deleteCity(cities[index]),
                              onToggleActive: (active) =>
                                  _toggleActive(cities[index], active),
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
        '_admin_vill_search',
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
        hint: 'ابحث باسم المدينة أو الوصف...',
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('xeo24ydc'),
      icon: Icons.add_rounded,
      onPressed: () => context.pushNamed(AddVillWidget.routeName),
    );
  }
}

class _CitiesGrid extends StatelessWidget {
  const _CitiesGrid({
    required this.cities,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final List<VillagesRecord> cities;
  final void Function(VillagesRecord) onEdit;
  final Future<void> Function(VillagesRecord) onDelete;
  final Future<void> Function(VillagesRecord, bool) onToggleActive;

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
            for (final city in cities)
              SizedBox(
                width: itemWidth,
                child: _CityCard(
                  record: city,
                  onEdit: () => onEdit(city),
                  onDelete: () => onDelete(city),
                  onToggleActive: (active) => onToggleActive(city, active),
                ),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final VillagesRecord record;
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
          _CityImage(url: record.img),
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
                  record.acctev ? Icons.stop_circle_rounded : Icons.check_rounded,
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

class _CityImage extends StatelessWidget {
  const _CityImage({required this.url});

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
        fallback: const _ImageFallback(icon: Icons.location_city_rounded),
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
        active ? 'نشطة' : 'غير نشطة',
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
