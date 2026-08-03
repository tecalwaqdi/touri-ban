import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
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
import 'admin_drivers_model.dart';
export 'admin_drivers_model.dart';

/// قائمة المناديب بانتظار التفعيل (`actev_mndob=false`).
class AdminDriversWidget extends StatefulWidget {
  const AdminDriversWidget({super.key});

  static String routeName = 'AdminDrivers';
  static String routePath = '/adminDrivers';

  @override
  State<AdminDriversWidget> createState() => _AdminDriversWidgetState();
}

class _AdminDriversWidgetState extends State<AdminDriversWidget> {
  late AdminDriversModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminDriversModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    if (AdminRoleService.isCountryAgent) {
      AdminAgentCountryLock.applyToAppState();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<UserRecord> _filterDrivers(List<UserRecord> drivers) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return drivers;
    return drivers.where((d) {
      return d.displayName.toLowerCase().contains(q) ||
          d.email.toLowerCase().contains(q) ||
          d.phoneNumber.toLowerCase().contains(q) ||
          d.mndobVillText.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deactivateDriver(UserRecord driver) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(uiTr(context, 'تأكيد الإيقاف')),
            content: Text(appTrFormat(context, 'adm_stop_confirm_body', driver.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(uiTr(context, 'نعم')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await driver.reference.update(
        createUserRecordData(actevMndob: false),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم إيقاف المندوب بنجاح'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_deactivate_failed')}: $e')),
      );
    }
  }

  void _openActivation(UserRecord driver) {
    context.pushNamed(
      DriverActivationWidget.routeName,
      queryParameters: {
        'dre': serializeParam(driver.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
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
        title: l10n.getText('ksgnau0w'),
        child: AdminPageBody(
          title: l10n.getText('ksgnau0w'),
          subtitle: uiTr(context, 'مناديب بانتظار التفعيل أو المراجعة'),
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
              const SizedBox(height: 16),
              AdminFirestoreList<UserRecord>(
                refreshScope: AdminListScope.drivers,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminCountryScope.applyPendingDriverActivationQuery(q),
                builder: (context, allDrivers, listState) {
                  final drivers = _filterDrivers(allDrivers);

                  return AdminContentCard(
                    padding: drivers.isEmpty
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (drivers.isNotEmpty)
                                    Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              'العدد: ${drivers.length}'
                              '${drivers.length != allDrivers.length ? ' من ${allDrivers.length}' : ''}'
                              '${listState.hasMore ? '+' : ''}',
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.labelLargeIsCustom,
                                        ),
                                      ),
                                    ),
                        if (drivers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Column(
                                      children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                              Text(
                                  _searchQuery.isEmpty
                                      ? 'لا يوجد مناديب بانتظار التفعيل'
                                      : 'لا توجد نتائج للبحث',
                                  style: theme.titleMedium,
                                  textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                          )
                        else
                          ListView.separated(
                                                  shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: drivers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _PendingDriverCard(
                              driver: drivers[index],
                              onActivate: () => _openActivation(drivers[index]),
                              onDeactivate: () =>
                                  _deactivateDriver(drivers[index]),
                            ),
                          ),
                        if (drivers.isNotEmpty)
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
        '_admin_drivers_search',
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
        hint: l10n.getText('fczkvegx'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('ocrq56of'),
      icon: Icons.person_add_rounded,
      onPressed: () => context.pushNamed(AddDrevWidget.routeName),
    );
  }
}

class _PendingDriverCard extends StatelessWidget {
  const _PendingDriverCard({
    required this.driver,
    required this.onActivate,
    required this.onDeactivate,
  });

  final UserRecord driver;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isActive = driver.actevMndob;

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: theme.alternate),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AdminRecordThumbnail(
            imageUrl: driver.photoUrl,
            width: 48,
            height: 48,
            fallback: Icon(
              Icons.directions_car_rounded,
              color: AdminUi.brandTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.displayName,
                  style: theme.titleSmall,
                ),
                if (driver.mndobVillText.isNotEmpty)
                  Text(
                    driver.mndobVillText,
                    style: theme.labelMedium.override(
                      fontFamily: theme.labelMediumFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelMediumIsCustom,
                    ),
                  ),
                Text(
                  isActive ? 'نشط' : 'غير مفعّل',
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: isActive ? theme.success : theme.error,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            FlutterFlowIconButton(
              buttonSize: 40,
              fillColor: theme.accent4,
              icon: Icon(Icons.stop_circle, color: theme.error, size: 28),
              onPressed: onDeactivate,
            )
          else
            FlutterFlowIconButton(
              buttonSize: 40,
              fillColor: theme.accent4,
              icon: Icon(Icons.verified, color: theme.primary, size: 28),
              onPressed: onActivate,
            ),
        ],
      ),
    );
  }
}
