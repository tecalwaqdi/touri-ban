// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AmaknCostmStruct extends FFFirebaseStruct {
  AmaknCostmStruct({
    String? naim,
    String? address,
    double? sr,
    DocumentReference? user,
    LatLng? loceshn,
    String? textivill,
    List<DocumentReference>? mkanRev,
    DocumentReference? dolh,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _naim = naim,
        _address = address,
        _sr = sr,
        _user = user,
        _loceshn = loceshn,
        _textivill = textivill,
        _mkanRev = mkanRev,
        _dolh = dolh,
        super(firestoreUtilData);

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  set naim(String? val) => _naim = val;

  bool hasNaim() => _naim != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  set address(String? val) => _address = val;

  bool hasAddress() => _address != null;

  // "sr" field.
  double? _sr;
  double get sr => _sr ?? 0.0;
  set sr(double? val) => _sr = val;

  void incrementSr(double amount) => sr = sr + amount;

  bool hasSr() => _sr != null;

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  set user(DocumentReference? val) => _user = val;

  bool hasUser() => _user != null;

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  set loceshn(LatLng? val) => _loceshn = val;

  bool hasLoceshn() => _loceshn != null;

  // "textivill" field.
  String? _textivill;
  String get textivill => _textivill ?? '';
  set textivill(String? val) => _textivill = val;

  bool hasTextivill() => _textivill != null;

  // "mkan_rev" field.
  List<DocumentReference>? _mkanRev;
  List<DocumentReference> get mkanRev => _mkanRev ?? const [];
  set mkanRev(List<DocumentReference>? val) => _mkanRev = val;

  void updateMkanRev(Function(List<DocumentReference>) updateFn) {
    updateFn(_mkanRev ??= []);
  }

  bool hasMkanRev() => _mkanRev != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  set dolh(DocumentReference? val) => _dolh = val;

  bool hasDolh() => _dolh != null;

  static AmaknCostmStruct fromMap(Map<String, dynamic> data) =>
      AmaknCostmStruct(
        naim: data['naim'] as String?,
        address: data['address'] as String?,
        sr: castToType<double>(data['sr']),
        user: data['user'] as DocumentReference?,
        loceshn: data['loceshn'] as LatLng?,
        textivill: data['textivill'] as String?,
        mkanRev: getDataList(data['mkan_rev']),
        dolh: data['dolh'] as DocumentReference?,
      );

  static AmaknCostmStruct? maybeFromMap(dynamic data) => data is Map
      ? AmaknCostmStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'naim': _naim,
        'address': _address,
        'sr': _sr,
        'user': _user,
        'loceshn': _loceshn,
        'textivill': _textivill,
        'mkan_rev': _mkanRev,
        'dolh': _dolh,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'naim': serializeParam(
          _naim,
          ParamType.String,
        ),
        'address': serializeParam(
          _address,
          ParamType.String,
        ),
        'sr': serializeParam(
          _sr,
          ParamType.double,
        ),
        'user': serializeParam(
          _user,
          ParamType.DocumentReference,
        ),
        'loceshn': serializeParam(
          _loceshn,
          ParamType.LatLng,
        ),
        'textivill': serializeParam(
          _textivill,
          ParamType.String,
        ),
        'mkan_rev': serializeParam(
          _mkanRev,
          ParamType.DocumentReference,
          isList: true,
        ),
        'dolh': serializeParam(
          _dolh,
          ParamType.DocumentReference,
        ),
      }.withoutNulls;

  static AmaknCostmStruct fromSerializableMap(Map<String, dynamic> data) =>
      AmaknCostmStruct(
        naim: deserializeParam(
          data['naim'],
          ParamType.String,
          false,
        ),
        address: deserializeParam(
          data['address'],
          ParamType.String,
          false,
        ),
        sr: deserializeParam(
          data['sr'],
          ParamType.double,
          false,
        ),
        user: deserializeParam(
          data['user'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['user'],
        ),
        loceshn: deserializeParam(
          data['loceshn'],
          ParamType.LatLng,
          false,
        ),
        textivill: deserializeParam(
          data['textivill'],
          ParamType.String,
          false,
        ),
        mkanRev: deserializeParam<DocumentReference>(
          data['mkan_rev'],
          ParamType.DocumentReference,
          true,
          collectionNamePath: ['mkan'],
        ),
        dolh: deserializeParam(
          data['dolh'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['countries'],
        ),
      );

  @override
  String toString() => 'AmaknCostmStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is AmaknCostmStruct &&
        naim == other.naim &&
        address == other.address &&
        sr == other.sr &&
        user == other.user &&
        loceshn == other.loceshn &&
        textivill == other.textivill &&
        listEquality.equals(mkanRev, other.mkanRev) &&
        dolh == other.dolh;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([naim, address, sr, user, loceshn, textivill, mkanRev, dolh]);
}

AmaknCostmStruct createAmaknCostmStruct({
  String? naim,
  String? address,
  double? sr,
  DocumentReference? user,
  LatLng? loceshn,
  String? textivill,
  DocumentReference? dolh,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AmaknCostmStruct(
      naim: naim,
      address: address,
      sr: sr,
      user: user,
      loceshn: loceshn,
      textivill: textivill,
      dolh: dolh,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AmaknCostmStruct? updateAmaknCostmStruct(
  AmaknCostmStruct? amaknCostm, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    amaknCostm
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAmaknCostmStructData(
  Map<String, dynamic> firestoreData,
  AmaknCostmStruct? amaknCostm,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (amaknCostm == null) {
    return;
  }
  if (amaknCostm.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && amaknCostm.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final amaknCostmData = getAmaknCostmFirestoreData(amaknCostm, forFieldValue);
  final nestedData = amaknCostmData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = amaknCostm.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAmaknCostmFirestoreData(
  AmaknCostmStruct? amaknCostm, [
  bool forFieldValue = false,
]) {
  if (amaknCostm == null) {
    return {};
  }
  final firestoreData = mapToFirestore(amaknCostm.toMap());

  // Add any Firestore field values
  amaknCostm.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAmaknCostmListFirestoreData(
  List<AmaknCostmStruct>? amaknCostms,
) =>
    amaknCostms?.map((e) => getAmaknCostmFirestoreData(e, true)).toList() ?? [];
