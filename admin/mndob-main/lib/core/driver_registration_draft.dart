import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local draft so registration survives back navigation and app restart.
/// Guest drafts and per-uid drafts are stored separately (no cross-user leak).
class DriverRegistrationDraft {
  const DriverRegistrationDraft({
    this.step = 0,
    this.name = '',
    this.idNumber = '',
    this.email = '',
    this.mobile = '',
    this.vehicleName = '',
    this.model = '',
    this.plate = '',
    this.lat,
    this.lng,
    this.photoUrl = '',
    this.idImageUrl = '',
    this.carImageUrl = '',
    this.countryIso = '',
    this.cityName = '',
    this.regionPath = '',
    this.regionName = '',
    this.villagePath = '',
    this.villageName = '',
    this.color = '',
    this.seats = '',
    this.birthDateIso = '',
    this.uid = '',
    this.affiliationType = 'independent',
    this.companyPath = '',
    this.companyName = '',
    this.isTourGuide = false,
    this.guidePermitUrl = '',
  });

  final int step;
  final String name;
  final String idNumber;
  final String email;
  final String mobile;
  final String vehicleName;
  final String model;
  final String plate;
  final double? lat;
  final double? lng;
  final String photoUrl;
  final String idImageUrl;
  final String carImageUrl;
  final String countryIso;
  final String cityName;
  final String regionPath;
  final String regionName;
  final String villagePath;
  final String villageName;
  final String color;
  final String seats;
  final String birthDateIso;
  final String uid;

  /// `'independent'` | `'company'`
  final String affiliationType;
  final String companyPath;
  final String companyName;
  final bool isTourGuide;
  final String guidePermitUrl;

  static const _guestKey = 'driver_registration_draft_v1_guest';
  static String _uidKey(String uid) => 'driver_registration_draft_v1_u_$uid';

  bool get hasContent =>
      name.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      mobile.trim().isNotEmpty ||
      idNumber.trim().isNotEmpty ||
      vehicleName.trim().isNotEmpty ||
      plate.trim().isNotEmpty ||
      color.trim().isNotEmpty ||
      birthDateIso.trim().isNotEmpty ||
      regionPath.trim().isNotEmpty ||
      villagePath.trim().isNotEmpty ||
      companyPath.trim().isNotEmpty ||
      guidePermitUrl.trim().isNotEmpty ||
      isTourGuide ||
      affiliationType == 'company' ||
      (lat != null && lng != null);

  Map<String, dynamic> toJson() => {
        'step': step,
        'name': name,
        'idNumber': idNumber,
        'email': email,
        'mobile': mobile,
        'vehicleName': vehicleName,
        'model': model,
        'plate': plate,
        'lat': lat,
        'lng': lng,
        'photoUrl': photoUrl,
        'idImageUrl': idImageUrl,
        'carImageUrl': carImageUrl,
        'countryIso': countryIso,
        'cityName': cityName,
        'regionPath': regionPath,
        'regionName': regionName,
        'villagePath': villagePath,
        'villageName': villageName,
        'color': color,
        'seats': seats,
        'birthDateIso': birthDateIso,
        'uid': uid,
        'affiliationType': affiliationType,
        'companyPath': companyPath,
        'companyName': companyName,
        'isTourGuide': isTourGuide,
        'guidePermitUrl': guidePermitUrl,
      };

  factory DriverRegistrationDraft.fromJson(Map<String, dynamic> json) {
    final rawAffiliation = (json['affiliationType'] as String?) ?? 'independent';
    final affiliation =
        rawAffiliation == 'company' ? 'company' : 'independent';
    return DriverRegistrationDraft(
      step: (json['step'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      idNumber: (json['idNumber'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      mobile: (json['mobile'] as String?) ?? '',
      vehicleName: (json['vehicleName'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      plate: (json['plate'] as String?) ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      photoUrl: (json['photoUrl'] as String?) ?? '',
      idImageUrl: (json['idImageUrl'] as String?) ?? '',
      carImageUrl: (json['carImageUrl'] as String?) ?? '',
      countryIso: (json['countryIso'] as String?) ?? '',
      cityName: (json['cityName'] as String?) ?? '',
      regionPath: (json['regionPath'] as String?) ?? '',
      regionName: (json['regionName'] as String?) ?? '',
      villagePath: (json['villagePath'] as String?) ?? '',
      villageName: (json['villageName'] as String?) ?? '',
      color: (json['color'] as String?) ?? '',
      seats: (json['seats'] as String?) ?? '',
      birthDateIso: (json['birthDateIso'] as String?) ?? '',
      uid: (json['uid'] as String?) ?? '',
      affiliationType: affiliation,
      companyPath: (json['companyPath'] as String?) ?? '',
      companyName: (json['companyName'] as String?) ?? '',
      isTourGuide: json['isTourGuide'] == true,
      guidePermitUrl: (json['guidePermitUrl'] as String?) ?? '',
    );
  }

  DriverRegistrationDraft copyWith({
    int? step,
    String? name,
    String? idNumber,
    String? email,
    String? mobile,
    String? vehicleName,
    String? model,
    String? plate,
    double? lat,
    double? lng,
    String? photoUrl,
    String? idImageUrl,
    String? carImageUrl,
    String? countryIso,
    String? cityName,
    String? regionPath,
    String? regionName,
    String? villagePath,
    String? villageName,
    String? color,
    String? seats,
    String? birthDateIso,
    String? uid,
    String? affiliationType,
    String? companyPath,
    String? companyName,
    bool? isTourGuide,
    String? guidePermitUrl,
    bool clearLocation = false,
    bool clearCompany = false,
  }) {
    return DriverRegistrationDraft(
      step: step ?? this.step,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      vehicleName: vehicleName ?? this.vehicleName,
      model: model ?? this.model,
      plate: plate ?? this.plate,
      lat: clearLocation ? null : (lat ?? this.lat),
      lng: clearLocation ? null : (lng ?? this.lng),
      photoUrl: photoUrl ?? this.photoUrl,
      idImageUrl: idImageUrl ?? this.idImageUrl,
      carImageUrl: carImageUrl ?? this.carImageUrl,
      countryIso: countryIso ?? this.countryIso,
      cityName: cityName ?? this.cityName,
      regionPath: clearLocation ? '' : (regionPath ?? this.regionPath),
      regionName: clearLocation ? '' : (regionName ?? this.regionName),
      villagePath: clearLocation ? '' : (villagePath ?? this.villagePath),
      villageName: clearLocation ? '' : (villageName ?? this.villageName),
      color: color ?? this.color,
      seats: seats ?? this.seats,
      birthDateIso: birthDateIso ?? this.birthDateIso,
      uid: uid ?? this.uid,
      affiliationType: affiliationType ?? this.affiliationType,
      companyPath: clearCompany ? '' : (companyPath ?? this.companyPath),
      companyName: clearCompany ? '' : (companyName ?? this.companyName),
      isTourGuide: isTourGuide ?? this.isTourGuide,
      guidePermitUrl: guidePermitUrl ?? this.guidePermitUrl,
    );
  }

  /// Load draft for [uid] if provided; otherwise guest draft only.
  /// Never returns another user's draft.
  static Future<DriverRegistrationDraft?> load({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    String? raw;
    if (uid != null && uid.isNotEmpty) {
      raw = prefs.getString(_uidKey(uid));
    } else {
      raw = prefs.getString(_guestKey);
      // Migrate legacy unscoped key once.
      if (raw == null || raw.isEmpty) {
        raw = prefs.getString('driver_registration_draft_v1');
      }
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final draft = DriverRegistrationDraft.fromJson(map);
      if (uid != null &&
          uid.isNotEmpty &&
          draft.uid.isNotEmpty &&
          draft.uid != uid) {
        return null;
      }
      return draft.hasContent || draft.step > 0 ? draft : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save({String? forUid}) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = copyWith(uid: forUid ?? uid);
    final key = (scoped.uid.isNotEmpty) ? _uidKey(scoped.uid) : _guestKey;
    await prefs.setString(key, jsonEncode(scoped.toJson()));
  }

  /// After Auth user is created: move guest draft under [uid], drop guest key.
  static Future<void> migrateGuestToUid(String uid) async {
    if (uid.isEmpty) return;
    final guest = await load();
    if (guest == null) return;
    await guest.copyWith(uid: uid).save(forUid: uid);
    await clearGuest();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    await prefs.remove('driver_registration_draft_v1');
  }

  static Future<void> clearForUid(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey(uid));
  }

  static Future<void> clearGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    await prefs.remove('driver_registration_draft_v1');
  }

  /// True when a draft should offer "Continue registration".
  static Future<bool> hasContinuableDraft({String? uid}) async {
    final d = await load(uid: uid);
    return d != null && (d.hasContent || d.step > 0);
  }
}
