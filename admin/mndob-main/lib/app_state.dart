import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _okDRIVER = prefs.getBool('ff_okDRIVER') ?? _okDRIVER;
    });
    _safeInit(() {
      _startR = prefs.containsKey('ff_startR')
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_startR')!)
          : _startR;
    });
    _safeInit(() {
      _EndDate = prefs.containsKey('ff_EndDate')
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_EndDate')!)
          : _EndDate;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  bool _okDRIVER = false;
  bool get okDRIVER => _okDRIVER;
  set okDRIVER(bool value) {
    _okDRIVER = value;
    prefs.setBool('ff_okDRIVER', value);
  }

  DateTime? _startR;
  DateTime? get startR => _startR;
  set startR(DateTime? value) {
    _startR = value;
    value != null
        ? prefs.setInt('ff_startR', value.millisecondsSinceEpoch)
        : prefs.remove('ff_startR');
  }

  DocumentReference? _villmndoBREV;
  DocumentReference? get villmndoBREV => _villmndoBREV;
  set villmndoBREV(DocumentReference? value) {
    _villmndoBREV = value;
  }

  DocumentReference? _MNDOBTYPECARrev;
  DocumentReference? get MNDOBTYPECARrev => _MNDOBTYPECARrev;
  set MNDOBTYPECARrev(DocumentReference? value) {
    _MNDOBTYPECARrev = value;
  }

  String _textvill = '';
  String get textvill => _textvill;
  set textvill(String value) {
    _textvill = value;
  }

  String _textTypeCar = '';
  String get textTypeCar => _textTypeCar;
  set textTypeCar(String value) {
    _textTypeCar = value;
  }

  DateTime? _startTime = DateTime.fromMillisecondsSinceEpoch(1765898160000);
  DateTime? get startTime => _startTime;
  set startTime(DateTime? value) {
    _startTime = value;
  }

  int _durationHours = 0;
  int get durationHours => _durationHours;
  set durationHours(int value) {
    _durationHours = value;
  }

  DateTime? _EndDate = DateTime.fromMillisecondsSinceEpoch(1765909080000);
  DateTime? get EndDate => _EndDate;
  set EndDate(DateTime? value) {
    _EndDate = value;
    value != null
        ? prefs.setInt('ff_EndDate', value.millisecondsSinceEpoch)
        : prefs.remove('ff_EndDate');
  }

  DocumentReference? _revOrder;
  DocumentReference? get revOrder => _revOrder;
  set revOrder(DocumentReference? value) {
    _revOrder = value;
  }

  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  set dolh(DocumentReference? value) {
    _dolh = value;
  }

  String _naimdolh = '';
  String get naimdolh => _naimdolh;
  set naimdolh(String value) {
    _naimdolh = value;
  }

  DocumentReference? _mdenh;
  DocumentReference? get mdenh => _mdenh;
  set mdenh(DocumentReference? value) {
    _mdenh = value;
  }

  String _naimmdenh = '';
  String get naimmdenh => _naimmdenh;
  set naimmdenh(String value) {
    _naimmdenh = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
