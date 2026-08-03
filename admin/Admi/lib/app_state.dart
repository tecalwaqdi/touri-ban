import 'package:flutter/material.dart';
import '/backend/backend.dart';
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
      _dolh = prefs.getString('ff_dolh')?.ref ?? _dolh;
    });
    _safeInit(() {
      _mdenh = prefs.getString('ff_mdenh')?.ref ?? _mdenh;
    });
    _safeInit(() {
      _naimdolh = prefs.getString('ff_naimdolh') ?? _naimdolh;
    });
    _safeInit(() {
      _naimmdenh = prefs.getString('ff_naimmdenh') ?? _naimmdenh;
    });
    _safeInit(() {
      _vil = prefs.getString('ff_vil')?.ref ?? _vil;
    });
    _safeInit(() {
      _cartsum = prefs.getDouble('ff_cartsum') ?? _cartsum;
    });
    _safeInit(() {
      _addcart = prefs.getInt('ff_addcart') ?? _addcart;
    });
    _safeInit(() {
      _cartItems = prefs
              .getStringList('ff_cartItems')
              ?.map((x) {
                try {
                  return CartItemStruct.fromSerializableMap(jsonDecode(x));
                } catch (e) {
                  print("Can't decode persisted data type. Error: $e.");
                  return null;
                }
              })
              .withoutNulls
              .toList() ??
          _cartItems;
    });
    _safeInit(() {
      _cart =
          prefs.getStringList('ff_cart')?.map((path) => path.ref).toList() ??
              _cart;
    });
    _safeInit(() {
      if (prefs.containsKey('ff_tmaddrhlh')) {
        try {
          final serializedData = prefs.getString('ff_tmaddrhlh') ?? '{}';
          _tmaddrhlh =
              IsAddRhlhStruct.fromSerializableMap(jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
    _safeInit(() {
      _villa = prefs.getString('ff_villa')?.ref ?? _villa;
    });
    _safeInit(() {
      _naimvillatext = prefs.getString('ff_naimvillatext') ?? _naimvillatext;
    });
    _safeInit(() {
      _tebycar = prefs.getString('ff_tebycar') ?? _tebycar;
    });
    _safeInit(() {
      _mapNEW = latLngFromString(prefs.getString('ff_mapNEW')) ?? _mapNEW;
    });
    _safeInit(() {
      _autostate = prefs.getString('ff_autostate')?.ref ?? _autostate;
    });
    _safeInit(() {
      _typecarRev = prefs.getString('ff_typecarRev')?.ref ?? _typecarRev;
    });
    _safeInit(() {
      _IMGVILL = prefs.getString('ff_IMGVILL') ?? _IMGVILL;
    });
    _safeInit(() {
      _cartmkss = prefs
              .getStringList('ff_cartmkss')
              ?.map((x) {
                try {
                  return AmaknCostmStruct.fromSerializableMap(jsonDecode(x));
                } catch (e) {
                  print("Can't decode persisted data type. Error: $e.");
                  return null;
                }
              })
              .withoutNulls
              .toList() ??
          _cartmkss;
    });
    _safeInit(() {
      _latlngvill =
          latLngFromString(prefs.getString('ff_latlngvill')) ?? _latlngvill;
    });
    _safeInit(() {
      _ismapview = prefs.getBool('ff_ismapview') ?? _ismapview;
    });
    _safeInit(() {
      _srtypecar = prefs.getInt('ff_srtypecar') ?? _srtypecar;
    });
    _safeInit(() {
      _totalsaatandcar = prefs.getInt('ff_totalsaatandcar') ?? _totalsaatandcar;
    });
    _safeInit(() {
      _isbas = prefs.getBool('ff_isbas') ?? _isbas;
    });
    _safeInit(() {
      _notcar = prefs.getString('ff_notcar') ?? _notcar;
    });
    _safeInit(() {
      _saatcar = prefs.getInt('ff_saatcar') ?? _saatcar;
    });
    _safeInit(() {
      _nodelet = prefs.getBool('ff_nodelet') ?? _nodelet;
    });
    _safeInit(() {
      _villnow = prefs.getString('ff_villnow')?.ref ?? _villnow;
    });
    _safeInit(() {
      _villtextnow = prefs.getString('ff_villtextnow') ?? _villtextnow;
    });
    _safeInit(() {
      _addhors = prefs.getInt('ff_addhors') ?? _addhors;
    });
    _safeInit(() {
      _onsaahcar = prefs.getInt('ff_onsaahcar') ?? _onsaahcar;
    });
    _safeInit(() {
      _totalsaat = prefs.getInt('ff_totalsaat') ?? _totalsaat;
    });
    _safeInit(() {
      _adressSelection =
          prefs.getString('ff_adressSelection')?.ref ?? _adressSelection;
    });
    _safeInit(() {
      _adressNaim = prefs.getString('ff_adressNaim') ?? _adressNaim;
    });
    _safeInit(() {
      _mkanuserorder = latLngFromString(prefs.getString('ff_mkanuserorder')) ??
          _mkanuserorder;
    });
    _safeInit(() {
      _akridorder = prefs.getInt('ff_akridorder') ?? _akridorder;
    });
    _safeInit(() {
      _akridorder2 = prefs.getInt('ff_akridorder2') ?? _akridorder2;
    });
    _safeInit(() {
      _dataSchedule = prefs.containsKey('ff_dataSchedule')
          ? DateTime.fromMillisecondsSinceEpoch(
              prefs.getInt('ff_dataSchedule')!)
          : _dataSchedule;
    });
    _safeInit(() {
      _taimSchedule = prefs.getString('ff_taimSchedule') ?? _taimSchedule;
    });
    _safeInit(() {
      _fulltextSchedule =
          prefs.getString('ff_fulltextSchedule') ?? _fulltextSchedule;
    });
    _safeInit(() {
      _payth = prefs.getString('ff_payth') ?? _payth;
    });
    _safeInit(() {
      _darkmode = prefs.getBool('ff_darkmode') ?? _darkmode;
    });
    _safeInit(() {
      _issereshMkan = prefs.getBool('ff_issereshMkan') ?? _issereshMkan;
    });
    _safeInit(() {
      _issereshUser = prefs.getBool('ff_issereshUser') ?? _issereshUser;
    });
    _safeInit(() {
      _isSereshREg = prefs.getBool('ff_isSereshREg') ?? _isSereshREg;
    });
    _safeInit(() {
      _RevDolh = prefs.getString('ff_RevDolh')?.ref ?? _RevDolh;
    });
    _safeInit(() {
      _RevdolhTEXT = prefs.getString('ff_RevdolhTEXT') ?? _RevdolhTEXT;
    });
    _safeInit(() {
      _RevRegTEXT = prefs.getString('ff_RevRegTEXT') ?? _RevRegTEXT;
    });
    _safeInit(() {
      _RevciteTEXT = prefs.getString('ff_RevciteTEXT') ?? _RevciteTEXT;
    });
    _safeInit(() {
      _REvCITE = prefs.getString('ff_REvCITE')?.ref ?? _REvCITE;
    });
    _safeInit(() {
      _workcite = prefs.getString('ff_workcite')?.ref ?? _workcite;
    });
    _safeInit(() {
      _workciteText = prefs.getString('ff_workciteText') ?? _workciteText;
    });
    _safeInit(() {
      _RefTepeCar = prefs.getString('ff_RefTepeCar')?.ref ?? _RefTepeCar;
    });
    _safeInit(() {
      _typeCarText = prefs.getString('ff_typeCarText') ?? _typeCarText;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  set dolh(DocumentReference? value) {
    _dolh = value;
    value != null
        ? prefs.setString('ff_dolh', value.path)
        : prefs.remove('ff_dolh');
  }

  DocumentReference? _mdenh;
  DocumentReference? get mdenh => _mdenh;
  set mdenh(DocumentReference? value) {
    _mdenh = value;
    value != null
        ? prefs.setString('ff_mdenh', value.path)
        : prefs.remove('ff_mdenh');
  }

  String _naimdolh = '';
  String get naimdolh => _naimdolh;
  set naimdolh(String value) {
    _naimdolh = value;
    prefs.setString('ff_naimdolh', value);
  }

  String _naimmdenh = '';
  String get naimmdenh => _naimmdenh;
  set naimmdenh(String value) {
    _naimmdenh = value;
    prefs.setString('ff_naimmdenh', value);
  }

  DocumentReference? _vil;
  DocumentReference? get vil => _vil;
  set vil(DocumentReference? value) {
    _vil = value;
    value != null
        ? prefs.setString('ff_vil', value.path)
        : prefs.remove('ff_vil');
  }

  double _cartsum = 0.0;
  double get cartsum => _cartsum;
  set cartsum(double value) {
    _cartsum = value;
    prefs.setDouble('ff_cartsum', value);
  }

  int _addcart = 0;
  int get addcart => _addcart;
  set addcart(int value) {
    _addcart = value;
    prefs.setInt('ff_addcart', value);
  }

  List<CartItemStruct> _cartItems = [];
  List<CartItemStruct> get cartItems => _cartItems;
  set cartItems(List<CartItemStruct> value) {
    _cartItems = value;
    prefs.setStringList(
        'ff_cartItems', value.map((x) => x.serialize()).toList());
  }

  void addToCartItems(CartItemStruct value) {
    cartItems.add(value);
    prefs.setStringList(
        'ff_cartItems', _cartItems.map((x) => x.serialize()).toList());
  }

  void removeFromCartItems(CartItemStruct value) {
    cartItems.remove(value);
    prefs.setStringList(
        'ff_cartItems', _cartItems.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromCartItems(int index) {
    cartItems.removeAt(index);
    prefs.setStringList(
        'ff_cartItems', _cartItems.map((x) => x.serialize()).toList());
  }

  void updateCartItemsAtIndex(
    int index,
    CartItemStruct Function(CartItemStruct) updateFn,
  ) {
    cartItems[index] = updateFn(_cartItems[index]);
    prefs.setStringList(
        'ff_cartItems', _cartItems.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInCartItems(int index, CartItemStruct value) {
    cartItems.insert(index, value);
    prefs.setStringList(
        'ff_cartItems', _cartItems.map((x) => x.serialize()).toList());
  }

  List<double> _cartPriceSummary = [];
  List<double> get cartPriceSummary => _cartPriceSummary;
  set cartPriceSummary(List<double> value) {
    _cartPriceSummary = value;
  }

  void addToCartPriceSummary(double value) {
    cartPriceSummary.add(value);
  }

  void removeFromCartPriceSummary(double value) {
    cartPriceSummary.remove(value);
  }

  void removeAtIndexFromCartPriceSummary(int index) {
    cartPriceSummary.removeAt(index);
  }

  void updateCartPriceSummaryAtIndex(
    int index,
    double Function(double) updateFn,
  ) {
    cartPriceSummary[index] = updateFn(_cartPriceSummary[index]);
  }

  void insertAtIndexInCartPriceSummary(int index, double value) {
    cartPriceSummary.insert(index, value);
  }

  List<DocumentReference> _cart = [];
  List<DocumentReference> get cart => _cart;
  set cart(List<DocumentReference> value) {
    _cart = value;
    prefs.setStringList('ff_cart', value.map((x) => x.path).toList());
  }

  void addToCart(DocumentReference value) {
    cart.add(value);
    prefs.setStringList('ff_cart', _cart.map((x) => x.path).toList());
  }

  void removeFromCart(DocumentReference value) {
    cart.remove(value);
    prefs.setStringList('ff_cart', _cart.map((x) => x.path).toList());
  }

  void removeAtIndexFromCart(int index) {
    cart.removeAt(index);
    prefs.setStringList('ff_cart', _cart.map((x) => x.path).toList());
  }

  void updateCartAtIndex(
    int index,
    DocumentReference Function(DocumentReference) updateFn,
  ) {
    cart[index] = updateFn(_cart[index]);
    prefs.setStringList('ff_cart', _cart.map((x) => x.path).toList());
  }

  void insertAtIndexInCart(int index, DocumentReference value) {
    cart.insert(index, value);
    prefs.setStringList('ff_cart', _cart.map((x) => x.path).toList());
  }

  bool _tm = false;
  bool get tm => _tm;
  set tm(bool value) {
    _tm = value;
  }

  IsAddRhlhStruct _tmaddrhlh =
      IsAddRhlhStruct.fromSerializableMap(jsonDecode('{\"Rhlh\":\"[]\"}'));
  IsAddRhlhStruct get tmaddrhlh => _tmaddrhlh;
  set tmaddrhlh(IsAddRhlhStruct value) {
    _tmaddrhlh = value;
    prefs.setString('ff_tmaddrhlh', value.serialize());
  }

  void updateTmaddrhlhStruct(Function(IsAddRhlhStruct) updateFn) {
    updateFn(_tmaddrhlh);
    prefs.setString('ff_tmaddrhlh', _tmaddrhlh.serialize());
  }

  DocumentReference? _villa;
  DocumentReference? get villa => _villa;
  set villa(DocumentReference? value) {
    _villa = value;
    value != null
        ? prefs.setString('ff_villa', value.path)
        : prefs.remove('ff_villa');
  }

  String _naimvillatext = '';
  String get naimvillatext => _naimvillatext;
  set naimvillatext(String value) {
    _naimvillatext = value;
    prefs.setString('ff_naimvillatext', value);
  }

  String _tebycar = '';
  String get tebycar => _tebycar;
  set tebycar(String value) {
    _tebycar = value;
    prefs.setString('ff_tebycar', value);
  }

  LatLng? _mapNEW;
  LatLng? get mapNEW => _mapNEW;
  set mapNEW(LatLng? value) {
    _mapNEW = value;
    value != null
        ? prefs.setString('ff_mapNEW', value.serialize())
        : prefs.remove('ff_mapNEW');
  }

  DocumentReference? _autostate;
  DocumentReference? get autostate => _autostate;
  set autostate(DocumentReference? value) {
    _autostate = value;
    value != null
        ? prefs.setString('ff_autostate', value.path)
        : prefs.remove('ff_autostate');
  }

  DocumentReference? _typecarRev;
  DocumentReference? get typecarRev => _typecarRev;
  set typecarRev(DocumentReference? value) {
    _typecarRev = value;
    value != null
        ? prefs.setString('ff_typecarRev', value.path)
        : prefs.remove('ff_typecarRev');
  }

  String _IMGVILL = '';
  String get IMGVILL => _IMGVILL;
  set IMGVILL(String value) {
    _IMGVILL = value;
    prefs.setString('ff_IMGVILL', value);
  }

  List<AmaknCostmStruct> _cartmkss = [];
  List<AmaknCostmStruct> get cartmkss => _cartmkss;
  set cartmkss(List<AmaknCostmStruct> value) {
    _cartmkss = value;
    prefs.setStringList(
        'ff_cartmkss', value.map((x) => x.serialize()).toList());
  }

  void addToCartmkss(AmaknCostmStruct value) {
    cartmkss.add(value);
    prefs.setStringList(
        'ff_cartmkss', _cartmkss.map((x) => x.serialize()).toList());
  }

  void removeFromCartmkss(AmaknCostmStruct value) {
    cartmkss.remove(value);
    prefs.setStringList(
        'ff_cartmkss', _cartmkss.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromCartmkss(int index) {
    cartmkss.removeAt(index);
    prefs.setStringList(
        'ff_cartmkss', _cartmkss.map((x) => x.serialize()).toList());
  }

  void updateCartmkssAtIndex(
    int index,
    AmaknCostmStruct Function(AmaknCostmStruct) updateFn,
  ) {
    cartmkss[index] = updateFn(_cartmkss[index]);
    prefs.setStringList(
        'ff_cartmkss', _cartmkss.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInCartmkss(int index, AmaknCostmStruct value) {
    cartmkss.insert(index, value);
    prefs.setStringList(
        'ff_cartmkss', _cartmkss.map((x) => x.serialize()).toList());
  }

  LatLng? _latlngvill;
  LatLng? get latlngvill => _latlngvill;
  set latlngvill(LatLng? value) {
    _latlngvill = value;
    value != null
        ? prefs.setString('ff_latlngvill', value.serialize())
        : prefs.remove('ff_latlngvill');
  }

  bool _ismapview = false;
  bool get ismapview => _ismapview;
  set ismapview(bool value) {
    _ismapview = value;
    prefs.setBool('ff_ismapview', value);
  }

  int _srtypecar = 0;
  int get srtypecar => _srtypecar;
  set srtypecar(int value) {
    _srtypecar = value;
    prefs.setInt('ff_srtypecar', value);
  }

  int _totalsaatandcar = 0;
  int get totalsaatandcar => _totalsaatandcar;
  set totalsaatandcar(int value) {
    _totalsaatandcar = value;
    prefs.setInt('ff_totalsaatandcar', value);
  }

  bool _isbas = false;
  bool get isbas => _isbas;
  set isbas(bool value) {
    _isbas = value;
    prefs.setBool('ff_isbas', value);
  }

  String _notcar = '';
  String get notcar => _notcar;
  set notcar(String value) {
    _notcar = value;
    prefs.setString('ff_notcar', value);
  }

  int _saatcar = 0;
  int get saatcar => _saatcar;
  set saatcar(int value) {
    _saatcar = value;
    prefs.setInt('ff_saatcar', value);
  }

  bool _nodelet = false;
  bool get nodelet => _nodelet;
  set nodelet(bool value) {
    _nodelet = value;
    prefs.setBool('ff_nodelet', value);
  }

  DocumentReference? _villnow;
  DocumentReference? get villnow => _villnow;
  set villnow(DocumentReference? value) {
    _villnow = value;
    value != null
        ? prefs.setString('ff_villnow', value.path)
        : prefs.remove('ff_villnow');
  }

  String _villtextnow = '';
  String get villtextnow => _villtextnow;
  set villtextnow(String value) {
    _villtextnow = value;
    prefs.setString('ff_villtextnow', value);
  }

  int _addhors = 0;
  int get addhors => _addhors;
  set addhors(int value) {
    _addhors = value;
    prefs.setInt('ff_addhors', value);
  }

  int _onsaahcar = 0;
  int get onsaahcar => _onsaahcar;
  set onsaahcar(int value) {
    _onsaahcar = value;
    prefs.setInt('ff_onsaahcar', value);
  }

  int _totalsaat = 0;
  int get totalsaat => _totalsaat;
  set totalsaat(int value) {
    _totalsaat = value;
    prefs.setInt('ff_totalsaat', value);
  }

  DocumentReference? _adressSelection;
  DocumentReference? get adressSelection => _adressSelection;
  set adressSelection(DocumentReference? value) {
    _adressSelection = value;
    value != null
        ? prefs.setString('ff_adressSelection', value.path)
        : prefs.remove('ff_adressSelection');
  }

  String _adressNaim = '';
  String get adressNaim => _adressNaim;
  set adressNaim(String value) {
    _adressNaim = value;
    prefs.setString('ff_adressNaim', value);
  }

  LatLng? _mkanuserorder;
  LatLng? get mkanuserorder => _mkanuserorder;
  set mkanuserorder(LatLng? value) {
    _mkanuserorder = value;
    value != null
        ? prefs.setString('ff_mkanuserorder', value.serialize())
        : prefs.remove('ff_mkanuserorder');
  }

  int _akridorder = 0;
  int get akridorder => _akridorder;
  set akridorder(int value) {
    _akridorder = value;
    prefs.setInt('ff_akridorder', value);
  }

  int _akridorder2 = 0;
  int get akridorder2 => _akridorder2;
  set akridorder2(int value) {
    _akridorder2 = value;
    prefs.setInt('ff_akridorder2', value);
  }

  DateTime? _dataSchedule;
  DateTime? get dataSchedule => _dataSchedule;
  set dataSchedule(DateTime? value) {
    _dataSchedule = value;
    value != null
        ? prefs.setInt('ff_dataSchedule', value.millisecondsSinceEpoch)
        : prefs.remove('ff_dataSchedule');
  }

  String _taimSchedule = '';
  String get taimSchedule => _taimSchedule;
  set taimSchedule(String value) {
    _taimSchedule = value;
    prefs.setString('ff_taimSchedule', value);
  }

  String _fulltextSchedule = '';
  String get fulltextSchedule => _fulltextSchedule;
  set fulltextSchedule(String value) {
    _fulltextSchedule = value;
    prefs.setString('ff_fulltextSchedule', value);
  }

  /// طريقة الدفع
  String _payth = '';
  String get payth => _payth;
  set payth(String value) {
    _payth = value;
    prefs.setString('ff_payth', value);
  }

  bool _darkmode = false;
  bool get darkmode => _darkmode;
  set darkmode(bool value) {
    _darkmode = value;
    prefs.setBool('ff_darkmode', value);
  }

  bool _issereshMkan = false;
  bool get issereshMkan => _issereshMkan;
  set issereshMkan(bool value) {
    _issereshMkan = value;
    prefs.setBool('ff_issereshMkan', value);
  }

  bool _issereshUser = false;
  bool get issereshUser => _issereshUser;
  set issereshUser(bool value) {
    _issereshUser = value;
    prefs.setBool('ff_issereshUser', value);
  }

  bool _isSereshREg = false;
  bool get isSereshREg => _isSereshREg;
  set isSereshREg(bool value) {
    _isSereshREg = value;
    prefs.setBool('ff_isSereshREg', value);
  }

  bool _issereshDrever = false;
  bool get issereshDrever => _issereshDrever;
  set issereshDrever(bool value) {
    _issereshDrever = value;
  }

  DocumentReference? _RevDolh;
  DocumentReference? get RevDolh => _RevDolh;
  set RevDolh(DocumentReference? value) {
    _RevDolh = value;
    value != null
        ? prefs.setString('ff_RevDolh', value.path)
        : prefs.remove('ff_RevDolh');
  }

  DocumentReference? _Revreg;
  DocumentReference? get Revreg => _Revreg;
  set Revreg(DocumentReference? value) {
    _Revreg = value;
  }

  String _RevdolhTEXT = '';
  String get RevdolhTEXT => _RevdolhTEXT;
  set RevdolhTEXT(String value) {
    _RevdolhTEXT = value;
    prefs.setString('ff_RevdolhTEXT', value);
  }

  String _RevRegTEXT = '';
  String get RevRegTEXT => _RevRegTEXT;
  set RevRegTEXT(String value) {
    _RevRegTEXT = value;
    prefs.setString('ff_RevRegTEXT', value);
  }

  String _RevciteTEXT = '';
  String get RevciteTEXT => _RevciteTEXT;
  set RevciteTEXT(String value) {
    _RevciteTEXT = value;
    prefs.setString('ff_RevciteTEXT', value);
  }

  DocumentReference? _REvCITE;
  DocumentReference? get REvCITE => _REvCITE;
  set REvCITE(DocumentReference? value) {
    _REvCITE = value;
    value != null
        ? prefs.setString('ff_REvCITE', value.path)
        : prefs.remove('ff_REvCITE');
  }

  /// مدينة العمل
  DocumentReference? _workcite;
  DocumentReference? get workcite => _workcite;
  set workcite(DocumentReference? value) {
    _workcite = value;
    value != null
        ? prefs.setString('ff_workcite', value.path)
        : prefs.remove('ff_workcite');
  }

  /// مدينة العمل كنص فقط
  String _workciteText = '';
  String get workciteText => _workciteText;
  set workciteText(String value) {
    _workciteText = value;
    prefs.setString('ff_workciteText', value);
  }

  DocumentReference? _RefTepeCar;
  DocumentReference? get RefTepeCar => _RefTepeCar;
  set RefTepeCar(DocumentReference? value) {
    _RefTepeCar = value;
    value != null
        ? prefs.setString('ff_RefTepeCar', value.path)
        : prefs.remove('ff_RefTepeCar');
  }

  String _typeCarText = '';
  String get typeCarText => _typeCarText;
  set typeCarText(String value) {
    _typeCarText = value;
    prefs.setString('ff_typeCarText', value);
  }

  DocumentReference? _mndobVillID;
  DocumentReference? get mndobVillID => _mndobVillID;
  set mndobVillID(DocumentReference? value) {
    _mndobVillID = value;
  }

  DocumentReference? _MNDOBtYPEcAR;
  DocumentReference? get MNDOBtYPEcAR => _MNDOBtYPEcAR;
  set MNDOBtYPEcAR(DocumentReference? value) {
    _MNDOBtYPEcAR = value;
  }

  String _MNDOBtextVILL = '';
  String get MNDOBtextVILL => _MNDOBtextVILL;
  set MNDOBtextVILL(String value) {
    _MNDOBtextVILL = value;
  }

  String _MNDONCARTEXT = '';
  String get MNDONCARTEXT => _MNDONCARTEXT;
  set MNDONCARTEXT(String value) {
    _MNDONCARTEXT = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}
