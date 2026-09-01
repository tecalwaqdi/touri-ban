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

  // "sr" field.
  int? _sr;
  int get sr => _sr ?? 0;
  bool hasSr() => _sr != null;

  // "Location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "mdh" field.
  String? _mdh;
  String get mdh => _mdh ?? '';
  bool hasMdh() => _mdh != null;

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _img1 = snapshotData['img1'] as String?;
    _sr = castToType<int>(snapshotData['sr']);
    _location = snapshotData['Location'] as LatLng?;
    _mdh = snapshotData['mdh'] as String?;
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

  String localizedName(String languageCode) {
    final lang = languageCode.split(RegExp(r'[_-]')).first.toLowerCase();
    final map = namesI18n;
    final ordered = <String>[
      if (lang.isNotEmpty) lang,
      if (lang != 'en') 'en',
    ];
    for (final key in ordered) {
      final v = map[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    for (final entry in map.entries) {
      if (lang != 'ar' && entry.key == 'ar') continue;
      final v = entry.value.trim();
      if (v.isNotEmpty) return v;
    }
    final legacy = naim.trim();
    if (lang != 'ar' && RegExp(r'[\u0600-\u06FF]').hasMatch(legacy)) {
      final en = map['en']?.trim();
      if (en != null && en.isNotEmpty) return en;
      return '';
    }
    return legacy;
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
  int? sr,
  LatLng? location,
  String? mdh,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'osf': osf,
      'img1': img1,
      'sr': sr,
      'Location': location,
      'mdh': mdh,
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
        e1?.sr == e2?.sr &&
        e1?.location == e2?.location &&
        e1?.mdh == e2?.mdh;
  }

  @override
  int hash(MkanRecord? e) => const ListEquality()
      .hash([e?.naim, e?.osf, e?.img1, e?.sr, e?.location, e?.mdh]);

  @override
  bool isValidKey(Object? o) => o is MkanRecord;
}
