import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/not_addresses_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'list_adress_select_model.dart';

export 'list_adress_select_model.dart';

/// قائمة بعناوين المستخدم المحفوظة
class ListAdressSelectWidget extends StatefulWidget {
  const ListAdressSelectWidget({super.key});

  static String routeName = 'list_adress_select';
  static String routePath = '/listAdressSelect';

  @override
  State<ListAdressSelectWidget> createState() => _ListAdressSelectWidgetState();
}

class _ListAdressSelectWidgetState extends State<ListAdressSelectWidget> {
  late ListAdressSelectModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListAdressSelectModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _selectAddress(AdressuserRecord record) {
    FFAppState().adressSelection = record.reference;
    FFAppState().adressNaim = record.tilet;
    FFAppState().mkanuserorder = record.map;
    FFAppState().villtextnow = record.naimVill;
    FFAppState().villnow = record.vill;
    FFAppState().update(() {});

    context.pushNamed(Checkout66Widget.routeName);
  }

  Future<void> _addAddress() async {
    FFAppState().adressVillTEXT = '';
    FFAppState().adressVillRev = null;
    safeSetState(() {});

    context.pushNamed(AddressaddWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
                  'lz7z1zve' /* Address list */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: FutureBuilder<int>(
                  future: queryAdressuserRecordCount(
                    queryBuilder: (adressuserRecord) => adressuserRecord
                        .where(
                          'USER',
                          isEqualTo: currentUserReference,
                        )
                        .where(
                          'acctev',
                          isEqualTo: true,
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
                                        adressuserRecord
                                            .where(
                                              'USER',
                                              isEqualTo: currentUserReference,
                                            )
                                            .where(
                                              'acctev',
                                              isEqualTo: true,
                                            )
                                            .where(
                                              'VILL',
                                              isEqualTo: FFAppState().villa,
                                            )
                                            .orderBy('data_add',
                                                descending: true),
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

                                    if (listViewAdressuserRecordList.isEmpty &&
                                        columnCount != 0) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: DsSpacing.xxl,
                                        ),
                                        child: DsEmptyState(
                                          icon: DsIcons.location,
                                          title:
                                              FFLocalizations.of(context)
                                                  .getText(
                                            'lz7z1zve' /* Address list */,
                                          ),
                                        ),
                                      );
                                    }

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
                                          child: _SelectableAddressTile(
                                            record: listViewAdressuserRecord,
                                            onTap: () => _selectAddress(
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
                              'bjnv8qvi' /* + Add New Address */,
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

/// Saved address row that can be picked for the current order.
class _SelectableAddressTile extends StatelessWidget {
  const _SelectableAddressTile({
    required this.record,
    required this.onTap,
  });

  final AdressuserRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      onTap: onTap,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.tilet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: DsSpacing.xxs),
                Text(
                  FFLocalizations.of(context).getText(
                    'ansiin3a' /* Selecting the address */,
                  ),
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.xs),
          Container(
            width: DsConstants.avatarSm,
            height: DsConstants.avatarSm,
            decoration: BoxDecoration(
              color: colors.successContainer,
              borderRadius: DsRadius.small,
            ),
            child: Icon(
              Icons.done_rounded,
              size: DsIcons.sm,
              color: colors.success,
            ),
          ),
        ],
      ),
    );
  }
}
