import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'support_model.dart';
export 'support_model.dart';

class SupportWidget extends StatefulWidget {
  const SupportWidget({super.key});

  static String routeName = 'support';
  static String routePath = '/support';

  @override
  State<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends State<SupportWidget> {
  late SupportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportModel());

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
                  'isvgr34v' /* Support Tickets */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxxl,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DsConstants.maxContentWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DsFadeSlide(
                            child: DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                'dd9g01hd' /* Create New Support Ticket */,
                              ),
                              icon: DsIcons.add,
                              size: DsButtonSize.lg,
                              expanded: true,
                              onPressed: () async {
                                context
                                    .pushNamed(NewSupportTicketWidget.routeName);
                              },
                            ),
                          ),
                          const SizedBox(height: DsSpacing.lg),
                          StreamBuilder<List<SupportRecord>>(
                            stream: querySupportRecord(
                              queryBuilder: (supportRecord) => supportRecord
                                  .where(
                                    'RefUser',
                                    isEqualTo: currentUserReference,
                                  )
                                  .orderBy('data', descending: true),
                            ),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: DsSpacing.huge,
                                  ),
                                  child: DsLoading(),
                                );
                              }
                              List<SupportRecord> listViewSupportRecordList =
                                  snapshot.data!;

                              if (listViewSupportRecordList.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: DsSpacing.xl,
                                  ),
                                  child: DsEmptyState(
                                    icon: DsIcons.support,
                                    title: FFLocalizations.of(context).getText(
                                      'isvgr34v' /* Support Tickets */,
                                    ),
                                    message: FFLocalizations.of(context)
                                        .getText(
                                      'r25scvtn' /* Would you like to contact our ... */,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: listViewSupportRecordList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: DsSpacing.sm),
                                itemBuilder: (context, listViewIndex) {
                                  final listViewSupportRecord =
                                      listViewSupportRecordList[listViewIndex];
                                  return DsFadeSlide(
                                    delay: Duration(
                                      milliseconds:
                                          (listViewIndex * 40).clamp(0, 240),
                                    ),
                                    child: _SupportTicketCard(
                                      record: listViewSupportRecord,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: DsSpacing.lg),
                          DsFadeSlide(
                            delay: DsDurations.fast,
                            child: _ContactDirectlyCard(
                              onWhatsApp: () async {
                                await launchURL('https://wa.me/966533356126');
                              },
                            ),
                          ),
                        ],
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

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({required this.record});

  final SupportRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final statusLabel = valueOrDefault<String>(
      record.halh?.name,
      'لايوجد',
    );

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: DsConstants.avatarMd,
                height: DsConstants.avatarMd,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.medium,
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  size: DsIcons.sm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  'support_ticket_number'.tr(namedArgs: {
                    'id': record.id.toString(),
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: DsSpacing.xs),
              Container(
                padding: DsSpacing.chipPadding,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.pill,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: typography.labelSmall.copyWith(
                    color: colors.primaryStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            record.osf,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          const DsDivider(),
          const SizedBox(height: DsSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: DsIcons.xs,
                color: colors.iconMuted,
              ),
              const SizedBox(width: DsSpacing.xxs),
              Expanded(
                child: Text(
                  dateTimeFormat(
                    "relative",
                    record.data!,
                    locale: FFLocalizations.of(context).languageCode,
                  ),
                  style: typography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactDirectlyCard extends StatelessWidget {
  const _ContactDirectlyCard({required this.onWhatsApp});

  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DsConstants.avatarMd,
                height: DsConstants.avatarMd,
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: DsRadius.medium,
                ),
                child: Icon(
                  DsIcons.chat,
                  size: DsIcons.sm,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        'h7ebj3c9' /* Contact us directly */,
                      ),
                      style: typography.titleSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    Text(
                      FFLocalizations.of(context).getText(
                        'r25scvtn' /* Would you like to contact our ... */,
                      ),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          DsButton.success(
            label: FFLocalizations.of(context).getText(
              '9964fm48' /* WhatsApp */,
            ),
            icon: DsIcons.chat,
            expanded: true,
            onPressed: onWhatsApp,
          ),
        ],
      ),
    );
  }
}
