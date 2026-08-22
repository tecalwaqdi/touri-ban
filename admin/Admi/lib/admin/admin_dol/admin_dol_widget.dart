import '/backend/admin_audit_log.dart';
import '/backend/backend.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_dol_model.dart';
export 'admin_dol_model.dart';

class AdminDolWidget extends StatefulWidget {
  const AdminDolWidget({super.key});

  static String routeName = 'AdminDol';
  static String routePath = '/adminDol';

  @override
  State<AdminDolWidget> createState() => _AdminDolWidgetState();
}

class _AdminDolWidgetState extends State<AdminDolWidget> {
  late AdminDolModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminDolModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<CountriesRecord> _filterCountries(List<CountriesRecord> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) {
      return c.naim.toLowerCase().contains(q) ||
          c.osf.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteCountry(CountriesRecord record) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: appTr(context, 'adm_delete_confirm_title'),
      whatHappens: uiTr(
        context,
        'Soft-disable this country (acctev=false). Related data is preserved.',
      ),
      subject: record.naim.isNotEmpty ? record.naim : record.reference.id,
      impact: uiTr(context, 'Country hidden from active lists; not cascade-deleted'),
      confirmLabel: uiTr(context, 'تعطيل الدولة'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: true,
      irreversible: false,
      reference: record.reference.id,
    );

    if (!confirmed) return;

    try {
      await record.reference.update(createCountriesRecordData(acctev: false));
      await AdminAuditLog.recordToggle(
        targetType: 'country',
        targetId: record.reference.id,
        targetLabel: record.naim,
        activated: false,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تعطيل الدولة (حذف ناعم)'),
        refreshScope: AdminListScope.countries,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  void _editCountry(CountriesRecord record) {
    context.pushNamed(
      EdetDolhWidget.routeName,
      queryParameters: {
        'iddolhe': serializeParam(
          record.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    if (!AdminSuperAdminGate.isAllowed) {
      final blocked = AdminSuperAdminGate.guardLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: l10n.getText('9ro9sa93'),
        feature: uiTr(context, 'إدارة الدول'),
      );
      if (blocked != null) return blocked;
    }

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
        title: l10n.getText('9ro9sa93'),
        child: AdminPageBody(
          title: l10n.getText('kjly85m8'),
          subtitle: appTr(context, 'scr_countries_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildSearch(l10n)),
                          const SizedBox(width: 12),
                          _buildAddButton(l10n),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearch(l10n),
                          const SizedBox(height: 12),
                          _buildAddButton(l10n),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              AdminFirestoreList<CountriesRecord>(
                refreshScope: AdminListScope.countries,
                query: CountriesRecord.collection,
                recordBuilder: CountriesRecord.fromSnapshot,
                queryBuilder: (q) => q.orderBy('naim'),
                builder: (context, allCountries, listState) {
                  final countries = _filterCountries(allCountries);

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            adminListCountLabel(context, listState, visibleCount: countries.length, pageFetched: allCountries.length),
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        if (countries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? uiTr(context, 'لا توجد دول مسجلة')
                                      : uiTr(context, 'لا توجد نتائج للبحث'),
                                  style: theme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        else if (isWide)
                          _CountriesGrid(
                            countries: countries,
                            onEdit: _editCountry,
                            onDelete: _deleteCountry,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: countries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _CountryCard(
                              record: countries[index],
                              onEdit: () => _editCountry(countries[index]),
                              onDelete: () =>
                                  _deleteCountry(countries[index]),
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

  Widget _buildSearch(FFLocalizations l10n) {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admin_dol_search',
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
        hint: uiTr(context, 'ابحث باسم الدولة أو الوصف...'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('gusxjz6h'),
      icon: Icons.add_rounded,
      onPressed: () => context.pushNamed(AddDolhWidget.routeName),
    );
  }
}

class _CountriesGrid extends StatelessWidget {
  const _CountriesGrid({
    required this.countries,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CountriesRecord> countries;
  final void Function(CountriesRecord) onEdit;
  final Future<void> Function(CountriesRecord) onDelete;

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
            for (final country in countries)
              SizedBox(
                width: itemWidth,
                child: _CountryCard(
                  record: country,
                  onEdit: () => onEdit(country),
                  onDelete: () => onDelete(country),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final CountriesRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          _CountryFlag(url: record.img),
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(active: record.acctev),
                    if (record.saudi) const _SaudiBadge(),
                    if (record.currencyCode.isNotEmpty ||
                        record.currencySymbol.isNotEmpty)
                      _CurrencyBadge(
                        code: record.currencyCode,
                        symbol: record.currencySymbol,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 36,
                fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
                icon: Icon(
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

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.url});

  final String url;

  static const double flagWidth = 72;
  static const double flagHeight = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flagWidth,
      height: flagHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
        width: flagWidth,
        height: flagHeight,
        fallback: const _FlagFallback(),
      ),
    );
  }
}

class _FlagFallback extends StatelessWidget {
  const _FlagFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminUi.brandTeal.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.flag_rounded,
          color: AdminUi.brandTeal,
          size: 28,
        ),
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

class _SaudiBadge extends StatelessWidget {
  const _SaudiBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Text(
        uiTr(context, '🇸🇦 السعودية'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: const Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  const _CurrencyBadge({
    required this.code,
    required this.symbol,
  });

  final String code;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = [
      if (code.trim().isNotEmpty) code.trim().toUpperCase(),
      if (symbol.trim().isNotEmpty) symbol.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: const Color(0xFF1565C0),
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}
