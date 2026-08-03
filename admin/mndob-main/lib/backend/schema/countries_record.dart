import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CountriesRecord extends FirestoreRecord {
  CountriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  bool? _saudi;
  bool get saudi => _saudi ?? false;
  bool hasSaudi() => _saudi != null;

  String? _naimEnglesh;
  String get naimEnglesh => _naimEnglesh ?? '';
  bool hasNaimEnglesh() => _naimEnglesh != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
    _saudi = snapshotData['saudi'] as bool?;
    _naimEnglesh = snapshotData['naimEnglesh'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('countries');

  static Future<CountriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CountriesRecord.fromSnapshot(s));

  static CountriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CountriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );
}
