import 'dart:async';
import 'dart:convert';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../index.dart';
import '../../main.dart';

final _handledMessageIds = <String?>{};

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

  Future _handlePushNotification(RemoteMessage message) async {
    if (_handledMessageIds.contains(message.messageId)) {
      return;
    }
    _handledMessageIds.add(message.messageId);

    safeSetState(() => _loading = true);
    try {
      final rawPageName = message.data['initialPageName'] as String;
      final initialPageName = switch (rawPageName) {
        'tfasel_order' || 'tfaselOrser' || 'tfasel_orser' => 'TfaselOrser',
        _ => rawPageName,
      };
      final initialParameterData = getInitialParameterData(message.data);
      final parametersBuilder = parametersBuilderMap[initialPageName] ??
          parametersBuilderMap[rawPageName];
      if (parametersBuilder != null) {
        final parameterData = await parametersBuilder(initialParameterData);
        if (mounted) {
          context.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        } else {
          appNavigatorKey.currentContext?.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      safeSetState(() => _loading = false);
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
      if (ctx == null) return;
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
            label: 'Open',
            onPressed: () => _handlePushNotification(message),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => _loading
      ? Container(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          child: Image.asset(
            'assets/images/logoTory.png',
            fit: BoxFit.contain,
          ),
        )
      : widget.child;
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
              getParameter<DocumentReference>(data, 'idorder'),
        },
      ),
  // Customer/driver legacy push routes
  'tfasel_order': (data) async => ParameterData(
        allParams: {
          'id': getParameter<DocumentReference>(data, 'id') ??
              getParameter<DocumentReference>(data, 'idorder'),
        },
      ),
  'tfaselOrser': (data) async => ParameterData(
        allParams: {
          'id': getParameter<DocumentReference>(data, 'id') ??
              getParameter<DocumentReference>(data, 'idorder'),
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
    final parameterDataStr = data['parameterData'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    print('Error parsing parameter data: $e');
    return {};
  }
}
