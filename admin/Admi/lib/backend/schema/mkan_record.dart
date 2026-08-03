import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MkanRecord extends FirestoreRecord {
  MkanRecord._(
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

  // "img1" field.
  String? _img1;
  String get img1 => _img1 ?? '';
  bool hasImg1() => _img1 != null;

  // "img2" field.
  String? _img2;
  String get img2 => _img2 ?? '';
  bool hasImg2() => _img2 != null;

  // "img3" field.
  String? _img3;
  String get img3 => _img3 ?? '';
  bool hasImg3() => _img3 != null;

  // "sr" field.
  int? _sr;
  int get sr => _sr ?? 0;
  bool hasSr() => _sr != null;

  // "ismsgd" field.
  bool? _ismsgd;
  bool get ismsgd => _ismsgd ?? false;
  bool hasIsmsgd() => _ismsgd != null;

  // "isfood" field.
  bool? _isfood;
  bool get isfood => _isfood ?? false;
  bool hasIsfood() => _isfood != null;

  // "ishmam" field.
  bool? _ishmam;
  bool get ishmam => _ishmam ?? false;
  bool hasIshmam() => _ishmam != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "idclassification" field.
  DocumentReference? _idclassification;
  DocumentReference? get idclassification => _idclassification;
  bool hasIdclassification() => _idclassification != null;

  // "id_cit" field.
  DocumentReference? _idCit;
  DocumentReference? get idCit => _idCit;
  bool hasIdCit() => _idCit != null;

  // "id_vill" field.
  DocumentReference? _idVill;
  DocumentReference? get idVill => _idVill;
  bool hasIdVill() => _idVill != null;

  // "Location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "user_malk" field.
  DocumentReference? _userMalk;
  DocumentReference? get userMalk => _userMalk;
  bool hasUserMalk() => _userMalk != null;

  // "ser" field.
  double? _ser;
  double get ser => _ser ?? 0.0;
  bool hasSer() => _ser != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "mdh" field.
  String? _mdh;
  String get mdh => _mdh ?? '';
  bool hasMdh() => _mdh != null;

  // "as_ads" field.
  bool? _asAds;
  bool get asAds => _asAds ?? false;
  bool hasAsAds() => _asAds != null;

  // "tsnef" field.
  String? _tsnef;
  String get tsnef => _tsnef ?? '';
  bool hasTsnef() => _tsnef != null;

  // "catgory" field.
  DocumentReference? _catgory;
  DocumentReference? get catgory => _catgory;
  bool hasCatgory() => _catgory != null;

  // "rate" field.
  double? _rate;
  double get rate => _rate ?? 0.0;
  bool hasRate() => _rate != null;

  // "add_saat" field.
  int? _addSaat;
  int get addSaat => _addSaat ?? 0;
  bool hasAddSaat() => _addSaat != null;

  // "ismzod" field.
  bool? _ismzod;
  bool get ismzod => _ismzod ?? false;
  bool hasIsmzod() => _ismzod != null;

  // "Rev_dolh" field.
  DocumentReference? _revDolh;
  DocumentReference? get revDolh => _revDolh;
  bool hasRevDolh() => _revDolh != null;

  // "isShrek" field.
  bool? _isShrek;
  bool get isShrek => _isShrek ?? false;
  bool hasIsShrek() => _isShrek != null;

  // "content_locale" field — لغة إدخال بيانات المعلم (ar, en, zh_Hans, …).
  String? _contentLocale;
  String get contentLocale => _contentLocale ?? '';
  bool hasContentLocale() => _contentLocale != null;

  // "names_i18n" field — اسم المعلم بكل اللغات.
  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};
  bool hasNamesI18n() => _namesI18n != null && _namesI18n!.isNotEmpty;

  // "osf_i18n" field — وصف المعلم بكل اللغات.
  Map<String, String>? _osfI18n;
  Map<String, String> get osfI18n => _osfI18n ?? const {};
  bool hasOsfI18n() => _osfI18n != null && _osfI18n!.isNotEmpty;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _img1 = snapshotData['img1'] as String?;
    _img2 = snapshotData['img2'] as String?;
    _img3 = snapshotData['img3'] as String?;
    _sr = castToType<int>(snapshotData['sr']);
    _ismsgd = snapshotData['ismsgd'] as bool?;
    _isfood = snapshotData['isfood'] as bool?;
    _ishmam = snapshotData['ishmam'] as bool?;
    _acctev = snapshotData['acctev'] as bool?;
    _idclassification = docRefFromFirestore(snapshotData['idclassification']);
    _idCit = docRefFromFirestore(snapshotData['id_cit']);
    _idVill = docRefFromFirestore(snapshotData['id_vill']);
    _location = snapshotData['Location'] as LatLng?;
    _userMalk = docRefFromFirestore(snapshotData['user_malk']);
    _ser = castToType<double>(snapshotData['ser']);
    _address = snapshotData['address'] as String?;
    _mdh = snapshotData['mdh'] as String?;
    _asAds = snapshotData['as_ads'] as bool?;
    _tsnef = snapshotData['tsnef'] as String?;
    _catgory = docRefFromFirestore(snapshotData['catgory']);
    _rate = castToType<double>(snapshotData['rate']);
    _addSaat = castToType<int>(snapshotData['add_saat']);
    _ismzod = snapshotData['ismzod'] as bool?;
    _revDolh = docRefFromFirestore(snapshotData['Rev_dolh']);
    _isShrek = snapshotData['isShrek'] as bool?;
    _contentLocale = snapshotData['content_locale'] as String?;
    _namesI18n = _parseI18nStringMap(snapshotData['names_i18n']);
    _osfI18n = _parseI18nStringMap(snapshotData['osf_i18n']);
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
      FirebaseFirestore.instance.collection('mkan');

  static Stream<MkanRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MkanRecord.fromSnapshot(s));

  static Future<MkanRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MkanRecord.fromSnapshot(s));

  static MkanRecord fromSnapshot(DocumentSnapshot snapshot) => MkanRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MkanRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MkanRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MkanRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MkanRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMkanRecordData({
  String? naim,
  String? osf,
  String? img1,
  String? img2,
  String? img3,
  int? sr,
  bool? ismsgd,
  bool? isfood,
  bool? ishmam,
  bool? acctev,
  DocumentReference? idclassification,
  DocumentReference? idCit,
  DocumentReference? idVill,
  LatLng? location,
  DocumentReference? userMalk,
  double? ser,
  String? address,
  String? mdh,
  bool? asAds,
  String? tsnef,
  DocumentReference? catgory,
  double? rate,
  int? addSaat,
  bool? ismzod,
  DocumentReference? revDolh,
  bool? isShrek,
  String? contentLocale,
  Map<String, String>? namesI18n,
  Map<String, String>? osfI18n,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'osf': osf,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'sr': sr,
      'ismsgd': ismsgd,
      'isfood': isfood,
      'ishmam': ishmam,
      'acctev': acctev,
      'idclassification': idclassification,
      'id_cit': idCit,
      'id_vill': idVill,
      'Location': location,
      'user_malk': userMalk,
      'ser': ser,
      'address': address,
      'mdh': mdh,
      'as_ads': asAds,
      'tsnef': tsnef,
      'catgory': catgory,
      'rate': rate,
      'add_saat': addSaat,
      'ismzod': ismzod,
      'Rev_dolh': revDolh,
      'isShrek': isShrek,
      'content_locale': contentLocale,
      'names_i18n': namesI18n,
      'osf_i18n': osfI18n,
    }.withoutNulls,
  );

  return firestoreData;
}

class MkanRecordDocumentEquality implements Equality<MkanRecord> {
  const MkanRecordDocumentEquality();

  @override
  bool equals(MkanRecord? e1, MkanRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.osf == e2?.osf &&
        e1?.img1 == e2?.img1 &&
        e1?.img2 == e2?.img2 &&
        e1?.img3 == e2?.img3 &&
        e1?.sr == e2?.sr &&
        e1?.ismsgd == e2?.ismsgd &&
        e1?.isfood == e2?.isfood &&
        e1?.ishmam == e2?.ishmam &&
        e1?.acctev == e2?.acctev &&
        e1?.idclassification == e2?.idclassification &&
        e1?.idCit == e2?.idCit &&
        e1?.idVill == e2?.idVill &&
        e1?.location == e2?.location &&
        e1?.userMalk == e2?.userMalk &&
        e1?.ser == e2?.ser &&
        e1?.address == e2?.address &&
        e1?.mdh == e2?.mdh &&
        e1?.asAds == e2?.asAds &&
        e1?.tsnef == e2?.tsnef &&
        e1?.catgory == e2?.catgory &&
        e1?.rate == e2?.rate &&
        e1?.addSaat == e2?.addSaat &&
        e1?.ismzod == e2?.ismzod &&
        e1?.revDolh == e2?.revDolh &&
        e1?.isShrek == e2?.isShrek;
  }

  @override
  int hash(MkanRecord? e) => const ListEquality().hash([
        e?.naim,
        e?.osf,
        e?.img1,
        e?.img2,
        e?.img3,
        e?.sr,
        e?.ismsgd,
        e?.isfood,
        e?.ishmam,
        e?.acctev,
        e?.idclassification,
        e?.idCit,
        e?.idVill,
        e?.location,
        e?.userMalk,
        e?.ser,
        e?.address,
        e?.mdh,
        e?.asAds,
        e?.tsnef,
        e?.catgory,
        e?.rate,
        e?.addSaat,
        e?.ismzod,
        e?.revDolh,
        e?.isShrek
      ]);

  @override
  bool isValidKey(Object? o) => o is MkanRecord;
}
