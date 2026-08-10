import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'dashbord_model.dart';
export 'dashbord_model.dart';

class DashbordWidget extends StatefulWidget {
  const DashbordWidget({super.key});

  static String routeName = 'dashbord';
  static String routePath = '/dashbord';

  @override
  State<DashbordWidget> createState() => _DashbordWidgetState();
}

class _DashbordWidgetState extends State<DashbordWidget> {
  late DashbordModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashbordModel());

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
                  'i2jy5q4m' /* الإحصائيات */,
                ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        DsSpacing.md, 0.0, DsSpacing.md, 0.0),
                    child: DsIconButton(
                      icon: Icons.refresh_rounded,
                      filled: true,
                      onPressed: () {
                        print('IconButton pressed ...');
                      },
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                top: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              '4ajya2oo' /* لوحة الإحصائيات */,
                            ),
                            textAlign: TextAlign.center,
                            style: typography.headlineLarge.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'g6fjaq55' /* نظرة عامة على البيانات والمؤشر... */,
                            ),
                            textAlign: TextAlign.center,
                            style: typography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        if (currentUserEmail == '24')
                          GridView(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: DsSpacing.md,
                              mainAxisSpacing: DsSpacing.md,
                              childAspectRatio: 0.7,
                            ),
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: [
                              _StatCountCard(
                                future: queryUserRecordCount(
                                  queryBuilder: (userRecord) =>
                                      userRecord.where(
                                    'actev_mndob',
                                    isEqualTo: true,
                                  ),
                                ),
                                icon: Icons.check_circle_rounded,
                                tone: _StatTone.success,
                                badge: FFLocalizations.of(context).getText(
                                  'cqt556np' /* نشط */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  'grj69qaz' /* الكباتن المفعلين */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryUserRecordCount(
                                  queryBuilder: (userRecord) => userRecord
                                      .where(
                                        'ismndom',
                                        isEqualTo: true,
                                      )
                                      .where(
                                        'actev_mndob',
                                        isEqualTo: false,
                                      )
                                      .where(
                                        'ismndob',
                                        isEqualTo: true,
                                      ),
                                ),
                                icon: Icons.pause_circle_rounded,
                                tone: _StatTone.warning,
                                badge: FFLocalizations.of(context).getText(
                                  '6mnlijl3' /* معلق */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  'nko6kql0' /* الكباتن المعلقين */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryMkanRecordCount(
                                  queryBuilder: (mkanRecord) =>
                                      mkanRecord.where(
                                    'isShrek',
                                    isEqualTo: true,
                                  ),
                                ),
                                icon: Icons.business_rounded,
                                tone: _StatTone.primary,
                                badge: FFLocalizations.of(context).getText(
                                  '1lg465oo' /* شركاء */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  '82s025nm' /* عدد الشركاء */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryOrderRecordCount(
                                  queryBuilder: (orderRecord) =>
                                      orderRecord.where(
                                    'ALLNOW',
                                    isEqualTo: true,
                                  ),
                                ),
                                icon: DsIcons.bookings,
                                tone: _StatTone.info,
                                badge: FFLocalizations.of(context).getText(
                                  '8g7utqxi' /* طلبات */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  'bsi9t2oo' /* إجمالي الطلبات */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryMkanRecordCount(),
                                icon: DsIcons.location,
                                tone: _StatTone.primary,
                                badge: FFLocalizations.of(context).getText(
                                  '23hdom7k' /* المعالم السياحية */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  'rebzyde4' /* عدد المعالم المضافة */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryUserRecordCount(
                                  queryBuilder: (userRecord) =>
                                      userRecord.where(
                                    'actev_mndob',
                                    isEqualTo: true,
                                  ),
                                ),
                                icon: Icons.check_circle_rounded,
                                tone: _StatTone.success,
                                badge: FFLocalizations.of(context).getText(
                                  'sdpgifk9' /* نشط */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  'jby5v3ng' /* الكباتن المفعلين */,
                                ),
                              ),
                              _StatCountCard(
                                future: queryUserRecordCount(),
                                icon: Icons.check_circle_rounded,
                                tone: _StatTone.success,
                                badge: FFLocalizations.of(context).getText(
                                  'zj1c4liz' /* نشط */,
                                ),
                                caption: FFLocalizations.of(context).getText(
                                  '1v68v5fy' /* عدد المسجلين بالتطبيق */,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.trending_up_rounded,
                                tone: _StatTone.primary,
                                caption: FFLocalizations.of(context).getText(
                                  'vdwbwgjl' /* معدل النمو */,
                                ),
                                value: FFLocalizations.of(context).getText(
                                  'z6pkg8vj' /* 12.5% */,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.star_rounded,
                                tone: _StatTone.success,
                                caption: FFLocalizations.of(context).getText(
                                  '2xck4uai' /* التقييم */,
                                ),
                                value: FFLocalizations.of(context).getText(
                                  '90pmpkdi' /* 4.8 */,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.schedule_rounded,
                                tone: _StatTone.info,
                                caption: FFLocalizations.of(context).getText(
                                  'nzy1sonv' /* متوسط الوقت */,
                                ),
                                value: FFLocalizations.of(context).getText(
                                  'r4xajzjc' /* 25 دقيقة */,
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(width: DsSpacing.sm)),
                        ),
                      ]
                          .divide(const SizedBox(height: DsSpacing.xl))
                          .addToStart(const SizedBox(height: DsSpacing.xl))
                          .addToEnd(const SizedBox(height: DsSpacing.xl)),
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

enum _StatTone { primary, success, warning, info }

Color _toneColor(DsColors colors, _StatTone tone) {
  switch (tone) {
    case _StatTone.primary:
      return colors.primary;
    case _StatTone.success:
      return colors.success;
    case _StatTone.warning:
      return colors.warning;
    case _StatTone.info:
      return colors.info;
  }
}

class _StatCountCard extends StatelessWidget {
  const _StatCountCard({
    required this.future,
    required this.icon,
    required this.tone,
    required this.badge,
    required this.caption,
  });

  final Future<int> future;
  final IconData icon;
  final _StatTone tone;
  final String badge;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final tint = _toneColor(colors, tone);

    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsCard(
            elevated: true,
            child: Center(child: DsLoading()),
          );
        }
        int containerCount = snapshot.data!;

        return DsFadeSlide(
          child: DsCard(
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: tint, size: DsConstants.iconXl),
                    Flexible(
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.labelMedium.copyWith(color: tint),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      containerCount.toString(),
                      style: typography.headlineMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.tone,
    required this.caption,
    required this.value,
  });

  final IconData icon;
  final _StatTone tone;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final tint = _toneColor(colors, tone);

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: tint, size: DsConstants.iconMd),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.titleMedium.copyWith(color: tint),
          ),
        ].divide(const SizedBox(height: DsSpacing.xs)),
      ),
    );
  }
}
