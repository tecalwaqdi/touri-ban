import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CountriesRecord extends FirestoreRecord {
  CountriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "img" field.
  String? _img;
  String get img => _img ?? '';
  bool hasImg() => _img != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "num_trteb" field.
  int? _numTrteb;
  int get numTrteb => _numTrteb ?? 0;
  bool hasNumTrteb() => _numTrteb != null;

  // "saudi" field.
  bool? _saudi;
  bool get saudi => _saudi ?? false;
  bool hasSaudi() => _saudi != null;

  // "vat_percent" field.
  double? _vatPercent;
  double get vatPercent => _vatPercent ?? 0.0;
  bool hasVatPercent() => _vatPercent != null;

  // "app_commission_percent" field.
  double? _appCommissionPercent;
  double get appCommissionPercent => _appCommissionPercent ?? 0.0;
  bool hasAppCommissionPercent() => _appCommissionPercent != null;

  // "naimEnglesh" field.
  String? _naimEnglesh;
  String get naimEnglesh => _naimEnglesh ?? '';
  bool hasNaimEnglesh() => _naimEnglesh != null;

  // "iso_code" field — ISO 3166-1 alpha-2 (SA, AE, …).
  String? _isoCode;
  String get isoCode => _isoCode ?? '';
  bool hasIsoCode() => _isoCode != null;

  // "currency_code" field — ISO 4217 (SAR, KGS, …).
  String? _currencyCode;
  String get currencyCode => _currencyCode ?? '';
  bool hasCurrencyCode() => _currencyCode != null;

  // "CurrencySymbol" field — display symbol (ر.س, сом, …).
  String? _currencySymbol;
  String get currencySymbol => _currencySymbol ?? '';
  bool hasCurrencySymbol() => _currencySymbol != null;

  // "driver_requirements" — Super Admin config map of document types.
  Map<String, dynamic>? _driverRequirements;
  Map<String, dynamic> get driverRequirements =>
      _driverRequirements ?? const {};
  bool hasDriverRequirements() =>
      _driverRequirements != null && _driverRequirements!.isNotEmpty;

  // "geo_center" field.
  LatLng? _geoCenter;
  LatLng? get geoCenter => _geoCenter;
  bool hasGeoCenter() => _geoCenter != null;

  // "bounds_sw" field — جنوب غرب الحدود.
  LatLng? _boundsSw;
  LatLng? get boundsSw => _boundsSw;
  bool hasBoundsSw() => _boundsSw != null;

  // "bounds_ne" field — شمال شرق الحدود.
  LatLng? _boundsNe;
  LatLng? get boundsNe => _boundsNe;
  bool hasBoundsNe() => _boundsNe != null;

  bool hasBounds() => hasBoundsSw() && hasBoundsNe();

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _img = snapshotData['img'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
    _numTrteb = castToType<int>(snapshotData['num_trteb']);
    _saudi = snapshotData['saudi'] as bool?;
    _vatPercent = castToType<double>(snapshotData['vat_percent']);
    // Back-compat: older docs / customer writes used `vat` + `isvat`.
    if (_vatPercent == null) {
      final legacyVat = castToType<int>(snapshotData['vat']) ??
          castToType<double>(snapshotData['vat'])?.round();
      if (legacyVat != null) {
        _vatPercent = legacyVat.toDouble();
      }
    }
    _appCommissionPercent =
        castToType<double>(snapshotData['app_commission_percent']);
    _naimEnglesh = snapshotData['naimEnglesh'] as String?;
    _isoCode = snapshotData['iso_code'] as String?;
    _currencyCode = (snapshotData['currency_code'] ??
            snapshotData['currencyCode'] ??
            snapshotData['currency'])
        ?.toString();
    _currencySymbol = (snapshotData['CurrencySymbol'] ??
            snapshotData['currency_symbol'] ??
            snapshotData['currencySymbol'])
        ?.toString();
    final rawReqs = snapshotData['driver_requirements'];
    if (rawReqs is Map) {
      _driverRequirements = Map<String, dynamic>.from(rawReqs);
    }
    _geoCenter = snapshotData['geo_center'] as LatLng?;
    _boundsSw = snapshotData['bounds_sw'] as LatLng?;
    _boundsNe = snapshotData['bounds_ne'] as LatLng?;
    _namesI18n = _parseI18nStringMap(snapshotData['names_i18n']);
  }

  static Map<String, String>? _parseI18nStringMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) out[key.toString()] = text;
    });
    return out.isEmpty ? null : out;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('countries');

  static Stream<CountriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CountriesRecord.fromSnapshot(s));

  static Future<CountriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CountriesRecord.fromSnapshot(s));

  static CountriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CountriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CountriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CountriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CountriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CountriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCountriesRecordData({
  String? naim,
  String? osf,
  String? img,
  bool? acctev,
  int? numTrteb,
  bool? saudi,
  double? vatPercent,
  double? appCommissionPercent,
  String? naimEnglesh,
  String? isoCode,
  LatLng? geoCenter,
  LatLng? boundsSw,
  LatLng? boundsNe,
  Map<String, String>? namesI18n,
  String? currencyCode,
  String? currencySymbol,
  Map<String, dynamic>? driverRequirements,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'osf': osf,
      'img': img,
      'acctev': acctev,
      'num_trteb': numTrteb,
      'saudi': saudi,
      'vat_percent': vatPercent,
      // Customer app reads legacy `vat` + `isvat` — keep both in sync.
      if (vatPercent != null) 'vat': vatPercent.round(),
      if (vatPercent != null) 'isvat': vatPercent > 0,
      'app_commission_percent': appCommissionPercent,
      'naimEnglesh': naimEnglesh,
      'iso_code': isoCode,
      'geo_center': geoCenter,
      'bounds_sw': boundsSw,
      'bounds_ne': boundsNe,
      'names_i18n': namesI18n,
      'currency_code': currencyCode,
      'CurrencySymbol': currencySymbol,
      if (driverRequirements != null) 'driver_requirements': driverRequirements,
    }.withoutNulls,
  );

  return firestoreData;
}

class CountriesRecordDocumentEquality implements Equality<CountriesRecord> {
  const CountriesRecordDocumentEquality();

  @override
  bool equals(CountriesRecord? e1, CountriesRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.osf == e2?.osf &&
        e1?.img == e2?.img &&
        e1?.acctev == e2?.acctev &&
        e1?.numTrteb == e2?.numTrteb &&
        e1?.saudi == e2?.saudi;
  }

  @override
  int hash(CountriesRecord? e) => const ListEquality()
      .hash([e?.naim, e?.osf, e?.img, e?.acctev, e?.numTrteb, e?.saudi]);

  @override
  bool isValidKey(Object? o) => o is CountriesRecord;
}
