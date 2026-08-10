import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              body: const SafeArea(
                child: Center(
                  child: Text('تعذر فتح المحادثة: بيانات ناقصة'),
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
                                  queryBuilder: (chatRecord) => chatRecord
                                      .where(
                                        'idorder',
                                        isEqualTo: orderRef,
                                      )
                                      .orderBy('date', descending: true),
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const DsLoading();
                                  }
                                  List<ChatRecord> listViewChatRecordList =
                                      snapshot.data!;

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

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: DsSpacing.xs,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              listViewChatRecord.naim,
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 280,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isMine
                                                        ? colors.primary
                                                        : colors.surface,
                                                    borderRadius:
                                                        DsRadius.large,
                                                    border: Border.all(
                                                      color: isMine
                                                          ? colors.primary
                                                          : colors.border,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: DsSpacing.md,
                                                      vertical: DsSpacing.sm,
                                                    ),
                                                    child: Text(
                                                      listViewChatRecord.msg,
                                                      style: typography
                                                          .bodyMedium
                                                          .copyWith(
                                                        color: isMine
                                                            ? colors.onPrimary
                                                            : colors
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: DsSpacing.xxs,
                                              ),
                                              child: Text(
                                                dateTimeFormat(
                                                  'jm',
                                                  listViewChatRecord.date!,
                                                  locale: FFLocalizations.of(
                                                    context,
                                                  ).languageCode,
                                                ),
                                                style: typography.bodySmall
                                                    .copyWith(
                                                  color: colors.textSecondary,
                                                  fontSize: 11,
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
                                      await ChatRecord.collection
                                          .doc()
                                          .set(createChatRecordData(
                                            idorder: orderRef,
                                            user1: currentUserReference,
                                            msg: _model.textController.text,
                                            date: getCurrentTimestamp,
                                            naim: currentUserDisplayName,
                                          ));
                                      safeSetState(() {
                                        _model.textController?.clear();
                                      });
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
                                  onPressed: () async {
                                    await ChatRecord.collection
                                        .doc()
                                        .set(createChatRecordData(
                                          idorder: orderRef,
                                          user1: currentUserReference,
                                          msg: _model.textController.text,
                                          date: getCurrentTimestamp,
                                          naim: currentUserDisplayName,
                                        ));
                                    await WhatCall.call(
                                      to: widget.phoneClent?.toString(),
                                      msg:
                                          '📩 المندوب راسلك داخل التطبيق، ادخل تفاصيل الطلب لقراءة الرسالة.اطرح سؤالك على ',
                                    );

                                    triggerPushNotification(
                                      notificationTitle:
                                          'رسالة خاصة - توري تاكسي',
                                      notificationText:
                                          _model.textController.text,
                                      notificationSound: 'default',
                                      userRefs: [clientRef],
                                      initialPageName: 'Login1',
                                      parameterData: {},
                                    );
                                    safeSetState(() {
                                      _model.textController?.clear();
                                    });
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
