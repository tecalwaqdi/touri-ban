import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '/backend/gemini/gemini.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'abut_mdenh_model.dart';

export 'abut_mdenh_model.dart';

class AbutMdenhWidget extends StatefulWidget {
  const AbutMdenhWidget({super.key});

  static String routeName = 'abut_mdenh';
  static String routePath = '/abutMdenh';

  @override
  State<AbutMdenhWidget> createState() => _AbutMdenhWidgetState();
}

class _AbutMdenhWidgetState extends State<AbutMdenhWidget> {
  late AbutMdenhModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AbutMdenhModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final weatherPrompt = valueOrDefault<String>(
        'اريد حالة الاجواء و مميزات الطقس لهذه المدينة بشكل عام واهم مايميز المدينة من ناحية سياحية  (ذكرت لك الدولة و المنطقة والمدينة اذكرلي وصف عن المدينة المذكورة وارجوا عدم ذكر اي مقدمات اريد وصف بشكل جذاب وجميل )${FFAppState().naimdolh}${FFAppState().naimmdenh}${FFAppState().naimvillatext}',
        'يرجى الإنتظار ...',
      );
      final tipsPrompt = valueOrDefault<String>(
        '${FFAppState().naimdolh}${FFAppState().naimvillatext}${FFAppState().naimmdenh}انا سائح الى هذه الوجهة والى المدينة تحديدا  اكتبلي نصائح عامة وبدون مقدمات بشكل مختصر على شكل نقاط عند زيارة هذه المدينة اليوم: مثل حالة الجو واللبس الأفضل كذلك  الثقافات المعروفة عندهم وأفضل الطرق للتعامل مع الناس هناك كسائح',
        '-',
      );

      final results = await Future.wait([
        geminiGenerateText(context, weatherPrompt),
        geminiGenerateText(context, tipsPrompt),
      ]);

      if (!mounted) return;
      safeSetState(() {
        _model.osfHrarh = results[0];
        _model.nsayh = results[1];
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.select<FFAppState, (String, String, String)>(
      (s) => (s.naimmdenh, s.naimvillatext, s.naimdolh),
    );

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return TouryAdaptiveScope(
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: FFAppState().naimvillatext,
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: DsFadeSlide(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CityHero(
                          city: FFAppState().naimmdenh,
                          village: FFAppState().naimvillatext,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.md,
                            DsSpacing.md,
                            0,
                          ),
                          child: DsCard(
                            elevated: true,
                            padding: DsSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_outlined,
                                      size: DsIcons.sm,
                                      color: colors.warning,
                                    ),
                                    const SizedBox(width: DsSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        FFAppState().naimmdenh,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.titleMedium.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: DsSpacing.sm),
                                if (_model.osfHrarh == null ||
                                    _model.osfHrarh!.trim().isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: DsSpacing.md,
                                    ),
                                    child: DsLoading(size: DsIcons.md),
                                  )
                                else
                                  Text(
                                    _model.osfHrarh!,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: DsSpacing.md,
                            vertical: DsSpacing.md,
                          ),
                          child: DsDivider(),
                        ),
                        DsSectionHeader(
                          title: "general tips when visiting this city today:"
                              .tr(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.xs,
                            DsSpacing.md,
                            DsSpacing.huge,
                          ),
                          child: DsCard(
                            color: colors.infoContainer,
                            bordered: false,
                            padding: DsSpacing.cardPadding,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tips_and_updates_outlined,
                                  size: DsIcons.sm,
                                  color: colors.info,
                                ),
                                const SizedBox(width: DsSpacing.xs),
                                Expanded(
                                  child: (_model.nsayh == null ||
                                          _model.nsayh!.trim().isEmpty)
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: DsSpacing.sm,
                                          ),
                                          child: DsLoading(size: DsIcons.md),
                                        )
                                      : Text(
                                          _model.nsayh!,
                                          style:
                                              typography.bodyMedium.copyWith(
                                            color: colors.textPrimary,
                                            height: 1.45,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _CityHero extends StatelessWidget {
  const _CityHero({
    required this.city,
    required this.village,
  });

  final String city;
  final String village;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    // Text always sits on a dark scrim, so pick the light-side token.
    final onScrim = context.dsIsDark ? colors.textPrimary : colors.onPrimary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: DsRadius.xlRadius),
      child: SizedBox(
        height: DsConstants.heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TouryVillageHeroBanner(
              height: DsConstants.heroHeight,
              width: double.infinity,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.scrim.withValues(alpha: 0.15),
                    colors.scrim.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    city,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.headlineMedium.copyWith(color: onScrim),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        DsIcons.location,
                        size: DsIcons.xs,
                        color: onScrim.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: DsSpacing.xxs),
                      Flexible(
                        child: Text(
                          village,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyMedium.copyWith(
                            color: onScrim.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
