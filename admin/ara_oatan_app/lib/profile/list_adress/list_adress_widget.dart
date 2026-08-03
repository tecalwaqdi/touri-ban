import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/not_addresses_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'list_adress_model.dart';

export 'list_adress_model.dart';

/// قائمة بعناوين المستخدم المحفوظة
class ListAdressWidget extends StatefulWidget {
  const ListAdressWidget({super.key});

  static String routeName = 'list_adress';
  static String routePath = '/listAdress';

  @override
  State<ListAdressWidget> createState() => _ListAdressWidgetState();
}

class _ListAdressWidgetState extends State<ListAdressWidget> {
  late ListAdressModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListAdressModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _openEditor(AdressuserRecord record) async {
    FFAppState().adressVillTEXT = '';
    FFAppState().adressVillRev = null;
    safeSetState(() {});

    context.pushNamed(
      EdetressaddWidget.routeName,
      queryParameters: {
        'ed': serializeParam(
          record,
          ParamType.Document,
        ),
      }.withoutNulls,
      extra: <String, dynamic>{
        'ed': record,
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdressuserRecord record,
  ) async {
    var confirmDialogResponse = await showDialog<bool>(
          context: context,
          builder: (alertDialogContext) {
            return WebViewAware(
              child: AlertDialog(
                content: Text('ui_text_def4060285'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(alertDialogContext, false),
                    child: Text('ui_text_5c528d9fa3'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(alertDialogContext, true),
                    child: Text('ui_text_d045bef8e5'.tr()),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
    if (confirmDialogResponse) {
      await record.reference.delete();
      if (!mounted) return;
      DsSnackBar.show(
        context,
        message: 'ui_text_85d0e17cdb'.tr(),
        tone: DsSnackTone.error,
      );
    }
  }

  Future<void> _addAddress() async {
    FFAppState().adressVillTEXT = '';
    FFAppState().adressVillRev = null;
    safeSetState(() {});

    context.pushNamed(AddressaddWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: FFLocalizations.of(context).getText(
                  '32tu70ib' /* Address list */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pushNamed(Profile05Widget.routeName);
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: FutureBuilder<int>(
                  future: queryAdressuserRecordCount(
                    queryBuilder: (adressuserRecord) => adressuserRecord.where(
                      'USER',
                      isEqualTo: currentUserReference,
                    ),
                  ),
                  builder: (context, snapshot) {
                    // Customize what your widget looks like when it's loading.
                    if (!snapshot.hasData) {
                      return const DsLoading();
                    }
                    int columnCount = snapshot.data!;

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.md,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (columnCount == 0)
                                  wrapWithModel(
                                    model: _model.notAddressesModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: const NotAddressesWidget(),
                                  ),
                                StreamBuilder<List<AdressuserRecord>>(
                                  stream: queryAdressuserRecord(
                                    queryBuilder: (adressuserRecord) =>
                                        adressuserRecord.where(
                                      'USER',
                                      isEqualTo: currentUserReference,
                                    ),
                                  ),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.all(DsSpacing.xl),
                                        child: DsLoading(),
                                      );
                                    }
                                    List<AdressuserRecord>
                                        listViewAdressuserRecordList =
                                        snapshot.data!;

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewAdressuserRecordList.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: DsSpacing.sm),
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewAdressuserRecord =
                                            listViewAdressuserRecordList[
                                                listViewIndex];
                                        return DsFadeSlide(
                                          delay: Duration(
                                            milliseconds: 40 * listViewIndex,
                                          ),
                                          child: _AddressTile(
                                            record: listViewAdressuserRecord,
                                            onEdit: () => _openEditor(
                                              listViewAdressuserRecord,
                                            ),
                                            onDelete: () => _confirmDelete(
                                              context,
                                              listViewAdressuserRecord,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.xs,
                            DsSpacing.md,
                            DsSpacing.md,
                          ),
                          child: DsButton.primary(
                            label: FFLocalizations.of(context).getText(
                              'tjoqfl2u' /* + Add New Address */,
                            ),
                            icon: DsIcons.add,
                            size: DsButtonSize.lg,
                            expanded: true,
                            onPressed: _addAddress,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Saved address row with edit / delete affordances.
class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final AdressuserRecord record;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: DsRadius.medium,
            ),
            child: Icon(
              DsIcons.location,
              size: DsIcons.sm,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              record.tilet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          DsIconButton(
            icon: DsIcons.edit,
            size: DsIcons.sm,
            filled: true,
            onPressed: () async => onEdit(),
          ),
          const SizedBox(width: DsSpacing.xs),
          DsIconButton(
            icon: DsIcons.delete,
            size: DsIcons.sm,
            background: colors.errorContainer,
            foreground: colors.error,
            onPressed: () async => onDelete(),
          ),
        ],
      ),
    );
  }
}
