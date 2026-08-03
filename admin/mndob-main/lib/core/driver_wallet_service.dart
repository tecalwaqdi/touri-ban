import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/transaction_record.dart';
import '/backend/schema/wallet_record.dart';
import '/core/driver_country_service.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/toury_country_registry.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Wallet + ledger — read Backend truth; never invent balance in Flutter.
abstract final class DriverWalletService {
  DriverWalletService._();

  static String currencyCode() {
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencyForIso(iso);
  }

  static bool currenciesCompatible(String? a, String? b) {
    final x = (a ?? '').trim().toUpperCase();
    final y = (b ?? '').trim().toUpperCase();
    if (x.isEmpty || y.isEmpty) return true;
    return x == y;
  }

  static Future<WalletRecord> getOrCreateWallet() async {
    final userRef = currentUserReference;
    if (userRef == null) {
      throw StateError('Driver not signed in');
    }

    final existing = await WalletRecord.collection
        .where('userRef', isEqualTo: userRef)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return WalletRecord.fromSnapshot(existing.docs.first);
    }

    final ref = WalletRecord.collection.doc();
    final data = createWalletRecordData(
      userRef: userRef,
      currentBalance: 0,
      lastUpdated: getCurrentTimestamp,
      currency: currencyCode(),
      isActive: true,
    );
    await ref.set(data);
    return WalletRecord.getDocumentOnce(ref);
  }

  static Stream<WalletRecord?> walletStream() {
    final userRef = currentUserReference;
    if (userRef == null) {
      return Stream<WalletRecord?>.value(null);
    }
    return WalletRecord.collection
        .where('userRef', isEqualTo: userRef)
        .limit(1)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) {
        return await getOrCreateWallet();
      }
      return WalletRecord.fromSnapshot(snap.docs.first);
    });
  }

  static Stream<List<TransactionRecord>> transactionsStream({int limit = 30}) {
    final userRef = currentUserReference;
    if (userRef == null) {
      return Stream<List<TransactionRecord>>.value(const []);
    }
    return TransactionRecord.collection
        .where('userRef', isEqualTo: userRef)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(TransactionRecord.fromSnapshot).toList());
  }

  /// Paginated ledger page (Backend query). Does not invent entries.
  static Future<DriverWalletLedgerPage> loadLedgerPage({
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) {
      return const DriverWalletLedgerPage(items: [], hasMore: false);
    }
    var q = TransactionRecord.collection
        .where('userRef', isEqualTo: userRef)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final items = snap.docs.map(TransactionRecord.fromSnapshot).toList();
    return DriverWalletLedgerPage(
      items: items,
      hasMore: snap.docs.length >= limit,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }

  static Future<double> availableBalance() async {
    final wallet = await getOrCreateWallet();
    return wallet.currentBalance;
  }

  /// Rejects mixing trip currency with wallet currency when both known.
  static Future<bool> acceptsTripCurrency(String? tripCurrency) async {
    final wallet = await getOrCreateWallet();
    final wc = wallet.currency.trim().toUpperCase();
    final tc = (tripCurrency ?? '').trim().toUpperCase();
    if (!DriverPaymentStatusMapper.supportedCurrencies.contains(tc) &&
        tc.isNotEmpty) {
      return false;
    }
    return currenciesCompatible(wc, tc);
  }
}

class DriverWalletLedgerPage {
  const DriverWalletLedgerPage({
    required this.items,
    required this.hasMore,
    this.lastDoc,
  });

  final List<TransactionRecord> items;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
}
