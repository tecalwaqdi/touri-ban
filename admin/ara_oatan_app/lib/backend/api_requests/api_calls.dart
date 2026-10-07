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
    return const ApiCallResponse(
      {'error': 'LEGACY_TRACKING_DIRECT_CALL_DISABLED'},
      {},
      410,
      exception: 'LEGACY_TRACKING_DIRECT_CALL_DISABLED',
    );
  }

  static String? sum(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.amount_format''',
      ));
}

class ApiWasalCall {
  static Future<ApiCallResponse> call() async {
    return const ApiCallResponse(
      {'error': 'DIRECT_WASL_DISPATCH_DISABLED'},
      {},
      410,
      exception: 'DIRECT_WASL_DISPATCH_DISABLED',
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
