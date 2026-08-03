import '/backend/admin_audit_log.dart';
import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/components/add_yser_widget.dart';
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
import 'adminuser_model.dart';
export 'adminuser_model.dart';

class AdminuserWidget extends StatefulWidget {
  const AdminuserWidget({super.key});

  static String routeName = 'Adminuser';
  static String routePath = '/adminuser';

  @override
  State<AdminuserWidget> createState() => _AdminuserWidgetState();
}

class _AdminuserWidgetState extends State<AdminuserWidget> {
  late AdminuserModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminuserModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<UserRecord> _filterUsers(List<UserRecord> users) {
    final appUsers = users
        .where((u) => !u.isagent && !u.ismndob)
        .toList(growable: false);

    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return appUsers;

    return appUsers.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleActivation(UserRecord user, {required bool activate}) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(activate ? 'تأكيد تنشيط الحساب' : 'تأكيد إيقاف الحساب'),
            content: Text(
              activate
                  ? 'هل أنت متأكد من تنشيط حساب "${user.displayName}"؟'
                  : 'هل أنت متأكد من إيقاف حساب "${user.displayName}"؟',
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
      await user.reference.update(
        createUserRecordData(actevUser: activate),
      );
      if (!mounted) return;
      await AdminAuditLog.recordToggle(
        targetType: 'app_user',
        targetId: user.reference.id,
        targetLabel: user.displayName,
        activated: activate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? 'تم تنشيط الحساب بنجاح' : 'تم إيقاف الحساب بنجاح',
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

  Future<void> _openAddUserSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 8),
              child: const AddYserWidget(),
            ),
          ),
        );
      },
    );
    safeSetState(() {});
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
        title: l10n.getText('0qqjtlup'),
        child: AdminPageBody(
          title: l10n.getText('5sxo5qip'),
          subtitle: appTr(context, 'scr_users_subtitle'),
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
                refreshScope: AdminListScope.users,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminCountryScope.applyAppUserQuery(q),
                builder: (context, allUsers, listState) {
                  final users = _filterUsers(allUsers);

                  if (users.isEmpty) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: AdminUi.brandTeal.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'لا يوجد مستخدمون مسجلون'
                                : 'لا توجد نتائج للبحث',
                            style: theme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return AdminContentCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Text(
                            'العدد: ${users.length}'
                            '${users.length != allUsers.length ? ' من ${allUsers.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                                        ),
                                      ),
                                    ),
                        const SizedBox(height: 8),
                        if (isWide)
                          _UsersTable(
                            users: users,
                            onToggle: _toggleActivation,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _UserCard(
                              user: users[index],
                              onToggle: _toggleActivation,
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
        '_adminuser_search',
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
        hint: 'ابحث بالاسم أو البريد أو الجوال...',
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('ojvmhyny'),
      icon: Icons.person_add_rounded,
      onPressed: _openAddUserSheet,
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.onToggle,
  });

  final List<UserRecord> users;
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
                                        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          child: Row(
                                            children: [
                  _HeaderCell('المستخدم', flex: 3, theme: theme),
                  _HeaderCell('البريد', flex: 3, theme: theme),
                  _HeaderCell('الجوال', flex: 2, theme: theme),
                  _HeaderCell('الحالة', flex: 2, theme: theme),
                  _HeaderCell('إجراءات', flex: 2, theme: theme),
                ],
              ),
            ),
            const Divider(height: 1),
            ...users.map(
              (user) => _UserTableRow(user: user, onToggle: onToggle),
            ),
                                            ],
                                          ),
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
        text,
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

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({
    required this.user,
    required this.onToggle,
  });

  final UserRecord user;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                            child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Expanded(
            flex: 3,
            child: Row(
                                                                    children: [
                _UserAvatar(user: user, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName : '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      fontWeight: FontWeight.w600,
                      useGoogleFonts: !theme.bodyMediumIsCustom,
                    ),
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
          Expanded(
            flex: 3,
            child: Text(
              user.email.isNotEmpty ? user.email : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
              style: theme.bodySmall,
            ),
          ),
          Expanded(flex: 2, child: _StatusBadge(active: user.actevUser)),
          Expanded(
            flex: 2,
            child: _UserActions(user: user, onToggle: onToggle),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onToggle,
  });

  final UserRecord user;
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
              _UserAvatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: AdminUi.brandTeal,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(active: user.actevUser),
                  ],
                ),
              ),
              _UserActions(user: user, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.email_outlined,
            label: uiTr(context, 'البريد الإلكتروني'),
            value: user.email.isNotEmpty ? user.email : '—',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.phone_rounded,
            label: uiTr(context, 'رقم الجوال'),
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
  });

  final IconData icon;
  final String label;
  final String value;

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
                label,
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
              const SizedBox(height: 2),
                                                                      Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                                          ),
                                                                                        ],
                                                                                      );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, this.size = 44});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'نشط' : 'موقوف',
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: active ? const Color(0xFF2E7D32) : theme.error,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
                                                          ),
                                                        ),
                                                      );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
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
          fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
          icon: const Icon(
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
        if (user.actevUser)
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
