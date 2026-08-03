import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

Future<ApiCallResponse> _secureCall(
  String name,
  Map<String, dynamic> data,
) async {
  final response = await makeCloudCall(name, data);
  return ApiCallResponse(
    response,
    const {},
    response.containsKey('error') ? 500 : 200,
    exception: response['error']?.toString(),
  );
}

class WaslhaflhCall {
  static Future<ApiCallResponse> call({
    String? identityNumber = '',
    String? commercialRecordNumber = '',
    String? commercialRecordIssueDateHijri = '',
    String? phoneNumber = '',
    String? emailAddress = '',
    String? managerName = '',
    String? managerPhoneNumber = '',
    String? managerMobileNumber = '',
    String? activity = '',
    String? extensionNumber = '',
  }) {
    return _secureCall('waslRequest', {
      'action': 'operating_company',
      'payload': <String, dynamic>{
        'identityNumber': identityNumber?.trim(),
        'commercialRecordNumber': commercialRecordNumber?.trim(),
        'commercialRecordIssueDateHijri':
            commercialRecordIssueDateHijri?.trim(),
        'phoneNumber': phoneNumber?.trim(),
        'extensionNumber': extensionNumber?.trim(),
        'emailAddress': emailAddress?.trim(),
        'managerName': managerName?.trim(),
        'managerPhoneNumber': managerPhoneNumber?.trim(),
        'managerMobileNumber': managerMobileNumber?.trim(),
        'activity': activity?.trim(),
      }.withoutNulls,
    });
  }
}

class TripsRegistrationCall {
  static Future<ApiCallResponse> call({
    String? sequenceNumber = '',
    String? driverId = '',
    String? tripId = '',
    int? distanceInMeters,
    int? durationInSeconds,
    double? customerRating,
    int? customerWaitingTimeInSeconds,
    String? originLatitude = '',
    String? originLongitude = '',
    String? destinationLatitude = '',
    String? destinationLongitude = '',
    String? pickupTimestamp = '',
    String? dropoffTimestamp = '',
    String? startedWhen = '',
  }) {
    return _secureCall('waslRequest', {
      'action': 'register_trip',
      'payload': <String, dynamic>{
        'sequenceNumber': sequenceNumber?.trim(),
        'driverId': driverId?.trim(),
        'tripId': tripId?.trim(),
        'distanceInMeters': distanceInMeters,
        'durationInSeconds': durationInSeconds,
        'customerRating': customerRating,
        'customerWaitingTimeInSeconds': customerWaitingTimeInSeconds,
        'originLatitude': originLatitude?.trim(),
        'originLongitude': originLongitude?.trim(),
        'destinationLatitude': destinationLatitude?.trim(),
        'destinationLongitude': destinationLongitude?.trim(),
        'pickupTimestamp': pickupTimestamp?.trim(),
        'dropoffTimestamp': dropoffTimestamp?.trim(),
        'startedWhen': startedWhen?.trim(),
      }.withoutNulls,
    });
  }

  static String? halh(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.rejectionReasons''',
      ));
}

Map<String, dynamic> _driverPayload({
  String? identityNumber,
  String? dateOfBirthHijri,
  String? dateOfBirthGregorian,
  String? emailAddress,
  String? mobileNumber,
  String? sequenceNumber,
  String? plateLetterRight,
  String? plateLetterMiddle,
  String? plateLetterLeft,
  String? plateNumber,
  String? plateType,
}) {
  return {
    'driver': <String, dynamic>{
      'identityNumber': identityNumber?.trim(),
      'dateOfBirthHijri': dateOfBirthHijri?.trim(),
      'dateOfBirthGregorian': dateOfBirthGregorian?.trim(),
      'emailAddress': emailAddress?.trim(),
      'mobileNumber': mobileNumber?.trim(),
    }.withoutNulls,
    'vehicle': <String, dynamic>{
      'sequenceNumber': sequenceNumber?.trim(),
      'plateLetterRight': plateLetterRight?.trim(),
      'plateLetterMiddle': plateLetterMiddle?.trim(),
      'plateLetterLeft': plateLetterLeft?.trim(),
      'plateNumber': plateNumber?.trim(),
      'plateType': plateType?.trim() ?? '1',
    }.withoutNulls,
  };
}

abstract class _DriverRegistrationResponse {
  static String? halh(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.rejectionReasons''',
      ));
  static String? alahle(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.eligibility''',
      ));
  static String? reCode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.resultCode''',
      ));
  static bool? suss(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  static String? naimAr(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.driverFullNameArabic''',
      ));
  static String? naimEn(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.driverFullNameEnglish''',
      ));
}

class NewDriverRegistrationCopyCall {
  static Future<ApiCallResponse> call({
    String? identityNumber = '',
    String? dateOfBirthHijri = '',
    String? dateOfBirthGregorian = '',
    String? emailAddress = '',
    String? mobileNumber = '',
    String? sequenceNumber = '',
    String? plateLetterRight = '',
    String? plateLetterMiddle = '',
    String? plateLetterLeft = '',
    String? plateNumber = '',
    String? plateType = '1',
  }) {
    return _secureCall('waslRequest', {
      'action': 'register_driver',
      'payload': _driverPayload(
        identityNumber: identityNumber,
        dateOfBirthHijri: dateOfBirthHijri,
        dateOfBirthGregorian: dateOfBirthGregorian,
        emailAddress: emailAddress,
        mobileNumber: mobileNumber,
        sequenceNumber: sequenceNumber,
        plateLetterRight: plateLetterRight,
        plateLetterMiddle: plateLetterMiddle,
        plateLetterLeft: plateLetterLeft,
        plateNumber: plateNumber,
        plateType: plateType,
      ),
    });
  }

  static String? halh(dynamic response) =>
      _DriverRegistrationResponse.halh(response);
  static String? alahle(dynamic response) =>
      _DriverRegistrationResponse.alahle(response);
  static String? reCode(dynamic response) =>
      _DriverRegistrationResponse.reCode(response);
  static bool? suss(dynamic response) =>
      _DriverRegistrationResponse.suss(response);
  static String? naimAr(dynamic response) =>
      _DriverRegistrationResponse.naimAr(response);
  static String? naimEn(dynamic response) =>
      _DriverRegistrationResponse.naimEn(response);
}

class DemoCall {
  static Future<ApiCallResponse> call({
    String? identityNumber = '',
    String? dateOfBirthHijri = '',
    String? dateOfBirthGregorian = '',
    String? emailAddress = '',
    String? mobileNumber = '',
    String? sequenceNumber = '',
    String? plateLetterRight = '',
    String? plateLetterMiddle = '',
    String? plateLetterLeft = '',
    String? plateNumber = '',
    String? plateType = '1',
  }) {
    return NewDriverRegistrationCopyCall.call(
      identityNumber: identityNumber,
      dateOfBirthHijri: dateOfBirthHijri,
      dateOfBirthGregorian: dateOfBirthGregorian,
      emailAddress: emailAddress,
      mobileNumber: mobileNumber,
      sequenceNumber: sequenceNumber,
      plateLetterRight: plateLetterRight,
      plateLetterMiddle: plateLetterMiddle,
      plateLetterLeft: plateLetterLeft,
      plateNumber: plateNumber,
      plateType: plateType,
    );
  }

  static String? halh(dynamic response) =>
      _DriverRegistrationResponse.halh(response);
  static String? alahle(dynamic response) =>
      _DriverRegistrationResponse.alahle(response);
  static String? reCode(dynamic response) =>
      _DriverRegistrationResponse.reCode(response);
  static bool? suss(dynamic response) =>
      _DriverRegistrationResponse.suss(response);
  static dynamic rebly(dynamic response) => getJsonField(
        response,
        r'''$.result''',
      );
  static String? naimAr(dynamic response) =>
      _DriverRegistrationResponse.naimAr(response);
}

class WhatCall {
  static Future<ApiCallResponse> call({
    String? to = '',
    String? msg = '',
  }) {
    return _secureCall('sendWhatsAppMessage', {
      'to': to?.trim() ?? '',
      'message': msg?.trim() ?? '',
    });
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
