import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'dddsccc_model.dart';
export 'dddsccc_model.dart';

/// Your Delivery Agent Is On the Way!
///
/// Meet your agent and stay connected with ease:
///
/// Name: Ahmad Al-Fahad
///
/// Phone Number: +966 5 1234 5678
///
/// Car Plate Number: XYZ-1234 🚗
///
/// Unread Messages: 📩 3 New Messages
///
/// Live Chat: 💬 Tap to chat instantly
///
/// Live Location Tracking: 📍 Track in real-time
///
/// Stay updated and in control — everything you need is just a tap away!
///
/// Let me know if you want it tailored for a FlutterFlow UI or app screen
/// specifically.
class DddscccWidget extends StatefulWidget {
  const DddscccWidget({super.key});

  static String routeName = 'dddsccc';
  static String routePath = '/dddsccc';

  @override
  State<DddscccWidget> createState() => _DddscccWidgetState();
}

class _DddscccWidgetState extends State<DddscccWidget> {
  late DddscccModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DddscccModel());

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
                title: FFLocalizations.of(context).getText(
                  '68uckfrp' /* Delivery Agent */,
                ),
                automaticallyImplyLeading: false,
                leading: DsBackButton(
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.xl,
                      DsSpacing.md,
                      DsSpacing.xl,
                    ),
                    child: DsFadeSlide(
                      child: DsCard(
                        elevated: true,
                        bordered: false,
                        padding: const EdgeInsets.all(DsSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 60.0,
                                        height: 60.0,
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: const AlignmentDirectional(
                                            0.0, 0.0),
                                        child: Icon(
                                          Icons.delivery_dining_rounded,
                                          color: colors.onPrimary,
                                          size: DsConstants.iconXl,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '8jwj4nrd' /* Ahmed Al-Qahtani */,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.titleLarge
                                                  .copyWith(
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: DsSpacing.xxs),
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '8mlyyfyr' /* Delivery Agent */,
                                              ),
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ].divide(const SizedBox(width: DsSpacing.sm)),
                                  ),
                                ),
                                Container(
                                  width: 12.0,
                                  height: 12.0,
                                  decoration: BoxDecoration(
                                    color: colors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: DsSpacing.xl),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            color: colors.primary,
                                            size: DsConstants.iconSm,
                                          ),
                                          Expanded(
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'eyngyw7i' /* +966 50 123 4567 */,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ].divide(
                                            const SizedBox(width: DsSpacing.sm)),
                                      ),
                                    ),
                                    DsIconButton(
                                      icon: Icons.call_rounded,
                                      size: DsConstants.iconSm,
                                      background: colors.success,
                                      foreground: colors.onSuccess,
                                      onPressed: () {
                                        print('IconButton pressed ...');
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          SizedBox(
                                            width: DsConstants.iconSm,
                                            height: DsConstants.iconSm,
                                            child: Stack(
                                              children: [
                                                Icon(
                                                  Icons.chat_bubble_rounded,
                                                  color: colors.primary,
                                                  size: DsConstants.iconSm,
                                                ),
                                                Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          1.0, -1.0),
                                                  child: Container(
                                                    width: 8.0,
                                                    height: 8.0,
                                                    decoration: BoxDecoration(
                                                      color: colors.error,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '6uq64lr1' /* Chat Messages */,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ].divide(
                                            const SizedBox(width: DsSpacing.sm)),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: DsConstants.iconSm,
                                          height: DsConstants.iconSm,
                                          decoration: BoxDecoration(
                                            color: colors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              const AlignmentDirectional(
                                                  0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'jv7ebv03' /* 3 */,
                                            ),
                                            style: typography.labelSmall
                                                .copyWith(
                                              color: colors.onError,
                                            ),
                                          ),
                                        ),
                                        DsIconButton(
                                          icon: Icons.chat_rounded,
                                          size: DsConstants.iconSm,
                                          background: colors.primary,
                                          foreground: colors.onPrimary,
                                          onPressed: () {
                                            print('IconButton pressed ...');
                                          },
                                        ),
                                      ].divide(
                                          const SizedBox(width: DsSpacing.xs)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            DsIcons.car,
                                            color: colors.primary,
                                            size: DsConstants.iconSm,
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'ppdjkfoe' /* Vehicle Plate */,
                                                  ),
                                                  style: typography.bodyMedium
                                                      .copyWith(
                                                    color: colors.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: DsSpacing.xxs),
                                                Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    '3gv0f2mv' /* KSA | 1234 ABC */,
                                                  ),
                                                  style: typography.bodySmall
                                                      .copyWith(
                                                    color: colors.textSecondary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ].divide(
                                            const SizedBox(width: DsSpacing.sm)),
                                      ),
                                    ),
                                    Container(
                                      height: DsSpacing.xxxl,
                                      padding: DsSpacing.chipPadding,
                                      decoration: BoxDecoration(
                                        color: colors.primarySoft,
                                        borderRadius: DsRadius.pill,
                                      ),
                                      alignment:
                                          const AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'r974bacf' /* VERIFIED */,
                                        ),
                                        style: typography.labelSmall.copyWith(
                                          color: colors.primaryStrong,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: DsRadius.medium,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(DsSpacing.sm),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 8.0,
                                                height: 8.0,
                                                decoration: BoxDecoration(
                                                  color: colors.success,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'eg92mhdo' /* Live Location Tracking */,
                                                      ),
                                                      style: typography
                                                          .bodyMedium
                                                          .copyWith(
                                                        color:
                                                            colors.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: DsSpacing.xxs),
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '3k2wfl7p' /* Real-time tracking active */,
                                                      ),
                                                      style: typography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: colors.success,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ].divide(const SizedBox(
                                                width: DsSpacing.sm)),
                                          ),
                                        ),
                                        DsIconButton(
                                          icon: DsIcons.location,
                                          size: DsConstants.iconXs,
                                          background: colors.success,
                                          foreground: colors.onSuccess,
                                          onPressed: () {
                                            print('IconButton pressed ...');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.md)),
                            ),
                            const SizedBox(height: DsSpacing.xl),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: DsButton.primary(
                                    label: FFLocalizations.of(context).getText(
                                      '8q54ad0o' /* Track Location */,
                                    ),
                                    icon: Icons.my_location_rounded,
                                    expanded: true,
                                    onPressed: () {
                                      print('Button pressed ...');
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: DsButton.outlined(
                                    label: FFLocalizations.of(context).getText(
                                      'njh6wt8a' /* Call Now */,
                                    ),
                                    icon: Icons.phone_rounded,
                                    expanded: true,
                                    onPressed: () {
                                      print('Button pressed ...');
                                    },
                                  ),
                                ),
                              ].divide(const SizedBox(width: DsSpacing.sm)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
