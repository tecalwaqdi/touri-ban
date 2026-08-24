// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class AmaknCoistmStruct extends FFFirebaseStruct {
  AmaknCoistmStruct({
    String? naim,
    String? address,
    LatLng? loceshn,
    bool? okdone,
    DocumentReference? revmkan,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _naim = naim,
        _address = address,
        _loceshn = loceshn,
        _okdone = okdone,
        _revmkan = revmkan,
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

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  set loceshn(LatLng? val) => _loceshn = val;

  bool hasLoceshn() => _loceshn != null;

  // "okdone" field.
  bool? _okdone;
  bool get okdone => _okdone ?? false;
  set okdone(bool? val) => _okdone = val;

  bool hasOkdone() => _okdone != null;

  // "Revmkan" field.
  DocumentReference? _revmkan;
  DocumentReference? get revmkan => _revmkan;
  set revmkan(DocumentReference? val) => _revmkan = val;

  bool hasRevmkan() => _revmkan != null;

  static AmaknCoistmStruct fromMap(Map<String, dynamic> data) {
    final rawName = (data['naim'] as String?)?.trim();
    final altName = (data['name'] as String?)?.trim();
    LatLng? loc = data['loceshn'] as LatLng?;
    if (loc == null && data['loceshn'] is GeoPoint) {
      final g = data['loceshn'] as GeoPoint;
      loc = LatLng(g.latitude, g.longitude);
    }
    if (loc == null) {
      final lat = castToType<double>(data['lat']) ??
          castToType<double>(data['latitude']);
      final lng = castToType<double>(data['lng']) ??
          castToType<double>(data['longitude']);
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        loc = LatLng(lat, lng);
      }
    }
    return AmaknCoistmStruct(
      naim: (rawName != null && rawName.isNotEmpty)
          ? rawName
          : (altName != null && altName.isNotEmpty ? altName : rawName),
      address: data['address'] as String?,
      loceshn: loc,
      okdone: data['okdone'] as bool?,
      revmkan: data['Revmkan'] as DocumentReference?,
    );
  }

  static AmaknCoistmStruct? maybeFromMap(dynamic data) => data is Map
      ? AmaknCoistmStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'naim': _naim,
        'address': _address,
        'loceshn': _loceshn,
        'okdone': _okdone,
        'Revmkan': _revmkan,
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
        'loceshn': serializeParam(
          _loceshn,
          ParamType.LatLng,
        ),
        'okdone': serializeParam(
          _okdone,
          ParamType.bool,
        ),
        'Revmkan': serializeParam(
          _revmkan,
          ParamType.DocumentReference,
        ),
      }.withoutNulls;

  static AmaknCoistmStruct fromSerializableMap(Map<String, dynamic> data) =>
      AmaknCoistmStruct(
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
        loceshn: deserializeParam(
          data['loceshn'],
          ParamType.LatLng,
          false,
        ),
        okdone: deserializeParam(
          data['okdone'],
          ParamType.bool,
          false,
        ),
        revmkan: deserializeParam(
          data['Revmkan'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['mkan'],
        ),
      );

  @override
  String toString() => 'AmaknCoistmStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AmaknCoistmStruct &&
        naim == other.naim &&
        address == other.address &&
        loceshn == other.loceshn &&
        okdone == other.okdone &&
        revmkan == other.revmkan;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([naim, address, loceshn, okdone, revmkan]);
}

AmaknCoistmStruct createAmaknCoistmStruct({
  String? naim,
  String? address,
  LatLng? loceshn,
  bool? okdone,
  DocumentReference? revmkan,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AmaknCoistmStruct(
      naim: naim,
      address: address,
      loceshn: loceshn,
      okdone: okdone,
      revmkan: revmkan,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AmaknCoistmStruct? updateAmaknCoistmStruct(
  AmaknCoistmStruct? amaknCoistm, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    amaknCoistm
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAmaknCoistmStructData(
  Map<String, dynamic> firestoreData,
  AmaknCoistmStruct? amaknCoistm,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (amaknCoistm == null) {
    return;
  }
  if (amaknCoistm.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && amaknCoistm.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final amaknCoistmData =
      getAmaknCoistmFirestoreData(amaknCoistm, forFieldValue);
  final nestedData =
      amaknCoistmData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = amaknCoistm.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAmaknCoistmFirestoreData(
  AmaknCoistmStruct? amaknCoistm, [
  bool forFieldValue = false,
]) {
  if (amaknCoistm == null) {
    return {};
  }
  final firestoreData = mapToFirestore(amaknCoistm.toMap());

  // Add any Firestore field values
  amaknCoistm.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAmaknCoistmListFirestoreData(
  List<AmaknCoistmStruct>? amaknCoistms,
) =>
    amaknCoistms?.map((e) => getAmaknCoistmFirestoreData(e, true)).toList() ??
    [];
