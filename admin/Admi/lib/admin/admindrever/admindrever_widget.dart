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
import 'admindrever_model.dart';
export 'admindrever_model.dart';

class AdmindreverWidget extends StatefulWidget {
  const AdmindreverWidget({super.key});

  static String routeName = 'Admindrever';
  static String routePath = '/drever';

  @override
  State<AdmindreverWidget> createState() => _AdmindreverWidgetState();
}

class _AdmindreverWidgetState extends State<AdmindreverWidget> {
  late AdmindreverModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdmindreverModel());

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

  List<UserRecord> _filterReps(List<UserRecord> reps) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return reps;
    return reps.where((r) {
      return r.displayName.toLowerCase().contains(q) ||
          r.phoneNumber.toLowerCase().contains(q) ||
          r.mndobVillText.toLowerCase().contains(q) ||
          r.transportCompanyText.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleActivation(UserRecord user, {required bool activate}) async {
    final title = activate ? 'تأكيد التفعيل' : 'تأكيد الإيقاف';
    final content = activate
        ? 'هل أنت متأكد من تفعيل المندوب؟'
        : 'هل أنت متأكد من إيقاف المندوب؟';

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
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
      await user.reference.update(
        createUserRecordData(actevMndob: activate),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? 'تم تفعيل المندوب بنجاح' : 'تم إيقاف المندوب بنجاح',
          ),
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
        title: l10n.getText('xqeazwes'),
        child: AdminPageBody(
          title: l10n.getText('xqeazwes'),
          subtitle: appTr(context, 'scr_reps_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildSearchField(l10n, theme)),
                          const SizedBox(width: 12),
                          _buildAddButton(l10n),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchField(l10n, theme),
                          const SizedBox(height: 12),
                          _buildAddButton(l10n),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<UserRecord>(
                refreshScope: AdminListScope.representatives,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminCountryScope.applyRepresentativeQuery(q),
                builder: (context, allReps, listState) {
                  final reps = _filterReps(allReps);

                  return AdminContentCard(
                    padding: reps.isEmpty
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (reps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              'العدد: ${reps.length}'
                              '${reps.length != allReps.length ? ' من ${allReps.length}' : ''}'
                              '${listState.hasMore ? '+' : ''}',
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.labelLargeIsCustom,
                              ),
                            ),
                          ),
                        if (reps.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'لا يوجد مناديب مسجلون'
                                      : 'لا توجد نتائج للبحث',
                                  style: theme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        else if (isWide)
                          _RepresentativesTable(
                            reps: reps,
                            l10n: l10n,
                            onToggle: _toggleActivation,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: reps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _RepresentativeCard(
                              user: reps[index],
                              l10n: l10n,
                              onToggle: _toggleActivation,
                            ),
                          ),
                        if (reps.isNotEmpty)
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

  Widget _buildSearchField(FFLocalizations l10n, FlutterFlowTheme theme) {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admindrever_search',
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
        label: l10n.getText('wvm3crco'),
        hint: 'ابحث بالاسم أو الجوال أو المدينة...',
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: uiTr(context, 'إضافة مندوب جديد'),
      icon: Icons.person_add_rounded,
      onPressed: () => context.pushNamed(AddDrevWidget.routeName),
    );
  }
}

class _RepresentativesTable extends StatelessWidget {
  const _RepresentativesTable({
    required this.reps,
    required this.l10n,
    required this.onToggle,
  });

  final List<UserRecord> reps;
  final FFLocalizations l10n;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AdminUi.adminTableMinWidth(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeaderRow(l10n: l10n, theme: theme),
            const Divider(height: 1),
            ...reps.map(
              (user) => _TableDataRow(
                user: user,
                l10n: l10n,
                theme: theme,
                onToggle: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.l10n, required this.theme});

  final FFLocalizations l10n;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _HeaderCell(l10n.getText('1s8f4tb9'), flex: 3, theme: theme),
          _HeaderCell(l10n.getText('py60u4hw'), flex: 2, theme: theme),
          _HeaderCell(l10n.getText('u207wx5e'), flex: 2, theme: theme),
          _HeaderCell(l10n.getText('qrv84p3x'), flex: 2, theme: theme),
          _HeaderCell('الحالة', flex: 2, theme: theme),
          _HeaderCell(l10n.getText('a4euyls3'), flex: 2, theme: theme),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, required this.theme});

  final String text;
  final int flex;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.labelLarge.override(
          fontFamily: theme.labelLargeFamily,
          fontWeight: FontWeight.w700,
          color: AdminUi.brandTeal,
          useGoogleFonts: !theme.labelLargeIsCustom,
        ),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.user,
    required this.l10n,
    required this.theme,
    required this.onToggle,
  });

  final UserRecord user;
  final FFLocalizations l10n;
  final FlutterFlowTheme theme;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.alternate.withValues(alpha: 0.6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _NameCell(user: user, theme: theme),
          ),
          Expanded(
            flex: 2,
            child: _DataCell(
              user.mndobVillText.isNotEmpty ? user.mndobVillText : '—',
              theme: theme,
            ),
          ),
          Expanded(
            flex: 2,
            child: _DataCell(
              user.totalApp.toStringAsFixed(0),
              theme: theme,
              bold: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: _DataCell(
              user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
              theme: theme,
              monospace: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusBadge(active: user.actevMndob),
          ),
          Expanded(
            flex: 2,
            child: _ActionButtons(user: user, onToggle: onToggle),
          ),
        ],
      ),
    );
  }
}

class _RepresentativeCard extends StatelessWidget {
  const _RepresentativeCard({
    required this.user,
    required this.l10n,
    required this.onToggle,
  });

  final UserRecord user;
  final FFLocalizations l10n;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: theme.error,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(active: user.actevMndob),
                  ],
                ),
              ),
              _ActionButtons(user: user, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (user.transportCompanyText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoTile(
                icon: Icons.local_shipping_outlined,
                label: uiTr(context, 'شركة النقل'),
                value: user.transportCompanyText,
              ),
            ),
          _InfoTile(
            icon: Icons.location_city_rounded,
            label: l10n.getText('py60u4hw'),
            value: user.mndobVillText.isNotEmpty ? user.mndobVillText : '—',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.getText('u207wx5e'),
            value: user.totalApp.toStringAsFixed(0),
            highlight: true,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.phone_rounded,
            label: l10n.getText('qrv84p3x'),
            value: user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminUi.brandTeal.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.trim(),
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: (highlight ? theme.titleSmall : theme.bodyMedium).override(
                  fontFamily: highlight
                      ? theme.titleSmallFamily
                      : theme.bodyMediumFamily,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  useGoogleFonts: highlight
                      ? !theme.titleSmallIsCustom
                      : !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.user, required this.theme});

  final UserRecord user;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(user: user, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            user.displayName.isNotEmpty ? user.displayName : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              fontWeight: FontWeight.w600,
              color: theme.error,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.theme,
    this.bold = false,
    this.monospace = false,
  });

  final String text;
  final FlutterFlowTheme theme;
  final bool bold;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.bodyMedium.override(
          fontFamily: monospace ? 'monospace' : theme.bodyMediumFamily,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          useGoogleFonts: !monospace && !theme.bodyMediumIsCustom,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.size = 44});

  final UserRecord user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdminRecordThumbnail(
        imageUrl: user.photoUrl,
        width: size,
        height: size,
        fallback: _AvatarFallback(size: size),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: AdminUi.brandTeal,
      size: size * 0.5,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = active ? const Color(0xFF2E7D32) : theme.error;
    final bg = active ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final label = active ? 'نشط' : 'موقوف';

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: color,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.user,
    required this.onToggle,
  });

  final UserRecord user;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE3F2FD),
          icon: Icon(
            Icons.edit_outlined,
            color: FlutterFlowTheme.of(context).primary,
            size: 18,
          ),
          onPressed: () {
            context.pushNamed(
              AddDrevWidget.routeName,
              queryParameters: {
                'editUser': serializeParam(
                  user.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            );
          },
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
          icon: Icon(
            Icons.visibility_outlined,
            color: AdminUi.brandTeal,
            size: 18,
          ),
          onPressed: () {
            context.pushNamed(
              DriverProfileWidget.routeName,
              queryParameters: {
                'iduser': serializeParam(
                  user.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            );
          },
        ),
        if (user.actevMndob)
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 36,
            fillColor: const Color(0xFFFFEBEE),
            icon: Icon(
              Icons.block_rounded,
              color: FlutterFlowTheme.of(context).error,
              size: 18,
            ),
            onPressed: () => onToggle(user, activate: false),
          )
        else
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 36,
            fillColor: const Color(0xFFE8F5E9),
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: FlutterFlowTheme.of(context).success,
              size: 18,
            ),
            onPressed: () => onToggle(user, activate: true),
          ),
      ],
    );
  }
}
