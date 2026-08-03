import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/toury_ngenius_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class CreateInvoiceCall {
  static Future<ApiCallResponse> call({
    String? name = '',
    int? number,
    String? amountFormat = '',
    String? osf = '',
    String? yarsCARD = '',
    String? monthCard = '',
  }) async {
    const ffApiRequestBody = '''
{
  "identityNumber": "7006309764",
  "commercialRecordNumber": "4031224235",
  "commercialRecordIssueDateHijri": "1440-07-07",
  "phoneNumber": "+966506279585",
  "extensionNumber": "1",
  "emailAddress": "ahmdrr777@gmail.com",
  "managerName": "محمد احمد امين عدنان جوير",
  "managerPhoneNumber": "+966506279585",
  "managerMobileNumber": "+966506279585",
  "activity": "SPECIALITY_TRANSPORT"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create Invoice',
      apiUrl: 'https://wasl.tga.gov.sa/api/tracking/v1/operating-companies',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': '',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? sum(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.amount_format''',
      ));
}

class ApiWasalCall {
  static Future<ApiCallResponse> call() async {
    const ffApiRequestBody = '''
{
  "sequenceNumber": "609281120",
  "driverId": "1098876947",
  "tripId": "4",
  "distanceInMeters": 5100,
  "durationInSeconds": 3600,
  "customerRating": 1,
  "customerWaitingTimeInSeconds": 5,
  "originCityNameInArabic": "حائل",
  "destinationCityNameInArabic": "حائل",
  "originLatitude": 27.499814978014555,
  "originLongitude": 41.71623955619158,
  "destinationLatitude": 27.49288666817404,
  "destinationLongitude": 41.72284851910663,
  "pickupTimestamp": "2024-11-21T12:35:00.000",
  "dropoffTimestamp": "2024-11-21T13:35:00.000",  
  "tripCost": 300,
  "startedWhen": "2024-11-20T12:35:05.000"
}
''';
    return ApiManager.instance.makeApiCall(
      callName: 'api wasal',
      apiUrl: 'https://wasl.api.elm.sa/api/dispatching/v2/trips',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'client-id': '',
        'app-id': '',
        'app-key': '',
        'Access-Control-Allow-Origin': '*',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class WatcCall {
  static Future<ApiCallResponse> call({
    String? to = '',
    String? msg = '',
  }) async {
    final data = await makeCloudCall('sendWhatsAppMessage', {
      'to': to?.trim() ?? '',
      'message': msg?.trim() ?? '',
    });
    return ApiCallResponse(
      data,
      const {},
      data.containsKey('error') ? 500 : 200,
      exception: data['error']?.toString(),
    );
  }
}

class PENmdenhCall {
  static Future<ApiCallResponse> call({
    String? io = '27.48390907229549,41.ئ728493419120994',
    String? countryCode,
    String language = 'en',
  }) async {
    final coordinates = (io ?? '').split(',');
    final latitude = coordinates.isNotEmpty
        ? double.tryParse(coordinates.first.trim())
        : null;
    final longitude =
        coordinates.length > 1 ? double.tryParse(coordinates[1].trim()) : null;
    if (latitude == null || longitude == null) {
      return ApiCallResponse(
        const {'error': 'invalid_coordinates'},
        const {},
        400,
        exception: 'invalid_coordinates',
      );
    }
    final data = await makeCloudCall('reverseGeocode', {
      'latitude': latitude,
      'longitude': longitude,
      'language': language,
      if (countryCode != null && countryCode.isNotEmpty)
        'countryCode': countryCode,
    });
    return ApiCallResponse(
      data,
      const {},
      data.containsKey('error') ? 500 : 200,
      exception: data['error']?.toString(),
    );
  }

  static dynamic _firstComponents(dynamic response) => getJsonField(
        response,
        r'''$.results[0].components''',
      );

  static String? _component(dynamic response, String key) {
    final components = _firstComponents(response);
    if (components is! Map) return null;
    final value = components[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// يستخرج اسم المدينة من عدة حقول لأن OpenCage يختلف في السعودية.
  static String? resolveCityName(dynamic response) {
    const keys = [
      'city',
      'town',
      'village',
      'municipality',
      'state_district',
      'county',
      'suburb',
      'city_district',
      'region',
    ];
    for (final key in keys) {
      final value = _component(response, key);
      if (value != null) return value;
    }
    return null;
  }

  static List<String> placeNameCandidates(dynamic response) {
    const keys = [
      'city',
      'town',
      'village',
      'municipality',
      'state_district',
      'county',
      'suburb',
      'city_district',
      'region',
      'state',
    ];
    final results = <String>{};
    for (final key in keys) {
      final value = _component(response, key);
      if (value != null) results.add(value);
    }
    return results.toList();
  }

  static String? name(dynamic response) => resolveCityName(response);
  static String? address(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.results[:].components.road''',
      ));
  static String? add(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.results[:].components.neighbourhood''',
      ));
  static String? dolh(dynamic response) => _component(response, 'country');
  static String? countryCode(dynamic response) =>
      _component(response, 'country_code')?.toLowerCase();
  static String? fullAdress(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.results[:].formatted''',
      ));
}

class NGeniusPaymentCall {
  static Future<ApiCallResponse> call({
    String? description = 'Toury booking',
    int? amount,
    String paymentPurpose = 'generic',
    String? carPath,
    String? countryPath,
    int? bookingHours,
    int? additionalHours,
    String? orderPath,
    int? extraHours,
    String? packageId,
    String? countryCode,
  }) async {
    return TouryNGeniusService.createPayment(
      description: description ?? '',
      amountHalalas: amount ?? 0,
      paymentPurpose: paymentPurpose,
      carPath: carPath,
      countryPath: countryPath,
      bookingHours: bookingHours,
      additionalHours: additionalHours,
      orderPath: orderPath,
      extraHours: extraHours,
      packageId: packageId,
      countryCode: countryCode,
    );
  }

  static String? url(dynamic response) =>
      TouryNGeniusService.transactionUrl(response) ??
      castToType<String>(getJsonField(
        response,
        r'''$.source.transaction_url''',
      ));

  static String? id(dynamic response) =>
      TouryNGeniusService.paymentId(response);
}

class NGeniusPaymentGetCall {
  static Future<ApiCallResponse> call({
    String? id = '',
  }) async {
    return TouryNGeniusService.getPayment(orderId: id?.trim() ?? '');
  }

  static String? status(dynamic response) =>
      TouryNGeniusService.status(response);

  static String? id(dynamic response) =>
      TouryNGeniusService.orderIdFromResponse(response);
}

class NGeniusPaymentRefundCall {
  static Future<ApiCallResponse> call({
    String? id = '',
    int? amountHalalas,
  }) async {
    return TouryNGeniusService.refundPayment(
      orderId: id?.trim() ?? '',
      amountHalalas: amountHalalas,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
