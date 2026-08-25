import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'checkout66_copy_model.dart';
export 'checkout66_copy_model.dart';

class Checkout66CopyWidget extends StatefulWidget {
  const Checkout66CopyWidget({super.key});

  static String routeName = 'Checkout66Copy';
  static String routePath = '/checkout66Copy';

  @override
  State<Checkout66CopyWidget> createState() => _Checkout66CopyWidgetState();
}

class _Checkout66CopyWidgetState extends State<Checkout66CopyWidget> {
  late Checkout66CopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Checkout66CopyModel());

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

  Future<void> _logout(BuildContext context) async {
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();

    context.goNamedAuth(HomePagWidget.routeName, context.mounted);
  }

  /// Cart removal keeps the price summary and the counter in sync.
  void _removeCartItem(dynamic cartItem) {
    FFAppState().removeFromCartPriceSummary(cartItem.totalPrice);
    FFAppState().removeFromCartItems(cartItem);
    FFAppState().addcart = FFAppState().addcart + -1;
    FFAppState().update(() {});
  }

  String get _totalAmount =>
      (((functions.priceSummary(FFAppState().cartPriceSummary.toList())!)) +
              0.000)
          .toString();

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
          final hasItems = FFAppState().addcart >= 1;

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
                child: hasItems
                    ? _buildCartBody(context)
                    : _buildEmptyBody(context),
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
        'hps58ox2' /* My trip list */,
      ),
      leading: DsBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        DsIconButton(
          icon: Icons.menu_rounded,
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: () async {
            scaffoldKey.currentState!.openDrawer();
          },
        ),
        const SizedBox(width: DsSpacing.xxs),
      ],
    );
  }

  Widget _buildEmptyBody(BuildContext context) {
    final villageHint = FFAppState().naimvillatext.trim();
    return DsFadeSlide(
      child: DsEmptyState(
        icon: Icons.luggage_outlined,
        title: FFLocalizations.of(context).getText(
          'cmuygo0x' /* No tours have been added! */,
        ),
        message: villageHint.isEmpty
            ? 'ux_add_places_hint'.tr()
            : villageHint,
      ),
    );
  }

  Widget _buildCartBody(BuildContext context) {
    final cartItems = FFAppState().cartItems.toList();

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
                    0,
                  ),
                  child: DsButton.primary(
                    expanded: true,
                    icon: Icons.map_outlined,
                    label: FFLocalizations.of(context).getText(
                      '7bl567rj' /* Show the interactive map */,
                    ),
                    onPressed: () {
                      print('Button pressed ...');
                    },
                  ),
                ),
                DsSectionHeader(
                  title: FFLocalizations.of(context).getText(
                    '00swgjcm' /* List of added locations. */,
                  ),
                  subtitle: FFAppState().naimmdenh,
                ),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.xs,
                        DsSpacing.md,
                        0,
                      ),
                      child: DsFadeSlide(
                        delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                        child: _CartItemCard(
                          itemRef: cartItem.itemRef!,
                          cityName: FFAppState().naimmdenh,
                          onRemove: () => _removeCartItem(cartItem),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: DsSpacing.md),
                DsSectionHeader(
                  title: FFLocalizations.of(context).getText(
                    'fwustt3y' /* Select the car type */,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                  ),
                  child: _CarSelectionCard(
                    carName: valueOrDefault<String>(
                      FFAppState().tebycar,
                      'لم يتم تحديد سيارة',
                    ),
                    hint: FFLocalizations.of(context).getText(
                      'fj1afbbi' /* Select your favorite car. */,
                    ),
                    onTap: () async {
                      context.pushNamed(CarWidget.routeName);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildSummaryBar(context),
      ],
    );
  }

  Widget _buildSummaryBar(BuildContext context) {
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
                    '0ttnj4jl' /* Total amount: */,
                  ),
                  style: typography.titleSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$_totalAmount${FFLocalizations.of(context).getText(
                  '64mbfw71' /* ر.س  */,
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
              'em74sqch' /* Book now */,
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
          'annspca1' /* YOU ARE BROWSING NOW */,
        ),
        countryName: FFAppState().naimdolh,
        changeLabel: FFLocalizations.of(context).getText(
          'mcloprue' /* Change country */,
        ),
        onChangeCountry: () async {
          context.pushNamed(LISTCountriesWidget.routeName);
        },
      ),
      items: [
        _DrawerActionTile(
          icon: DsIcons.location,
          title: FFLocalizations.of(context).getText(
            'c0x39i45' /* You are currently browsing. */,
          ),
          subtitle: FFAppState().naimvillatext,
        ),
        _DrawerActionTile(
          icon: DsIcons.map,
          title: FFAppState().naimmdenh,
          subtitle: FFLocalizations.of(context).getText(
            'nqmjfztr' /* Go now. */,
          ),
          onTap: () async {
            context.pushNamed(ListWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.playlist_add_check_rounded,
          title: FFLocalizations.of(context).getText(
            'uf8tvdq8' /* Added destinations */,
          ),
          badge: FFAppState().addcart.toString(),
          onTap: () async {
            context.pushNamed(Checkout66CopyWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.bookings,
          title: FFLocalizations.of(context).getText(
            '337nk4yr' /* My bookings */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            '2gie7hge' /* Booking list. */,
          ),
          onTap: () async {
            context.pushNamed(List22TaskOverviewResponsiveWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.mail_outline_rounded,
          title: FFLocalizations.of(context).getText(
            'i4f9c0gs' /* رسائل جديدة */,
          ),
          badge: FFLocalizations.of(context).getText(
            'jnlfevn6' /* 0 */,
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
            '35vq7cxk' /* Settings */,
          ),
          onTap: () async {
            context.pushNamed(Profile05Widget.routeName);
          },
        ),
      ],
      footer: _DrawerLogoutButton(
        label: FFLocalizations.of(context).getText(
          '3vd0zode' /* Log Out */,
        ),
        onTap: () => _logout(context),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cart pieces
// -----------------------------------------------------------------------------

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.itemRef,
    required this.cityName,
    required this.onRemove,
  });

  final DocumentReference itemRef;
  final String cityName;
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
            child: FutureBuilder<MkanRecord>(
              future: MkanRecord.getDocumentOnce(itemRef),
              builder: (context, snapshot) {
                // Customize what your widget looks like when it's loading.
                if (!snapshot.hasData) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DsShimmer(width: 140, height: 18),
                      SizedBox(height: DsSpacing.xxs),
                      DsShimmer(width: 90, height: 14),
                    ],
                  );
                }

                final columnMkanRecord = snapshot.data!;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      columnMkanRecord.naim,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Text(
                      formatNumber(
                        columnMkanRecord.sr,
                        formatType: FormatType.decimal,
                        decimalType: DecimalType.automatic,
                        currency: 'ر.س ',
                      ),
                      style: typography.labelLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
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

class _CarSelectionCard extends StatelessWidget {
  const _CarSelectionCard({
    required this.carName,
    required this.hint,
    required this.onTap,
  });

  final String carName;
  final String hint;
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
            child: Icon(DsIcons.car, size: DsIcons.sm, color: colors.primary),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text(
                  hint,
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

class _DrawerLogoutButton extends StatelessWidget {
  const _DrawerLogoutButton({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xs,
            vertical: DsSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: DsIcons.sm,
                color: colors.error,
              ),
              const SizedBox(width: DsSpacing.sm),
              Text(
                label,
                style: typography.titleSmall.copyWith(color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
