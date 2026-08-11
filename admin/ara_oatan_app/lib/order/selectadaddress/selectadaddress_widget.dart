import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'selectadaddress_model.dart';

export 'selectadaddress_model.dart';

/// List of Addresses
///
/// A list where each address is displayed as a selectable item.
///
/// Users can tap on an address to select it.
/// A selected address is highlighted to indicate it has been chosen.
/// Confirm Button
///
/// A button at the bottom to confirm the selected address and proceed to the
/// next step (e.g., navigating to the selected location).
/// Behavior:
///
/// Only one address can be selected at a time.
/// If no address is selected and the user presses "Confirm," an error message
/// or prompt is displayed.
/// Example Design (Text):
/// Choose an Address for Navigation:
///
/// Address 1 (Selectable)
/// Address 2 (Selectable)
/// Address 3 (Selectable)
/// (Selected Address is Highlighted)
///
/// [Confirm Address] (Button at the Bottom)
class SelectadaddressWidget extends StatefulWidget {
  const SelectadaddressWidget({super.key});

  static String routeName = 'Selectadaddress';
  static String routePath = '/selectadaddress';

  @override
  State<SelectadaddressWidget> createState() => _SelectadaddressWidgetState();
}

class _SelectadaddressWidgetState extends State<SelectadaddressWidget> {
  late SelectadaddressModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SelectadaddressModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

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
                  'w0fdamuo' /* Select the address */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: StreamBuilder<List<AdressuserRecord>>(
                  stream: queryAdressuserRecord(
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
                    List<AdressuserRecord> listViewAdressuserRecordList =
                        snapshot.data!;

                    if (listViewAdressuserRecordList.isEmpty) {
                      return DsEmptyState(
                        icon: Icons.location_off_outlined,
                        title: FFLocalizations.of(context).getText(
                          'clz0j4ow' /* No Addresses Found */,
                        ),
                        message: FFLocalizations.of(context).getText(
                          'wzjesk7u' /* You haven't added any addresse... */,
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.md,
                        DsSpacing.md,
                        DsSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: listViewAdressuserRecordList.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DsSpacing.sm),
                      itemBuilder: (context, listViewIndex) {
                        if (listViewIndex == 0) {
                          return DsInformationCard(
                            title: FFLocalizations.of(context).getText(
                              'w0fdamuo' /* Select the address */,
                            ),
                            message: FFLocalizations.of(context).getText(
                              'fjy1t636' /* Choose your delivery address: */,
                            ),
                            icon: Icons.location_on_outlined,
                          );
                        }

                        final listViewAdressuserRecord =
                            listViewAdressuserRecordList[listViewIndex - 1];

                        return DsFadeSlide(
                          delay: Duration(
                            milliseconds: 40 * (listViewIndex - 1),
                          ),
                          child: DsCard(
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
                                    Icons.location_on_outlined,
                                    size: DsIcons.sm,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: DsSpacing.sm),
                                Expanded(
                                  child: Text(
                                    listViewAdressuserRecord.tilet,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.titleSmall.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: DsIcons.md,
                                  color: colors.iconMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
