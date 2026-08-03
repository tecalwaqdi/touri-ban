import 'package:firebase_auth/firebase_auth.dart';

import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Result of seeding demo panel users.
class DemoSeedResult {
  const DemoSeedResult({
    required this.created,
    required this.skipped,
    required this.accounts,
    this.error,
  });

  final int created;
  final int skipped;
  final List<DemoAccountInfo> accounts;
  final String? error;

  bool get success => error == null;
}

class DemoAccountInfo {
  const DemoAccountInfo({
    required this.roleLabel,
    required this.email,
    required this.password,
    required this.existed,
  });

  final String roleLabel;
  final String email;
  final String password;
  final bool existed;
}

/// Demo password shared by all seeded accounts.
const kDemoSeedPassword = 'Demo@2026';

class AdminDemoSeed {
  AdminDemoSeed._();

  static const _secondaryAppName = 'AdminDemoSeed';
  static const superEmail = _superEmail;
  static const demoPassword = kDemoSeedPassword;

  static const _superEmail = 'demo.super@arawatan.sa';
  static const _agentEmail = 'demo.agent@arawatan.sa';
  static const _partnerEmail = 'demo.partner@arawatan.sa';
  static const _transportEmail = 'demo.transport@arawatan.sa';

  static const _countryId = 'demo_saudi';
  static const _regionId = 'demo_region_riyadh';
  static const _villageId = 'demo_city_riyadh';
  static const _mkanId = 'demo_partner_mkan';
  static const _companyId = 'demo_transport_co';
  static const _orderId = 'demo_order_001';

  /// Seeds 4 demo users + geo/company/order data. Safe to run multiple times.
  static Future<DemoSeedResult> run() async {
    final accounts = <DemoAccountInfo>[];
    var created = 0;
    var skipped = 0;

    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);

    try {
      await auth.signOut();

      final now = getCurrentTimestamp;
      final countryRef = db.collection('countries').doc(_countryId);
      final regionRef = db.collection('cities').doc(_regionId);
      final villageRef = db.collection('villages').doc(_villageId);
      final mkanRef = db.collection('mkan').doc(_mkanId);
      final companyRef = db.collection('transport_company').doc(_companyId);
      final orderRef = db.collection('order').doc(_orderId);

      final superUid = await _ensureAuthUser(
        auth: auth,
        email: _superEmail,
        password: kDemoSeedPassword,
        existedCounter: (existed) {
          if (existed) {
            skipped++;
          } else {
            created++;
          }
        },
      );

      await db.collection('user').doc(superUid).set(
            createUserRecordData(
              email: _superEmail,
              displayName: 'سوبر أدمن تجريبي',
              phoneNumber: '+966500000001',
              uid: superUid,
              actevUser: true,
              createdTime: now,
              isAdmin: true,
              isAdminRule: AdminRoleService.ruleSuperAdmin,
            ),
            SetOptions(merge: true),
          );

      accounts.add(
        DemoAccountInfo(
          roleLabel: 'سوبر أدمن',
          email: _superEmail,
          password: kDemoSeedPassword,
          existed: false,
        ),
      );

      await auth.signInWithEmailAndPassword(
        email: _superEmail,
        password: kDemoSeedPassword,
      );

      await countryRef.set(
        createCountriesRecordData(
          naim: 'السعودية (تجريبي)',
          osf: 'دولة تجريبية لاختبار لوحة الإدارة',
          acctev: true,
          saudi: true,
          vatPercent: 15,
          appCommissionPercent: 12,
          numTrteb: 1,
        ),
        SetOptions(merge: true),
      );

      await regionRef.set(
        createCitiesRecordData(
          naim: 'منطقة الرياض (تجريبي)',
          dolh: countryRef,
          acctev: true,
        ),
        SetOptions(merge: true),
      );

      await villageRef.set(
        createVillagesRecordData(
          naim: 'الرياض (تجريبي)',
          cities: regionRef,
          dolh: countryRef,
          acctev: true,
        ),
        SetOptions(merge: true),
      );

      await mkanRef.set({
        ...createMkanRecordData(
          naim: 'منتجع الشريك التجريبي',
          osf: 'معلم شريك سياحي للاختبار — إقامة وفعاليات',
          img1:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
          acctev: true,
          isShrek: true,
          ismzod: true,
          asAds: true,
          tsnef: 'شريك سياحي',
          revDolh: countryRef,
          idCit: regionRef,
          idVill: villageRef,
          address: 'الرياض، المملكة العربية السعودية',
          mdh: '+966500000003',
          rate: 4.5,
          location: const LatLng(24.7136, 46.6753),
        ),
        'EmailUser': _partnerEmail,
        'dataAdd': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await companyRef.set(
        createTransportCompanyRecordData(
          naim: 'شركة النقل التجريبية',
          licenseNumber: 'DEMO-LIC-2026-001',
          revDolh: countryRef,
          dolhText: 'السعودية (تجريبي)',
          phone: '+966500000004',
          email: _transportEmail,
          actev: true,
          createdTime: now,
        ),
        SetOptions(merge: true),
      );

      await orderRef.set({
        ...createOrderRecordData(
          total: 1250,
          allnow: true,
          revDolh: countryRef,
          dataOrder: now,
          iDorder: 'DEMO-001',
          naimUserText: 'عميل تجريبي',
          halhOrder: Halh.Pending,
          halh: 'pending',
          partnerMkans: [mkanRef],
        ),
        'listAmakn': [
          AmaknCostmStruct(
            naim: 'منتجع الشريك التجريبي',
            mkanRev: [mkanRef],
          ).toMap(),
        ],
      }, SetOptions(merge: true));

      final agentEnd = DateTime.now().add(const Duration(days: 365));

      final otherUsers = <_DemoUserSpec>[
        _DemoUserSpec(
          roleLabel: 'وكيل دولة',
          email: _agentEmail,
          buildData: (uid) => createUserRecordData(
            email: _agentEmail,
            displayName: 'وكيل دولة تجريبي',
            phoneNumber: '+966500000002',
            uid: uid,
            actevUser: true,
            createdTime: now,
            isagent: true,
            isAdminRule: AdminRoleService.ruleCountryAgent,
            dolhAgent: 'السعودية (تجريبي)',
            revDlohAgent: countryRef,
            agentDateReg: now,
            agentDateEnd: agentEnd,
            agentTotal: 10,
            vatPercent: 15,
            appCommissionPercent: 12,
            bookingsAgent: 0,
          ),
        ),
        _DemoUserSpec(
          roleLabel: 'شريك',
          email: _partnerEmail,
          buildData: (uid) => createUserRecordData(
            email: _partnerEmail,
            displayName: 'شريك تجريبي',
            phoneNumber: '+966500000003',
            uid: uid,
            actevUser: true,
            createdTime: now,
            isPartner: true,
            partnerMkanRef: mkanRef,
            isAdminRule: AdminRoleService.rulePartner,
          ),
        ),
        _DemoUserSpec(
          roleLabel: 'مدير شركة نقل',
          email: _transportEmail,
          buildData: (uid) => createUserRecordData(
            email: _transportEmail,
            displayName: 'مدير شركة نقل تجريبي',
            phoneNumber: '+966500000004',
            uid: uid,
            actevUser: true,
            createdTime: now,
            isAdminRule: AdminRoleService.ruleTransportCompany,
            transportCompany: companyRef,
            transportCompanyText: 'شركة النقل التجريبية',
          ),
        ),
      ];

      DocumentReference? transportManagerRef;

      for (final spec in otherUsers) {
        await auth.signOut();
        final existedBefore = await _authUserExists(auth, spec.email);

        final uid = await _ensureAuthUser(
          auth: auth,
          email: spec.email,
          password: kDemoSeedPassword,
          existedCounter: (existed) {
            if (existed || existedBefore) {
              skipped++;
            } else {
              created++;
            }
          },
        );

        final userRef = db.collection('user').doc(uid);
        await userRef.set(spec.buildData(uid), SetOptions(merge: true));

        if (spec.email == _transportEmail) {
          transportManagerRef = userRef;
        }

        accounts.add(
          DemoAccountInfo(
            roleLabel: spec.roleLabel,
            email: spec.email,
            password: kDemoSeedPassword,
            existed: existedBefore,
          ),
        );

        await auth.signInWithEmailAndPassword(
          email: _superEmail,
          password: kDemoSeedPassword,
        );
      }

      if (transportManagerRef != null) {
        await companyRef.set(
          createTransportCompanyRecordData(ownerUser: transportManagerRef),
          SetOptions(merge: true),
        );
      }

      await auth.signOut();

      return DemoSeedResult(
        created: created,
        skipped: skipped,
        accounts: accounts,
      );
    } catch (e) {
      try {
        await auth.signOut();
      } catch (_) {}
      return DemoSeedResult(
        created: created,
        skipped: skipped,
        accounts: accounts,
        error: e.toString(),
      );
    }
  }

  static Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }
  }

  static Future<bool> _authUserExists(FirebaseAuth auth, String email) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: kDemoSeedPassword,
      );
      await auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return false;
      }
      if (e.code == 'wrong-password') {
        return true;
      }
      rethrow;
    }
  }

  static Future<String> _ensureAuthUser({
    required FirebaseAuth auth,
    required String email,
    required String password,
    required void Function(bool existed) existedCounter,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      existedCounter(false);
      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('تعذر إنشاء حساب $email');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        existedCounter(true);
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = credential.user?.uid;
        if (uid == null) {
          throw Exception(
            'الحساب $email موجود لكن كلمة المرور مختلفة — احذفه من Firebase Console',
          );
        }
        return uid;
      }
      rethrow;
    }
  }
}

class _DemoUserSpec {
  const _DemoUserSpec({
    required this.roleLabel,
    required this.email,
    required this.buildData,
  });

  final String roleLabel;
  final String email;
  final Map<String, dynamic> Function(String uid) buildData;
}
