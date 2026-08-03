
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_production_seed_data.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';

/// Result of seeding production landmarks + historical orders.
class ProductionSeedResult {
  const ProductionSeedResult({
    required this.landmarks,
    required this.orders,
    required this.regions,
    required this.cities,
    required this.supportTickets,
    this.error,
  });

  final int landmarks;
  final int orders;
  final int regions;
  final int cities;
  final int supportTickets;
  final String? error;

  bool get success => error == null;
}

/// Seeds realistic Saudi tourism data (landmarks, geo, orders over ~1 year).
class AdminProductionLandmarkSeed {
  AdminProductionLandmarkSeed._();

  static const _vehicleTypes = [
    ('sedan_standard', 'سيدان اقتصادية', 180),
    ('sedan_business', 'سيدان أعمال', 240),
    ('suv_compact', 'SUV مدمجة', 260),
    ('suv_family', 'SUV عائلية', 320),
    ('van_family', 'فان عائلي', 360),
    ('van_vip', 'فان VIP', 450),
    ('pickup_4x4', 'بيك أب 4x4', 300),
    ('luxury_suv', 'SUV فاخرة', 520),
    ('premium_sedan', 'سيدان فاخرة', 420),
    ('coach_mini', 'ميني باص', 600),
    ('coach_tour', 'باص سياحي', 900),
    ('executive_shuttle', 'شاتل تنفيذي', 700),
  ];

  static const _categories = [
    ('cat_heritage', 'تراث وثقافة'),
    ('cat_nature', 'طبيعة ومغامرات'),
    ('cat_religious', 'مواقع دينية'),
    ('cat_modern', 'معالم حديثة'),
  ];

  /// Requires super-admin session (uses current Firebase auth).
  static Future<ProductionSeedResult> run() async {
    if (!loggedIn || !AdminRoleService.isSuperAdmin) {
      return const ProductionSeedResult(
        landmarks: 0,
        orders: 0,
        regions: 0,
        cities: 0,
        supportTickets: 0,
        error: 'يتطلب تسجيل الدخول كسوبر أدمن',
      );
    }
    return _executeSeed();
  }

  /// CLI / automated seed — any authenticated Firebase user (Firestore rules).
  static Future<ProductionSeedResult> runAuthenticated() async {
    if (!loggedIn) {
      return const ProductionSeedResult(
        landmarks: 0,
        orders: 0,
        regions: 0,
        cities: 0,
        supportTickets: 0,
        error: 'يتطلب تسجيل دخول Firebase',
      );
    }
    return _executeSeed();
  }

  static Future<ProductionSeedResult> _executeSeed() async {
    try {
      final db = FirebaseFirestore.instance;
      final geo = AdminProductionSeedCatalog.geo;
      final now = DateTime.now();
      final writer = _SeedBatchWriter(db);

      final countryRef =
          db.collection('countries').doc(AdminProductionSeedCatalog.countryId);

      await writer.set(
        countryRef,
        createCountriesRecordData(
          naim: geo.countryName,
          osf: geo.countryDesc,
          acctev: true,
          saudi: true,
          vatPercent: 15,
          appCommissionPercent: 12,
          numTrteb: 1,
        ),
      );

      final regionRefs = <String, DocumentReference>{};
      final cityRefs = <String, DocumentReference>{};
      var regionCount = 0;
      var cityCount = 0;

      for (final region in geo.regions) {
        final regionRef = db.collection('cities').doc(region.id);
        regionRefs[region.id] = regionRef;
        await writer.set(
          regionRef,
          createCitiesRecordData(
            naim: region.name,
            dolh: countryRef,
            acctev: true,
          ),
        );
        regionCount++;

        for (final city in region.cities) {
          final cityRef = db.collection('villages').doc(city.id);
          cityRefs[city.id] = cityRef;
          await writer.set(
            cityRef,
            createVillagesRecordData(
              naim: city.name,
              cities: regionRef,
              dolh: countryRef,
              acctev: true,
            ),
          );
          cityCount++;
        }
      }

      for (final type in _vehicleTypes) {
        await writer.set(
          db.collection('type_car').doc(type.$1),
          {
            'naim': type.$2,
            'sr': type.$3,
            'acctev': true,
          },
        );
      }

      for (final cat in _categories) {
        await writer.set(
          db.collection('Classification').doc(cat.$1),
          {
            'naim': cat.$2,
            'acctev': true,
          },
        );
      }

      final mkanRefs = <String, DocumentReference>{};
      var landmarkCount = 0;

      for (final lm in AdminProductionSeedCatalog.landmarks) {
        final regionRef = regionRefs[lm.regionId];
        final cityRef = cityRefs[lm.cityId];
        if (regionRef == null || cityRef == null) continue;

        final ref = db.collection('mkan').doc(lm.id);
        mkanRefs[lm.id] = ref;

        final addedAt = now.subtract(Duration(days: lm.daysAgo));

        await writer.set(
          ref,
          {
            ...createMkanRecordData(
              naim: lm.name,
              osf: lm.description,
              img1: lm.img1,
              img2: lm.img2 ?? '',
              img3: lm.img3 ?? '',
              sr: lm.sortOrder,
              ismsgd: lm.isMosque,
              isfood: lm.isFood,
              ishmam: lm.isRestroom,
              acctev: true,
              idCit: regionRef,
              idVill: cityRef,
              revDolh: countryRef,
              location: LatLng(lm.lat, lm.lng),
              address: lm.address,
              mdh: lm.phone,
              asAds: true,
              ismzod: true,
              isShrek: lm.isPartner,
              tsnef: lm.category,
              rate: lm.rate,
              addSaat: 2,
            ),
            'dataAdd': Timestamp.fromDate(addedAt),
            if (lm.isPartner) 'EmailUser': 'partner.${lm.id}@arawatan.sa',
          },
        );
        landmarkCount++;
      }

      var orderCount = 0;
      final landmarkList = AdminProductionSeedCatalog.landmarks;
      final rng = landmarkList.length;

      for (var monthOffset = 11; monthOffset >= 0; monthOffset--) {
        for (var i = 0; i < 8; i++) {
          final lm = landmarkList[(monthOffset * 3 + i) % rng];
          final mkanRef = mkanRefs[lm.id];
          if (mkanRef == null) continue;

          final orderDate = now.subtract(
            Duration(days: monthOffset * 28 + i * 4 + 3),
          );

          final total = 450.0 + (monthOffset * 37) + (i * 125);
          final isPaid = (monthOffset + i) % 4 != 0;
          final isCanceled = !isPaid && i == 4;
          final status = isCanceled
              ? Halh.Canceled
              : isPaid
                  ? Halh.Paid
                  : Halh.Pending;
          final halhText = isCanceled
              ? 'canceled'
              : isPaid
                  ? 'paid'
                  : 'pending';

          final orderId =
              'order_${orderDate.year}${orderDate.month.toString().padLeft(2, '0')}_${(monthOffset * 5 + i + 1).toString().padLeft(3, '0')}';

          final customer = AdminProductionSeedCatalog
              .customerNames[(monthOffset + i) % AdminProductionSeedCatalog.customerNames.length];

          await writer.set(
            db.collection('order').doc(orderId),
            {
              ...createOrderRecordData(
                total: total,
                totalApp: (total * 0.12).round(),
                totalVat: (total * 0.15).round(),
                allnow: !isCanceled && !isPaid,
                revDolh: countryRef,
                dataOrder: orderDate,
                iDorder: 'ARW-${orderDate.year}${orderDate.month.toString().padLeft(2, '0')}-${(monthOffset * 5 + i + 1).toString().padLeft(4, '0')}',
                naimUserText: customer,
                halhOrder: status,
                halh: halhText,
                cartext: lm.name,
                partnerMkans: lm.isPartner ? [mkanRef] : null,
              ),
              'listAmakn': [
                AmaknCostmStruct(
                  naim: lm.name,
                  mkanRev: [mkanRef],
                  sr: total,
                ).toMap(),
              ],
            },
          );
          orderCount++;
        }
      }

      var ticketCount = 0;
      final ticketSubjects = [
        'استفسار عن حجز معلم',
        'تأخر وصول المندوب',
        'طلب تعديل موعد',
        'مشكلة في الدفع',
        'اقتراح إضافة معلم',
      ];

      for (var t = 0; t < ticketSubjects.length; t++) {
        await writer.set(
          db.collection('support').doc('support_${t + 1}'),
          createSupportRecordData(
            id: t + 1,
            naim: ticketSubjects[t],
            osf:
                'تذكرة دعم رقم ${t + 1} — تم فتحها ضمن بيانات النظام التشغيلية.',
            revDolh: countryRef,
            data: now.subtract(Duration(days: 30 * (t + 1))),
            halh: t % 2 == 0 ? HalhSupport.Open : HalhSupport.Closed,
          ),
        );
        ticketCount++;
      }

      await writer.flush();
      AdminLandmarkCountCache.invalidate();

      return ProductionSeedResult(
        landmarks: landmarkCount,
        orders: orderCount,
        regions: regionCount,
        cities: cityCount,
        supportTickets: ticketCount,
      );
    } catch (e) {
      return ProductionSeedResult(
        landmarks: 0,
        orders: 0,
        regions: 0,
        cities: 0,
        supportTickets: 0,
        error: e.toString(),
      );
    }
  }
}

class _SeedBatchWriter {
  static const _maxOps = 450;

  _SeedBatchWriter(this._db);

  final FirebaseFirestore _db;
  late WriteBatch _batch = _db.batch();
  var _ops = 0;

  Future<void> set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    _batch.set(ref, data, SetOptions(merge: true));
    _ops++;
    if (_ops >= _maxOps) {
      await _commitCurrent();
    }
  }

  Future<void> flush() async {
    if (_ops > 0) {
      await _commitCurrent();
    }
  }

  Future<void> _commitCurrent() async {
    final batch = _batch;
    _batch = _db.batch();
    _ops = 0;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await batch.commit();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return;
      } on FirebaseException catch (e) {
        final retryable = e.code == 'resource-exhausted' ||
            e.code == 'unavailable' ||
            e.code == 'deadline-exceeded';
        if (retryable && attempt < 5) {
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
  }
}
