import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_model.dart';
export 'chat_model.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    super.key,
    required this.idorder,
    this.phoneClent,
    required this.iduserclent,
  });

  final DocumentReference? idorder;
  final int? phoneClent;
  final DocumentReference? iduserclent;

  static String routeName = 'Chat';
  static String routePath = '/chat';

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late ChatModel _model;
  bool _sending = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  List<DocumentReference> _participants(DocumentReference clientRef) {
    return <DocumentReference>[
      if (currentUserReference != null) currentUserReference!,
      clientRef,
    ];
  }

  Future<void> _sendMessage({
    required DocumentReference orderRef,
    required DocumentReference clientRef,
  }) async {
    final text = _model.textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatRecord.collection.doc().set(createChatRecordData(
            idorder: orderRef,
            user1: currentUserReference,
            msg: text,
            date: getCurrentTimestamp,
            naim: currentUserDisplayName,
            participants: _participants(clientRef),
          ));
      try {
        final ping = driverTr(context, 'chat_whatsapp_driver_ping');
        await WhatCall.call(
          to: widget.phoneClent?.toString(),
          msg: ping,
        );
      } catch (_) {}
      try {
        final phoneDigits =
            currentPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        triggerPushNotification(
          notificationType: 'notification_private_message_title',
          notificationPayload: {
            'sender': currentUserDisplayName,
            'message': text,
          },
          notificationSound: 'default',
          userRefs: [clientRef],
          // Customer maps Chat → chat2; also accept Login1 alias.
          initialPageName: 'Chat',
          parameterData: {
            'idorder': orderRef,
            // chat2 params (customer app):
            'naimMndob': currentUserDisplayName,
            'phoneMndob': int.tryParse(phoneDigits),
            'imgMndob': currentUserPhoto,
            'idmndob': currentUserReference,
          },
        );
      } catch (_) {}
      if (!mounted) return;
      safeSetState(() {
        _model.textController?.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            driverTr(context, 'Something went wrong. Please try again.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderRef = widget.idorder;
    final clientRef = widget.iduserclent;

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          if (orderRef == null || clientRef == null) {
            return Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                centerTitle: false,
                leading: DsIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
                title: FFLocalizations.of(context).getText(
                  '7h5d8vnk' /* Chat */,
                ),
              ),
              body: SafeArea(
                child: Center(
                  child: Text(
                    driverTr(
                      context,
                      'Could not open chat: missing data',
                    ),
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                centerTitle: false,
                leading: DsIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
                title: FFLocalizations.of(context).getText(
                  '7h5d8vnk' /* Chat */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: DriverContentWidth(
                  child: StreamBuilder<OrderRecord>(
                    stream: OrderRecord.getDocument(orderRef),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const DsLoading();
                      }

                      final columnOrderRecord = snapshot.data!;

                      return Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                              vertical: DsSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: DriverNetworkImage(
                                    url: columnOrderRecord.imgProfileClent,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                DsSpacing.gapSm,
                                Expanded(
                                  child: Text(
                                    columnOrderRecord.naimUserText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.titleMedium.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DsSpacing.gapSm,
                                DsIconButton(
                                  icon: Icons.call_rounded,
                                  filled: true,
                                  onPressed: () async {
                                    final phone =
                                        widget.phoneClent?.toString().trim() ??
                                            '';
                                    if (phone.isEmpty) return;
                                    await launchUrl(Uri(
                                      scheme: 'tel',
                                      path: '966$phone',
                                    ));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: colors.scaffold,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                DsSpacing.md,
                                DsSpacing.md,
                                DsSpacing.md,
                                0,
                              ),
                              child: StreamBuilder<List<ChatRecord>>(
                                stream: queryChatRecord(
                                  queryBuilder: (chatRecord) {
                                    var q = chatRecord.where(
                                      'idorder',
                                      isEqualTo: orderRef,
                                    );
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
                                      title: driverTr(
                                        context,
                                        'Failed to open chat',
                                      ),
                                      message: driverTr(
                                        context,
                                        'Check your connection and try again.',
                                      ),
                                      retryLabel: driverTr(context, 'Retry'),
                                      onRetry: () => safeSetState(() {}),
                                    );
                                  }
                                  List<ChatRecord> listViewChatRecordList =
                                      snapshot.data ?? const <ChatRecord>[];

                                  if (listViewChatRecordList.isEmpty) {
                                    return DsEmptyState(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      title: columnOrderRecord.naimUserText,
                                      message: FFLocalizations.of(context)
                                          .getText(
                                        'mejzih35' /* Type a message... */,
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    reverse: true,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount: listViewChatRecordList.length,
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewChatRecord =
                                          listViewChatRecordList[listViewIndex];
                                      final isMine = currentUserReference ==
                                          listViewChatRecord.user1;
                                      final text =
                                          listViewChatRecord.msg.trim();
                                      if (text.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final bubbleColor = isMine
                                          ? colors.primary
                                          : (context.dsIsDark
                                              ? colors.surfaceElevated
                                              : const Color(0xFFEEF2F6));
                                      final textColor = isMine
                                          ? colors.onPrimary
                                          : colors.textPrimary;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: DsSpacing.sm,
                                          left: DsSpacing.md,
                                          right: DsSpacing.md,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: isMine
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMine &&
                                                listViewChatRecord.naim
                                                    .trim()
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                  left: 4,
                                                  right: 4,
                                                ),
                                                child: Text(
                                                  listViewChatRecord.naim
                                                      .trim(),
                                                  style: typography.labelMedium
                                                      .copyWith(
                                                    color: colors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            Align(
                                              alignment: isMine
                                                  ? AlignmentDirectional
                                                      .centerEnd
                                                  : AlignmentDirectional
                                                      .centerStart,
                                              child: Container(
                                                constraints: BoxConstraints(
                                                  maxWidth: MediaQuery.sizeOf(
                                                              context)
                                                          .width *
                                                      0.78,
                                                ),
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  14,
                                                  10,
                                                  14,
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bubbleColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            18),
                                                    topRight:
                                                        const Radius.circular(
                                                            18),
                                                    bottomLeft:
                                                        Radius.circular(
                                                            isMine ? 18 : 4),
                                                    bottomRight:
                                                        Radius.circular(
                                                            isMine ? 4 : 18),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.06),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      text,
                                                      style: typography
                                                          .bodyMedium
                                                          .copyWith(
                                                        color: textColor,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional
                                                              .centerEnd,
                                                      child: Text(
                                                        listViewChatRecord
                                                                    .date ==
                                                                null
                                                            ? ''
                                                            : dateTimeFormat(
                                                                'jm',
                                                                listViewChatRecord
                                                                    .date!,
                                                                locale:
                                                                    FFLocalizations.of(
                                                                  context,
                                                                ).languageCode,
                                                              ),
                                                        style: typography
                                                            .labelSmall
                                                            .copyWith(
                                                          color: isMine
                                                              ? colors
                                                                  .onPrimary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.75)
                                                              : colors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },

                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border(
                              top: BorderSide(color: colors.border),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.sm,
                              DsSpacing.md,
                              DsSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _model.textController,
                                    focusNode: _model.textFieldFocusNode,
                                    onFieldSubmitted: (_) async {
                                      await _sendMessage(
                                        orderRef: orderRef,
                                        clientRef: clientRef,
                                      );
                                    },
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      hintText: FFLocalizations.of(context)
                                          .getText(
                                        'mejzih35' /* Type a message... */,
                                      ),
                                      hintStyle: typography.bodyMedium.copyWith(
                                        color: colors.hint,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: colors.border,
                                        ),
                                        borderRadius: DsRadius.pill,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: colors.primary,
                                        ),
                                        borderRadius: DsRadius.pill,
                                      ),
                                      filled: true,
                                      fillColor: colors.scaffold,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: DsSpacing.lg,
                                        vertical: DsSpacing.sm,
                                      ),
                                    ),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 4,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    cursorColor: colors.primary,
                                    validator: _model.textControllerValidator
                                        .asValidator(context),
                                  ),
                                ),
                                DsSpacing.gapSm,
                                DsIconButton(
                                  icon: Icons.send_rounded,
                                  filled: true,
                                  background: colors.primary,
                                  foreground: colors.onPrimary,
                                  onPressed: _sending
                                      ? null
                                      : () async {
                                          await _sendMessage(
                                            orderRef: orderRef,
                                            clientRef: clientRef,
                                          );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
