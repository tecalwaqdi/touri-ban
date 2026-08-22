import 'dart:async';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../index.dart';

final _handledMessageIds = <String?>{};
final _handledOrderNavKeys = <String>{};

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  _PushNotificationsHandlerState createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  bool _loading = false;

  Future handleOpenedPushNotification() async {
    if (isWeb) {
      return;
    }

    final notification = await FirebaseMessaging.instance.getInitialMessage();
    if (notification != null) {
      await _handlePushNotification(notification);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  DocumentReference? _resolveOrderRef(Map<String, dynamic> data) {
    const keys = [
      'id',
      'idorder',
      'orderId',
      'order_id',
      'orderPath',
      'bookingId',
      'booking_id',
    ];
    for (final key in keys) {
      final fromParam = getParameter<DocumentReference>(data, key);
      if (fromParam != null) return fromParam;
      final raw = data[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isEmpty) continue;
      try {
        if (text.contains('/')) {
          return FirebaseFirestore.instance.doc(text);
        }
        return OrderRecord.collection.doc(text);
      } catch (_) {}
    }
    return null;
  }

  Future _handlePushNotification(RemoteMessage message) async {
    final dedupeKey = message.messageId ??
        '${message.data['initialPageName']}|${message.data['parameterData']}|${message.sentTime?.millisecondsSinceEpoch}';
    if (_handledMessageIds.contains(dedupeKey)) {
      return;
    }
    _handledMessageIds.add(dedupeKey);

    // Soft loading overlay only — do not replace the whole app tree (blank/logo flash).
    if (mounted) safeSetState(() => _loading = true);
    try {
      final data = Map<String, dynamic>.from(message.data);
      final initialParameterData = {
        ...getInitialParameterData(data),
        ...data,
      };

      final rawPageName =
          (data['initialPageName'] ?? data['initial_page_name'] ?? '')
              .toString()
              .trim();
      if (rawPageName.isEmpty && _resolveOrderRef(initialParameterData) == null) {
        return;
      }

      final orderRef = _resolveOrderRef(initialParameterData);
      var initialPageName = switch (rawPageName) {
        'tfasel_order' ||
        'tfaselOrser' ||
        'tfasel_orser' ||
        'TfaselOrser' =>
          'TfaselOrser',
        'Now' || 'neworder' || 'new_order' => 'Now',
        _ => rawPageName,
      };
      // Prefer opening the exact order when payload includes an id.
      if (orderRef != null &&
          (initialPageName.isEmpty ||
              initialPageName == 'Now' ||
              initialPageName == 'home' ||
              initialPageName == 'Dashboard5')) {
        initialPageName = 'TfaselOrser';
      }
      if (initialPageName.isEmpty && orderRef != null) {
        initialPageName = 'TfaselOrser';
      }
      if (initialPageName.isEmpty) {
        return;
      }

      if (orderRef != null) {
        final navKey = '${initialPageName}:${orderRef.path}';
        if (_handledOrderNavKeys.contains(navKey)) {
          return;
        }
        _handledOrderNavKeys.add(navKey);
      }

      final parametersBuilder = parametersBuilderMap[initialPageName] ??
          parametersBuilderMap[rawPageName];
      if (parametersBuilder != null) {
        final parameterData = await parametersBuilder(initialParameterData);
        final extra = Map<String, dynamic>.from(parameterData.extra);
        if (orderRef != null &&
            (initialPageName == 'TfaselOrser' ||
                initialPageName == 'tfasel_order')) {
          extra['id'] = orderRef;
        }
        final navContext = appNavigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          navContext.pushNamed(
            initialPageName == 'tfasel_order' ||
                    initialPageName == 'tfaselOrser' ||
                    initialPageName == 'tfasel_orser'
                ? 'TfaselOrser'
                : initialPageName,
            pathParameters: parameterData.pathParameters,
            queryParameters: orderRef != null
                ? {
                    'id': serializeParam(
                      orderRef,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls
                : const <String, String>{},
            extra: extra,
          );
        }
      } else if (orderRef != null) {
        final navContext = appNavigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          navContext.pushNamed(
            TfaselOrserWidget.routeName,
            queryParameters: {
              'id': serializeParam(orderRef, ParamType.DocumentReference),
            }.withoutNulls,
          );
        }
      }
    } catch (e) {
      debugPrint('Push open error: $e');
    } finally {
      if (mounted) safeSetState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handleOpenedPushNotification();
      _listenForegroundMessages();
    });
  }

  void _listenForegroundMessages() {
    if (isWeb) return;
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ??
          message.data['notification_title'] as String? ??
          'إشعار جديد';
      final body = message.notification?.body ??
          message.data['notification_text'] as String? ??
          '';
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            body.isNotEmpty ? '$title\n$body' : title,
            style: const TextStyle(fontFamily: 'cairo'),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'فتح',
            onPressed: () => _handlePushNotification(message),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_loading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: FlutterFlowTheme.of(context)
                    .secondaryBackground
                    .withValues(alpha: 0.55),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ParameterData {
  const ParameterData(
      {this.requiredParams = const {}, this.allParams = const {}});
  final Map<String, String?> requiredParams;
  final Map<String, dynamic> allParams;

  Map<String, String> get pathParameters => Map.fromEntries(
        requiredParams.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
  Map<String, dynamic> get extra => Map.fromEntries(
        allParams.entries.where((e) => e.value != null),
      );

  static Future<ParameterData> Function(Map<String, dynamic>) none() =>
      (data) async => ParameterData();
}

final parametersBuilderMap =
    <String, Future<ParameterData> Function(Map<String, dynamic>)>{
  'DriverWallet': ParameterData.none(),
  'Login1': ParameterData.none(),
  'hgzCopy': ParameterData.none(),
  'Dashboard5': ParameterData.none(),
  'Profile07': ParameterData.none(),
  'mktmlh': ParameterData.none(),
  'tfaselCopy': (data) async => ParameterData(
        allParams: {
          'idorder': getParameter<DocumentReference>(data, 'idorder'),
        },
      ),
  'hgzmgbol': ParameterData.none(),
  'hgzmktml': ParameterData.none(),
  'reg_compne': ParameterData.none(),
  'demoAI1': ParameterData.none(),
  'NewDriverRegistration': ParameterData.none(),
  'sfdf': ParameterData.none(),
  'Now': ParameterData.none(),
  'Accepted': ParameterData.none(),
  'Completed': ParameterData.none(),
  'regdrever': ParameterData.none(),
  'listvill': ParameterData.none(),
  'home': ParameterData.none(),
  'suport': ParameterData.none(),
  'TfaselOrser': (data) async => ParameterData(
        allParams: {
          'id': getParameter<DocumentReference>(data, 'id') ??
              getParameter<DocumentReference>(data, 'idorder') ??
              getParameter<DocumentReference>(data, 'orderId') ??
              getParameter<DocumentReference>(data, 'order_id'),
        },
      ),
  // Customer/driver legacy push routes
  'tfasel_order': (data) async => ParameterData(
        allParams: {
          'id': getParameter<DocumentReference>(data, 'id') ??
              getParameter<DocumentReference>(data, 'idorder') ??
              getParameter<DocumentReference>(data, 'orderId'),
        },
      ),
  'tfaselOrser': (data) async => ParameterData(
        allParams: {
          'id': getParameter<DocumentReference>(data, 'id') ??
              getParameter<DocumentReference>(data, 'idorder') ??
              getParameter<DocumentReference>(data, 'orderId'),
        },
      ),
  'dfddf': ParameterData.none(),
  'Chat': (data) async => ParameterData(
        allParams: {
          'idorder': getParameter<DocumentReference>(data, 'idorder'),
          'phoneClent': getParameter<int>(data, 'phoneClent'),
          'iduserclent': getParameter<DocumentReference>(data, 'iduserclent'),
        },
      ),
  'UpdetBank': ParameterData.none(),
  'taimrDemo': ParameterData.none(),
  'ttb3': (data) async => ParameterData(
        allParams: {
          'ido': getParameter<DocumentReference>(data, 'ido'),
        },
      ),
  'cansel': ParameterData.none(),
  'ProfileUpdatePage': ParameterData.none(),
};

Map<String, dynamic> getInitialParameterData(Map<String, dynamic> data) {
  try {
    final parameterDataStr = data['parameterData'] ?? data['parameter_data'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('Error parsing parameter data: $e');
    return {};
  }
}
