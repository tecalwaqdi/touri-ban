import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/toury_notification_localizer.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'chat2_model.dart';

export 'chat2_model.dart';

class Chat2Widget extends StatefulWidget {
  const Chat2Widget({
    super.key,
    required this.idorder,
    this.naimMndob,
    this.phoneMndob,
    this.imgMndob,
    required this.idmndob,
  });

  final DocumentReference? idorder;
  final String? naimMndob;
  final int? phoneMndob;
  final String? imgMndob;
  final DocumentReference? idmndob;

  static String routeName = 'chat2';
  static String routePath = '/chat2';

  @override
  State<Chat2Widget> createState() => _Chat2WidgetState();
}

class _Chat2WidgetState extends State<Chat2Widget> {
  late Chat2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Chat2Model());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (_model.textController.text != '') {
      final me = currentUserReference;
      final driver = widget.idmndob;
      final participants = <DocumentReference>[
        if (me != null) me,
        if (driver != null) driver,
      ];
      await ChatRecord.collection.doc().set(createChatRecordData(
            idorder: widget.idorder,
            user1: me,
            msg: _model.textController.text,
            date: getCurrentTimestamp,
            naim: currentUserDisplayName,
            participants: participants,
          ));
      if (widget.idmndob != null) {
        final recipient = await UserRecord.getDocumentOnce(
          widget.idmndob!,
        );
        final recipientLocale =
            TouryNotificationLocalizer.localeForUser(recipient);
        triggerPushNotification(
          notificationTitle: await TouryNotificationLocalizer.text(
            recipientLocale,
            'notification_private_message_title',
          ),
          notificationText: _model.textController.text,
          userRefs: [widget.idmndob!],
          initialPageName: 'List',
          parameterData: const {},
        );
        await WatcCall.call(
          to: widget.phoneMndob?.toString(),
          msg: await TouryNotificationLocalizer.text(
            recipientLocale,
            'notification_private_message_body',
            args: {
              'sender': currentUserDisplayName,
            },
          ),
        );
      }
      safeSetState(() {
        _model.textController?.clear();
      });
    } else {
      DsSnackBar.show(
        context,
        message: 'ui_text_b73e88df71'.tr(),
        tone: DsSnackTone.error,
      );
    }
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
                centerTitle: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
                titleWidget: Row(
                  children: [
                    Container(
                      width: DsConstants.avatarSm,
                      height: DsConstants.avatarSm,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primarySoft,
                      ),
                      child: Image(
                        fit: BoxFit.cover,
                        image: touryNetworkImageProvider(
                          widget.imgMndob,
                          fallbackAsset: 'assets/images/torytaxi.png',
                        ),
                      ),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(
                        valueOrDefault<String>(
                          widget.naimMndob,
                          '-',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if ((widget.phoneMndob ?? 0) > 0)
                    DsIconButton(
                      icon: Icons.phone_outlined,
                      size: DsIcons.sm,
                      filled: true,
                      onPressed: () async {
                        var phone = widget.phoneMndob!.toString();
                        if (!phone.startsWith('0') && phone.length <= 10) {
                          phone = '0$phone';
                        }
                        await launchUrl(Uri(scheme: 'tel', path: phone));
                      },
                    ),
                  const SizedBox(width: DsSpacing.md),
                ],
              ),
              body: SafeArea(
                top: true,
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<ChatRecord>>(
                        stream: queryChatRecord(
                          queryBuilder: (chatRecord) {
                            var q = chatRecord.where(
                              'idorder',
                              isEqualTo: widget.idorder,
                            );
                            // Prefer participant-scoped query so list rules
                            // can be proven without widening access.
                            if (currentUserReference != null) {
                              q = q.where(
                                'participants',
                                arrayContains: currentUserReference,
                              );
                            }
                            return q.orderBy('date', descending: true);
                          },
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const DsLoading();
                          }
                          if (snapshot.hasError) {
                            return DsErrorState(
                              title: 'order_chat_load_error_title'.tr(),
                              message: 'order_chat_load_error_msg'.tr(),
                              retryLabel: 'ux_retry'.tr(),
                              onRetry: () => safeSetState(() {}),
                            );
                          }
                          final listViewChatRecordList =
                              snapshot.data ?? const <ChatRecord>[];

                          if (listViewChatRecordList.isEmpty) {
                            return DsEmptyState(
                              icon: DsIcons.chat,
                              title: valueOrDefault<String>(
                                widget.naimMndob,
                                '-',
                              ),
                              message: FFLocalizations.of(context).getText(
                                'yvnt7xqi' /* Type your message... */,
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.xs,
                            ),
                            physics: const BouncingScrollPhysics(),
                            reverse: true,
                            scrollDirection: Axis.vertical,
                            itemCount: listViewChatRecordList.length,
                            itemBuilder: (context, listViewIndex) {
                              final listViewChatRecord =
                                  listViewChatRecordList[listViewIndex];
                              return _MessageBubble(
                                record: listViewChatRecord,
                                isMine: listViewChatRecord.user1 ==
                                    currentUserReference,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    _Composer(
                      controller: _model.textController,
                      focusNode: _model.textFieldFocusNode,
                      onSend: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Single chat bubble aligned by sender.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.record,
    required this.isMine,
  });

  final ChatRecord record;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final bubbleColor = isMine ? colors.primary : colors.surfaceElevated;
    final textColor = isMine ? colors.onPrimary : colors.textPrimary;
    final metaColor = isMine
        ? colors.onPrimary.withValues(alpha: 0.75)
        : colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280.0),
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: DsRadius.lgRadius,
                  topRight: DsRadius.lgRadius,
                  bottomLeft:
                      isMine ? DsRadius.lgRadius : DsRadius.xsRadius,
                  bottomRight:
                      isMine ? DsRadius.xsRadius : DsRadius.lgRadius,
                ),
                border: isMine
                    ? null
                    : Border.all(color: colors.border.withValues(alpha: 0.9)),
                boxShadow: DsShadows.soft(dark: context.dsIsDark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.naim,
                    style: typography.labelMedium.copyWith(color: metaColor),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(
                    record.msg,
                    style: typography.bodyMedium.copyWith(color: textColor),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      dateTimeFormat(
                        "jm",
                        record.date!,
                        locale: FFLocalizations.of(context).languageCode,
                      ),
                      style: typography.labelSmall.copyWith(color: metaColor),
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

/// Message input bar pinned under the conversation.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Future<void> Function(BuildContext) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.divider),
        ),
        boxShadow: DsShadows.soft(dark: context.dsIsDark),
      ),
      padding: EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.sm + bottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: DsTextField(
              controller: controller,
              focusNode: focusNode,
              hint: FFLocalizations.of(context).getText(
                'yvnt7xqi' /* Type your message... */,
              ),
              variant: DsFieldVariant.filled,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.xxs),
            child: DsIconButton(
              icon: Icons.send_rounded,
              size: DsIcons.sm,
              filled: true,
              background: colors.primary,
              foreground: colors.onPrimary,
              onPressed: () async => onSend(context),
            ),
          ),
        ],
      ),
    );
  }
}
