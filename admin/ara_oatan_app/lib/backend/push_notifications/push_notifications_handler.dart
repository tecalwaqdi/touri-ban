import 'dart:async';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/design_system/colors/ds_color_scales.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


final _handledMessageIds = <String?>{};

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({super.key, required this.child});

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
      final initialPageName = message.data['initialPageName'] as String;
      final initialParameterData = getInitialParameterData(message.data);
      final parametersBuilder = parametersBuilderMap[initialPageName];
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
            label: 'فتح',
            onPressed: () => _handlePushNotification(message),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => _loading
      ? Container(
          color: DsNeutralScale.shade0,
          child: Image.asset(
            'assets/images/torytaxi.png',
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
      (data) async => const ParameterData();
}

final parametersBuilderMap =
    <String, Future<ParameterData> Function(Map<String, dynamic>)>{
  'HomePag': ParameterData.none(),
  'Cities': (data) async => ParameterData(
        allParams: {
          'dol': getParameter<DocumentReference>(data, 'dol'),
          'textstre': getParameter<String>(data, 'textstre'),
        },
      ),
  'Citie2': (data) async => ParameterData(
        allParams: {
          'coun': getParameter<DocumentReference>(data, 'coun'),
          'naim': getParameter<String>(data, 'naim'),
          'osfdolh': getParameter<String>(data, 'osfdolh'),
          'idcit': getParameter<DocumentReference>(data, 'idcit'),
          'imgDolh': getParameter<String>(data, 'imgDolh'),
        },
      ),
  'List': ParameterData.none(),
  'Placedetails': (data) async => ParameterData(
        allParams: {
          'mk': getParameter<DocumentReference>(data, 'mk'),
          'textnaim': getParameter<String>(data, 'textnaim'),
        },
      ),
  'Profile05': ParameterData.none(),
  'update_prof': ParameterData.none(),
  'LIST_countries': ParameterData.none(),
  'Checkout3': ParameterData.none(),
  'vid': ParameterData.none(),
  'List_vi': (data) async => ParameterData(
        allParams: {
          'cite': getParameter<DocumentReference>(data, 'cite'),
        },
      ),
  'car': ParameterData.none(),
  'List22TaskOverviewResponsive': ParameterData.none(),
  'tfasel_order': (data) async => ParameterData(
        allParams: {
          'idorder': await getDocumentParameter<OrderRecord>(
              data, 'idorder', OrderRecord.fromSnapshot),
        },
      ),
  'Details24QuizPage': (data) async => ParameterData(
        allParams: {
          'usermndob': getParameter<DocumentReference>(data, 'usermndob'),
          'idordeer': getParameter<DocumentReference>(data, 'idordeer'),
          'naimMndob': getParameter<String>(data, 'naimMndob'),
        },
      ),
  'Checkout66': ParameterData.none(),
  'Checkout66Copy': ParameterData.none(),
  'abut_mdenh': ParameterData.none(),
  'addpay': ParameterData.none(),
  'List_viCopy': ParameterData.none(),
  'aldol': ParameterData.none(),
  'List_viCopyCopy': (data) async => ParameterData(
        allParams: {
          'map': getParameter<LatLng>(data, 'map'),
        },
      ),
  'view_mapCopy': (data) async => ParameterData(
        allParams: {
          'map': getParameter<LatLng>(data, 'map'),
        },
      ),
  'mapdemo': ParameterData.none(),
  'TouryCustomPlace': ParameterData.none(),
  'Listvillnow': ParameterData.none(),
  'Checkout66Copy2': ParameterData.none(),
  'addressadd': ParameterData.none(),
  'ScheduletheTrip': ParameterData.none(),
  'list_adress': ParameterData.none(),
  'panel': ParameterData.none(),
  'ERRORPAY': ParameterData.none(),
  'Selectadaddress': ParameterData.none(),
  'msg_no_adresd': ParameterData.none(),
  'edetressadd': (data) async => ParameterData(
        allParams: {
          'ed': await getDocumentParameter<AdressuserRecord>(
              data, 'ed', AdressuserRecord.fromSnapshot),
        },
      ),
  'list_adress_select': ParameterData.none(),
  'logen': ParameterData.none(),
  'demoall': ParameterData.none(),
  'oksend': ParameterData.none(),
  'Bookings': ParameterData.none(),
  'support': ParameterData.none(),
  'NewSupportTicket': ParameterData.none(),
  'ForgotPassword': ParameterData.none(),
  'ListCar': ParameterData.none(),
  'REGdrev': ParameterData.none(),
  'delet': ParameterData.none(),
  'EdetAdress2': (data) async => ParameterData(
        allParams: {
          'idad': getParameter<DocumentReference>(data, 'idad'),
        },
      ),
  'cLENT': ParameterData.none(),
  'ddd': ParameterData.none(),
  'demooo': ParameterData.none(),
  'demoooooo': ParameterData.none(),
  'regdemo': ParameterData.none(),
  'sdsd': ParameterData.none(),
  'RegCom': ParameterData.none(),
  'aaaaa': ParameterData.none(),
  'CreateAccount1Shrek': ParameterData.none(),
  'demoD': (data) async => ParameterData(
        allParams: {
          'isSpeed': getParameter<bool>(data, 'isSpeed'),
        },
      ),
  'khj': ParameterData.none(),
  'NewPlace': ParameterData.none(),
  'mndob': ParameterData.none(),
  'dddsccc': ParameterData.none(),
  'chat2': (data) async => ParameterData(
        allParams: {
          'idorder': getParameter<DocumentReference>(data, 'idorder'),
          'naimMndob': getParameter<String>(data, 'naimMndob'),
          'phoneMndob': getParameter<int>(data, 'phoneMndob'),
          'imgMndob': getParameter<String>(data, 'imgMndob'),
          'idmndob': getParameter<DocumentReference>(data, 'idmndob'),
        },
      ),
  'HomePlus': ParameterData.none(),
  'Homequick': ParameterData.none(),
  'list3': ParameterData.none(),
  'AddPaymentCard': ParameterData.none(),
  'webview': (data) async => ParameterData(
        allParams: {
          'url': getParameter<String>(data, 'url'),
        },
      ),
  'paymentConfirm': (data) async => ParameterData(
        allParams: {
          'fromWebView': getParameter<bool>(data, 'fromWebView'),
        },
      ),
  'payMoyserOK': (data) async => ParameterData(
        allParams: {
          'fromWebView': getParameter<bool>(data, 'fromWebView'),
        },
      ),
  'paymetHostre': ParameterData.none(),
  'dashbord': ParameterData.none(),
  'List_viCopy2': (data) async => ParameterData(
        allParams: {
          'cite': getParameter<DocumentReference>(data, 'cite'),
        },
      ),
  'hsab': ParameterData.none(),
  'mapTrdemo': (data) async => ParameterData(
        allParams: {
          'idd': getParameter<DocumentReference>(data, 'idd'),
        },
      ),
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
