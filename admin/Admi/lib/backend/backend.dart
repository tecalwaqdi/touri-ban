import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_auth/auth_util.dart';

import '../flutter_flow/flutter_flow_util.dart';
import 'schema/util/firestore_util.dart';

import 'schema/countries_record.dart';
import 'schema/cities_record.dart';
import 'schema/villages_record.dart';
import 'schema/user_record.dart';
import 'schema/mkan_record.dart';
import 'schema/classification_record.dart';
import 'schema/cart_record.dart';
import 'schema/type_car_record.dart';
import 'schema/order_record.dart';
import 'schema/auto_num_record.dart';
import 'schema/cart_maps_record.dart';
import 'schema/mapmap_record.dart';
import 'schema/order_mkss_record.dart';
import 'schema/mkss_record.dart';
import 'schema/adressuser_record.dart';
import 'schema/listamaknorder_record.dart';
import 'schema/order2_record.dart';
import 'schema/mkan2_record.dart';
import 'schema/ordaercart_record.dart';
import 'schema/list_address_record.dart';
import 'schema/idlistorder_record.dart';
import 'schema/demodelet_record.dart';
import 'schema/support_record.dart';
import 'schema/settings_record.dart';
import 'schema/transport_company_record.dart';

export 'dart:async' show StreamSubscription;
export 'package:cloud_firestore/cloud_firestore.dart' hide Order;
export 'package:firebase_core/firebase_core.dart';
export 'schema/index.dart';
export 'schema/util/firestore_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/countries_record.dart';
export 'schema/cities_record.dart';
export 'schema/villages_record.dart';
export 'schema/user_record.dart';
export 'schema/mkan_record.dart';
export 'schema/classification_record.dart';
export 'schema/cart_record.dart';
export 'schema/type_car_record.dart';
export 'schema/order_record.dart';
export 'schema/auto_num_record.dart';
export 'schema/cart_maps_record.dart';
export 'schema/mapmap_record.dart';
export 'schema/order_mkss_record.dart';
export 'schema/mkss_record.dart';
export 'schema/adressuser_record.dart';
export 'schema/listamaknorder_record.dart';
export 'schema/order2_record.dart';
export 'schema/mkan2_record.dart';
export 'schema/ordaercart_record.dart';
export 'schema/list_address_record.dart';
export 'schema/idlistorder_record.dart';
export 'schema/demodelet_record.dart';
export 'schema/support_record.dart';
export 'schema/settings_record.dart';
export 'schema/transport_company_record.dart';

/// Functions to query CountriesRecords (as a Stream and as a Future).
Future<int> queryCountriesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CountriesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CountriesRecord>> queryCountriesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      CountriesRecord.collection,
      CountriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CountriesRecord>> queryCountriesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CountriesRecord.collection,
      CountriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query CitiesRecords (as a Stream and as a Future).
Future<int> queryCitiesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CitiesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CitiesRecord>> queryCitiesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      CitiesRecord.collection,
      CitiesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CitiesRecord>> queryCitiesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CitiesRecord.collection,
      CitiesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query VillagesRecords (as a Stream and as a Future).
Future<int> queryVillagesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      VillagesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<VillagesRecord>> queryVillagesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      VillagesRecord.collection,
      VillagesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<VillagesRecord>> queryVillagesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      VillagesRecord.collection,
      VillagesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query UserRecords (as a Stream and as a Future).
Future<int> queryUserRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UserRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UserRecord>> queryUserRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UserRecord.collection,
      UserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UserRecord>> queryUserRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UserRecord.collection,
      UserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query MkanRecords (as a Stream and as a Future).
Future<int> queryMkanRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MkanRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MkanRecord>> queryMkanRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MkanRecord.collection,
      MkanRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MkanRecord>> queryMkanRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MkanRecord.collection,
      MkanRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ClassificationRecords (as a Stream and as a Future).
Future<int> queryClassificationRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ClassificationRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ClassificationRecord>> queryClassificationRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ClassificationRecord.collection,
      ClassificationRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ClassificationRecord>> queryClassificationRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ClassificationRecord.collection,
      ClassificationRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query CartRecords (as a Stream and as a Future).
Future<int> queryCartRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CartRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CartRecord>> queryCartRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      CartRecord.collection,
      CartRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CartRecord>> queryCartRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CartRecord.collection,
      CartRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query TypeCarRecords (as a Stream and as a Future).
Future<int> queryTypeCarRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      TypeCarRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<TypeCarRecord>> queryTypeCarRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<TypeCarRecord>> queryTypeCarRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query OrderRecords (as a Stream and as a Future).
Future<int> queryOrderRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      OrderRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<OrderRecord>> queryOrderRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      OrderRecord.collection,
      OrderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrderRecord>> queryOrderRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      OrderRecord.collection,
      OrderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AutoNumRecords (as a Stream and as a Future).
Future<int> queryAutoNumRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AutoNumRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AutoNumRecord>> queryAutoNumRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AutoNumRecord.collection,
      AutoNumRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AutoNumRecord>> queryAutoNumRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AutoNumRecord.collection,
      AutoNumRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query CartMapsRecords (as a Stream and as a Future).
Future<int> queryCartMapsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CartMapsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CartMapsRecord>> queryCartMapsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      CartMapsRecord.collection,
      CartMapsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CartMapsRecord>> queryCartMapsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CartMapsRecord.collection,
      CartMapsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query MapmapRecords (as a Stream and as a Future).
Future<int> queryMapmapRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MapmapRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MapmapRecord>> queryMapmapRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MapmapRecord.collection,
      MapmapRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MapmapRecord>> queryMapmapRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MapmapRecord.collection,
      MapmapRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query OrderMkssRecords (as a Stream and as a Future).
Future<int> queryOrderMkssRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      OrderMkssRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<OrderMkssRecord>> queryOrderMkssRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      OrderMkssRecord.collection,
      OrderMkssRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrderMkssRecord>> queryOrderMkssRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      OrderMkssRecord.collection,
      OrderMkssRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query MkssRecords (as a Stream and as a Future).
Future<int> queryMkssRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MkssRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MkssRecord>> queryMkssRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MkssRecord.collection(parent),
      MkssRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MkssRecord>> queryMkssRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MkssRecord.collection(parent),
      MkssRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AdressuserRecords (as a Stream and as a Future).
Future<int> queryAdressuserRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AdressuserRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AdressuserRecord>> queryAdressuserRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AdressuserRecord.collection,
      AdressuserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AdressuserRecord>> queryAdressuserRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AdressuserRecord.collection,
      AdressuserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ListamaknorderRecords (as a Stream and as a Future).
Future<int> queryListamaknorderRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ListamaknorderRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ListamaknorderRecord>> queryListamaknorderRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ListamaknorderRecord.collection,
      ListamaknorderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ListamaknorderRecord>> queryListamaknorderRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ListamaknorderRecord.collection,
      ListamaknorderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query Order2Records (as a Stream and as a Future).
Future<int> queryOrder2RecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      Order2Record.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<Order2Record>> queryOrder2Record({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      Order2Record.collection,
      Order2Record.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<Order2Record>> queryOrder2RecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      Order2Record.collection,
      Order2Record.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query Mkan2Records (as a Stream and as a Future).
Future<int> queryMkan2RecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      Mkan2Record.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<Mkan2Record>> queryMkan2Record({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      Mkan2Record.collection(parent),
      Mkan2Record.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<Mkan2Record>> queryMkan2RecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      Mkan2Record.collection(parent),
      Mkan2Record.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query OrdaercartRecords (as a Stream and as a Future).
Future<int> queryOrdaercartRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      OrdaercartRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<OrdaercartRecord>> queryOrdaercartRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      OrdaercartRecord.collection(parent),
      OrdaercartRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrdaercartRecord>> queryOrdaercartRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      OrdaercartRecord.collection(parent),
      OrdaercartRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ListAddressRecords (as a Stream and as a Future).
Future<int> queryListAddressRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ListAddressRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ListAddressRecord>> queryListAddressRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ListAddressRecord.collection,
      ListAddressRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ListAddressRecord>> queryListAddressRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ListAddressRecord.collection,
      ListAddressRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query IdlistorderRecords (as a Stream and as a Future).
Future<int> queryIdlistorderRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      IdlistorderRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<IdlistorderRecord>> queryIdlistorderRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      IdlistorderRecord.collection,
      IdlistorderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<IdlistorderRecord>> queryIdlistorderRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      IdlistorderRecord.collection,
      IdlistorderRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query DemodeletRecords (as a Stream and as a Future).
Future<int> queryDemodeletRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      DemodeletRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<DemodeletRecord>> queryDemodeletRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      DemodeletRecord.collection,
      DemodeletRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<DemodeletRecord>> queryDemodeletRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      DemodeletRecord.collection,
      DemodeletRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query SupportRecords (as a Stream and as a Future).
Future<int> querySupportRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      SupportRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<SupportRecord>> querySupportRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      SupportRecord.collection,
      SupportRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<SupportRecord>> querySupportRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      SupportRecord.collection,
      SupportRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query SettingsRecords (as a Stream and as a Future).
Future<int> querySettingsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      SettingsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<SettingsRecord>> querySettingsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      SettingsRecord.collection,
      SettingsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<SettingsRecord>> querySettingsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      SettingsRecord.collection,
      SettingsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query TransportCompanyRecords.
Future<int> queryTransportCompanyRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      TransportCompanyRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<TransportCompanyRecord>> queryTransportCompanyRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      TransportCompanyRecord.collection,
      TransportCompanyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<TransportCompanyRecord>> queryTransportCompanyRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      TransportCompanyRecord.collection,
      TransportCompanyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<int> queryCollectionCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool forceServer = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0) {
    query = query.limit(limit);
  }

  try {
    final aggregate = forceServer
        ? await query
            .count()
            .get(source: AggregateSource.server)
            .timeout(const Duration(seconds: 18))
        : await query.count().get().timeout(const Duration(seconds: 18));
    final count = aggregate.count;
    if (count != null) return count;
  } catch (err) {
    print('Count aggregate failed for $collection: $err');
  }

  // Light fallback only — never scan the whole collection on mobile.
  try {
    final snap = forceServer
        ? await query
            .limit(300)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 12))
        : await query.limit(300).get().timeout(const Duration(seconds: 12));
    return snap.docs.length;
  } catch (err) {
    print('Light count fallback failed: $err');
    return 0;
  }
}

Stream<List<T>> queryCollection<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots(includeMetadataChanges: false).handleError((err) {
    print('Error querying $collection: $err');
  }).map((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Future<List<T>> queryCollectionOnce<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (singleRecord) {
    query = query.limit(1);
  } else if (limit > 0) {
    query = query.limit(limit);
  } else {
    query = query.limit(100);
  }
  return query.get(const GetOptions(source: Source.serverAndCache)).then((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Filter filterIn(String field, List? list) => (list?.isEmpty ?? true)
    ? Filter(field, whereIn: null)
    : Filter(field, whereIn: list);

Filter filterArrayContainsAny(String field, List? list) =>
    (list?.isEmpty ?? true)
        ? Filter(field, arrayContainsAny: null)
        : Filter(field, arrayContainsAny: list);

extension QueryExtension on Query {
  Query whereIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereIn: null)
      : where(field, whereIn: list);

  Query whereNotIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereNotIn: null)
      : where(field, whereNotIn: list);

  Query whereArrayContainsAny(String field, List? list) =>
      (list?.isEmpty ?? true)
          ? where(field, arrayContainsAny: null)
          : where(field, arrayContainsAny: list);
}

class FFFirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FFFirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

Future<FFFirestorePage<T>> queryCollectionPage<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection).limit(pageSize);
  if (nextPageMarker != null) {
    query = query.startAfterDocument(nextPageMarker);
  }
  Stream<QuerySnapshot>? docSnapshotStream;
  QuerySnapshot docSnapshot;
  if (isStream) {
    docSnapshotStream = query.snapshots();
    docSnapshot = await docSnapshotStream.first;
  } else {
    docSnapshot = await query.get();
  }
  final getDocs = (QuerySnapshot s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
  final data = getDocs(docSnapshot);
  final dataStream = docSnapshotStream?.map(getDocs);
  final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
  return FFFirestorePage(data, dataStream, nextPageToken);
}

// Creates a Firestore document representing the logged in user if it doesn't yet exist
Future maybeCreateUser(User user) async {
  final userRecord = UserRecord.collection.doc(user.uid);
  final userExists = await userRecord
      .get()
      .timeout(const Duration(seconds: 20))
      .then((u) => u.exists)
      .catchError((_) => false);
  if (userExists) {
    try {
      currentUserDocument = await UserRecord.getDocumentOnce(userRecord)
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
    return;
  }

  final userData = createUserRecordData(
    email: user.email ??
        FirebaseAuth.instance.currentUser?.email ??
        user.providerData.firstOrNull?.email,
    displayName:
        user.displayName ?? FirebaseAuth.instance.currentUser?.displayName,
    photoUrl: user.photoURL,
    uid: user.uid,
    phoneNumber: user.phoneNumber,
    createdTime: getCurrentTimestamp,
  );

  await userRecord
      .set(userData)
      .timeout(const Duration(seconds: 20));
  currentUserDocument = UserRecord.getDocumentFromData(userData, userRecord);
}

Future updateUserDocument({String? email}) async {
  await currentUserDocument?.reference
      .update(createUserRecordData(email: email));
}
