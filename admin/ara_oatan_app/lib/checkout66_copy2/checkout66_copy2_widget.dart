import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/components/mmaapp_widget.dart';
import '/core/toury_landmark_cart.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'checkout66_copy2_model.dart';
export 'checkout66_copy2_model.dart';

class Checkout66Copy2Widget extends StatefulWidget {
  const Checkout66Copy2Widget({super.key});

  static String routeName = 'Checkout66Copy2';
  static String routePath = '/checkout66Copy2';

  @override
  State<Checkout66Copy2Widget> createState() => _Checkout66Copy2WidgetState();
}

class _Checkout66Copy2WidgetState extends State<Checkout66Copy2Widget> {
  late Checkout66Copy2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Checkout66Copy2Model());

    _model.textController ??= TextEditingController(
        text: (FFAppState().saatcar + FFAppState().addhors).toString());
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Business logic — unchanged behaviour, DS-styled surfaces only.
  // ---------------------------------------------------------------------------

  bool get _hasItems => FFAppState().addcart >= 1;

  bool get _hasHourlyPlan => _hasItems && FFAppState().saatcar != 0;

  Future<void> _openTripMapSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return WebViewAware(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: const MmaappWidget(),
            ),
          ),
        );
      },
    ).then((value) => safeSetState(() {}));
  }

  void _removeCartPlace(AmaknCostmStruct mkssItem) {
    touryRemoveLandmarkFromCart(
      context: context,
      item: mkssItem,
      onChanged: () => safeSetState(() {}),
    );
  }

  /// Extra hours feed both the app-state counter and the derived totals.
  Future<void> _updateExtraHours(int count) async {
    safeSetState(() => _model.countControllerValue = count);
    FFAppState().addhors = _model.countControllerValue!;
    FFAppState().totalsaat = FFAppState().saatcar + FFAppState().addhors;
    safeSetState(() {});
  }

  int? get _baseTotal => functions.total(
        FFAppState().srtypecar,
        FFAppState().totalsaat.toDouble(),
      );

  double? get _appFee => functions.vat(10.0, _baseTotal);

  String get _vatAmount => valueOrDefault<String>(
        functions.nesbhmnrgmen(_baseTotal, _appFee, 15)?.toString(),
        '0',
      );

  String get _grandTotal {
    final typedTotal = functions.total(
      FFAppState().srtypecar,
      double.tryParse(_model.textController.text),
    );
    return functions
        .totalAll(
          _baseTotal?.toDouble(),
          _appFee?.toDouble(),
          valueOrDefault<double>(
            functions
                .nesbhmnrgmen(
                  typedTotal,
                  functions.vat(10.0, typedTotal),
                  15,
                )
                ?.toDouble(),
            0.0,
          ),
        )
        .toString();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
              drawer: WebViewAware(child: _buildDrawer(context)),
              appBar: _buildAppBar(context),
              body: SafeArea(
                top: false,
                child:
                    _hasItems ? _buildTripBody(context) : _buildEmpty(context),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return DsAppBar(
      automaticallyImplyLeading: false,
      title: FFLocalizations.of(context).getText(
        'n4minjo8' /* My trip list */,
      ),
      leading: DsBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        DsIconButton(
          icon: Icons.list_alt_rounded,
          onPressed: () async {
            context.pushNamed(
              ListViWidget.routeName,
              queryParameters: {
                'cite': serializeParam(
                  FFAppState().villa,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            );
          },
        ),
        const SizedBox(width: DsSpacing.xxs),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return DsFadeSlide(
      child: DsEmptyState(
        icon: Icons.luggage_outlined,
        title: FFLocalizations.of(context).getText(
          'wka7ux46' /* No tours have been added! */,
        ),
        message: FFLocalizations.of(context).getText(
          'be0v7eti' /* No tours have been added! */,
        ),
      ),
    );
  }

  Widget _buildTripBody(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: DsSpacing.md),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.sm,
                    DsSpacing.md,
                    DsSpacing.xs,
                  ),
                  child: DsButton.outlined(
                    expanded: true,
                    icon: Icons.map_outlined,
                    label: FFLocalizations.of(context).getText(
                      '3f6pytzl' /* View my trip list map */,
                    ),
                    onPressed: _openTripMapSheet,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                    vertical: DsSpacing.xxs,
                  ),
                  child: _SelectionTile(
                    icon: DsIcons.car,
                    title: valueOrDefault<String>(
                      FFAppState().tebycar,
                      'لم يتم تحديد سيارة',
                    ),
                    subtitle: valueOrDefault<String>(
                      FFAppState().notcar,
                      ' السيارة المفضلة',
                    ),
                    onTap: () async {
                      context.pushNamed(CarWidget.routeName);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                    vertical: DsSpacing.xxs,
                  ),
                  child: _SelectionTile(
                    icon: DsIcons.location,
                    title: valueOrDefault<String>(
                      FFAppState().villtextnow,
                      'مكان الإلتقاء',
                    ),
                    subtitle: FFLocalizations.of(context).getText(
                      'veo115ap' /* Please select the city you are... */,
                    ),
                    onTap: () async {
                      context.pushNamed(ListvillnowWidget.routeName);
                    },
                  ),
                ),
                DsSectionHeader(
                  title: FFLocalizations.of(context).getText(
                    'z54884xu' /* List of added locations. */,
                  ),
                  subtitle: FFAppState().naimvillatext,
                ),
                _buildPlacesList(context),
                if (valueOrDefault<bool>(
                      currentUserDocument?.actevMndob,
                      false,
                    ) ==
                    true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.md,
                      DsSpacing.md,
                      0,
                    ),
                    child: AuthUserStreamWidget(
                      builder: (context) => _buildHoursField(context),
                    ),
                  ),
                if (_hasHourlyPlan) ...[
                  const SizedBox(height: DsSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md,
                    ),
                    child: _buildHoursCard(context),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md,
                    ),
                    child: _buildPriceBreakdown(context),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_hasHourlyPlan) _buildCheckoutBar(context),
      ],
    );
  }

  Widget _buildPlacesList(BuildContext context) {
    final mkss = FFAppState().cartmkss.toList();

    return ListView.builder(
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: mkss.length,
      itemBuilder: (context, index) {
        final mkssItem = mkss[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.xs,
            DsSpacing.md,
            0,
          ),
          child: DsFadeSlide(
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: _PlaceCard(
              name: mkssItem.naim,
              onRemove: () => _removeCartPlace(mkssItem),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoursField(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: DsRadius.medium,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      autofocus: false,
      obscureText: false,
      keyboardType: TextInputType.number,
      cursorColor: colors.primary,
      style: typography.bodyLarge.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        labelText: FFLocalizations.of(context).getText(
          '1mfsgnmt' /* عدد الساعات المطلوبة */,
        ),
        labelStyle: typography.labelMedium.copyWith(
          color: colors.textSecondary,
        ),
        hintText: FFLocalizations.of(context).getText(
          'tl7tpkur' /* TextField */,
        ),
        hintStyle: typography.bodySmall.copyWith(color: colors.hint),
        prefixIcon: Icon(Icons.schedule_rounded, color: colors.iconMuted),
        filled: true,
        fillColor: colors.surface,
        contentPadding: DsSpacing.inputContentPadding,
        border: border(colors.border),
        enabledBorder: border(colors.border),
        focusedBorder: border(colors.focus, width: 1.6),
        errorBorder: border(colors.error),
        focusedErrorBorder: border(colors.error, width: 1.6),
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildHoursCard(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsPressable(
            onTap: () async {
              context.pushNamed(Checkout66Copy2Widget.routeName);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primaryStrong],
                ),
                borderRadius: DsRadius.medium,
              ),
              child: Text(
                '${FFAppState().saatcar.toString()}${' ساعات أساسية متاحة مع الحجز '}',
                textAlign: TextAlign.center,
                style: typography.titleSmall.copyWith(color: colors.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Center(
            child: DsButton.text(
              label: FFLocalizations.of(context).getText(
                '78a5u6uf' /* Additional hours */,
              ),
              icon: Icons.more_time_rounded,
              onPressed: () async {
                context.pushNamed(Checkout3Widget.routeName);
              },
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          Center(
            child: Container(
              width: 132,
              height: DsConstants.buttonHeightSm,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: DsRadius.medium,
              ),
              child: FlutterFlowCountController(
                decrementIconBuilder: (enabled) => Icon(
                  Icons.remove_rounded,
                  color: enabled ? colors.icon : colors.disabled,
                  size: DsIcons.md,
                ),
                incrementIconBuilder: (enabled) => Icon(
                  Icons.add_rounded,
                  color: enabled ? colors.primary : colors.disabled,
                  size: DsIcons.md,
                ),
                countBuilder: (count) => Text(
                  count.toString(),
                  style: typography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                count: _model.countControllerValue ??= 0,
                updateCount: _updateExtraHours,
                stepSize: 1,
                minimum: 0,
                maximum: 300,
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  DsSpacing.sm,
                  0.0,
                  DsSpacing.sm,
                  0.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'yf0bd934' /* Total number of hours:  */,
                    ),
                    style: typography.titleSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: (FFAppState().saatcar + FFAppState().addhors)
                        .toString(),
                    style: typography.titleMedium.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'prxk3k9a' /*   Hours   */,
                    ),
                    style: typography.titleSmall.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(BuildContext context) {
    return DsCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PriceRow(
            label: FFLocalizations.of(context).getText(
              'cvynf9d6' /* Total price: */,
            ),
            value: '${_baseTotal.toString()}'
                '${FFLocalizations.of(context).getText(
              'iyjh4m9g' /* R.S */,
            )}',
          ),
          const SizedBox(height: DsSpacing.xs),
          _PriceRow(
            label: FFLocalizations.of(context).getText(
              'r4njg998' /* Application fee 10%: */,
            ),
            value: formatNumber(
              _appFee,
              formatType: FormatType.decimal,
              decimalType: DecimalType.automatic,
              currency: 'ر.س ',
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          _PriceRow(
            label: FFLocalizations.of(context).getText(
              '2pqf8rlw' /* VAT 15%:  */,
            ),
            value: '$_vatAmount${FFLocalizations.of(context).getText(
              'mgcfshum' /*  R.S  */,
            )}',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        boxShadow: DsShadows.bottomSheet(dark: context.dsIsDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  FFLocalizations.of(context).getText(
                    'bs7xbl75' /* Total:   */,
                  ),
                  style: typography.titleSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$_grandTotal${FFLocalizations.of(context).getText(
                  'eidrei68' /*  ر.س  */,
                )}',
                style: typography.headlineSmall.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.primary(
            expanded: true,
            size: DsButtonSize.lg,
            icon: Icons.payment_rounded,
            label: FFLocalizations.of(context).getText(
              'y1obdz3e' /* Book now */,
            ),
            onPressed: () {
              print('Button pressed ...');
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Widget _buildDrawer(BuildContext context) {
    return DsDrawer(
      header: _DrawerHeaderCard(
        caption: FFLocalizations.of(context).getText(
          'k7bwtga6' /* YOU ARE BROWSING NOW */,
        ),
        countryName: FFAppState().naimdolh,
        changeLabel: FFLocalizations.of(context).getText(
          'nv5pw5o0' /* Change country */,
        ),
        onChangeCountry: () async {
          context.pushNamed(LISTCountriesWidget.routeName);
        },
      ),
      items: [
        _DrawerActionTile(
          icon: DsIcons.location,
          title: FFLocalizations.of(context).getText(
            'e2p9bqag' /* You are currently browsing. */,
          ),
          subtitle: FFAppState().naimvillatext,
        ),
        _DrawerActionTile(
          icon: DsIcons.map,
          title: FFAppState().naimmdenh,
          subtitle: FFLocalizations.of(context).getText(
            '4t5pmmpz' /* Go now. */,
          ),
          onTap: () async {
            context.pushNamed(ListWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.playlist_add_check_rounded,
          title: FFLocalizations.of(context).getText(
            'grnb4jcy' /* Added destinations */,
          ),
          badge: FFAppState().addcart.toString(),
          onTap: () async {
            context.pushNamed(Checkout66Copy2Widget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.bookings,
          title: FFLocalizations.of(context).getText(
            '1jnhdrno' /* My bookings */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            'qdh43sza' /* Booking list. */,
          ),
          onTap: () async {
            context.pushNamed(List22TaskOverviewResponsiveWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.mail_outline_rounded,
          title: FFLocalizations.of(context).getText(
            'ufw7fgrl' /* رسائل جديدة */,
          ),
          badge: FFLocalizations.of(context).getText(
            'ptn5zdw3' /* 0 */,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.xs,
          ),
          child: DsDivider(),
        ),
        DsDrawerItem(
          icon: DsIcons.settings,
          label: FFLocalizations.of(context).getText(
            'cvo7w5qx' /* Settings */,
          ),
          onTap: () async {
            context.pushNamed(Profile05Widget.routeName);
          },
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Trip pieces
// -----------------------------------------------------------------------------

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: DsRadius.medium,
            ),
            child: Icon(icon, size: DsIcons.sm, color: colors.primary),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: DsIcons.sm,
            color: colors.iconMuted,
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            alignment: Alignment.center,
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
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          DsIconButton(
            icon: DsIcons.delete,
            foreground: colors.error,
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: typography.titleSmall.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Drawer pieces
// -----------------------------------------------------------------------------

class _DrawerHeaderCard extends StatelessWidget {
  const _DrawerHeaderCard({
    required this.caption,
    required this.countryName,
    required this.changeLabel,
    required this.onChangeCountry,
  });

  final String caption;
  final String countryName;
  final String changeLabel;
  final VoidCallback onChangeCountry;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: DsRadius.large,
        boxShadow: DsShadows.primaryGlow(dark: context.dsIsDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DsConstants.avatarMd,
                height: DsConstants.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: DsRadius.medium,
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: DsIcons.sm,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.labelSmall.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleLarge.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          DsPressable(
            onTap: onChangeCountry,
            child: Container(
              padding: DsSpacing.chipPadding,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.16),
                borderRadius: DsRadius.pill,
                border: Border.all(
                  color: colors.onPrimary.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: DsIcons.xs,
                    color: colors.onPrimary,
                  ),
                  const SizedBox(width: DsSpacing.xxs),
                  Text(
                    changeLabel,
                    style: typography.labelMedium.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return ListTile(
      leading: Container(
        width: DsConstants.avatarSm,
        height: DsConstants.avatarSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: DsRadius.small,
        ),
        child: Icon(icon, size: DsIcons.sm, color: colors.primary),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.titleSmall.copyWith(color: colors.textPrimary),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: DsRadius.pill,
              ),
              child: Text(
                badge!,
                style: typography.labelMedium.copyWith(
                  color: colors.primaryStrong,
                ),
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: DsSpacing.xxs),
            Icon(
              Icons.chevron_right_rounded,
              size: DsIcons.sm,
              color: colors.iconMuted,
            ),
          ],
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
      onTap: onTap,
    );
  }
}