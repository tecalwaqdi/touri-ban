import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VillagesRecord extends FirestoreRecord {
  VillagesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  // "cities" field.
  DocumentReference? _cities;
  DocumentReference? get cities => _cities;
  bool hasCities() => _cities != null;

  // "naimciteText" field.
  String? _naimciteText;
  String get naimciteText => _naimciteText ?? '';
  bool hasNaimciteText() => _naimciteText != null;

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
    _dolh = snapshotData['dolh'] as DocumentReference?;
    _cities = snapshotData['cities'] as DocumentReference?;
    _naimciteText = snapshotData['naimciteText'] as String?;
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
      FirebaseFirestore.instance.collection('villages');

  static Stream<VillagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => VillagesRecord.fromSnapshot(s));

  static Future<VillagesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => VillagesRecord.fromSnapshot(s));

  static VillagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      VillagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static VillagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      VillagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'VillagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is VillagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createVillagesRecordData({
  String? naim,
  bool? acctev,
  DocumentReference? dolh,
  DocumentReference? cities,
  String? naimciteText,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'acctev': acctev,
      'dolh': dolh,
      'cities': cities,
      'naimciteText': naimciteText,
    }.withoutNulls,
  );

  return firestoreData;
}

class VillagesRecordDocumentEquality implements Equality<VillagesRecord> {
  const VillagesRecordDocumentEquality();

  @override
  bool equals(VillagesRecord? e1, VillagesRecord? e2) {
    return e1?.naim == e2?.naim && e1?.acctev == e2?.acctev;
  }

  @override
  int hash(VillagesRecord? e) =>
      const ListEquality().hash([e?.naim, e?.acctev]);

  @override
  bool isValidKey(Object? o) => o is VillagesRecord;
}
