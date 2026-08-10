import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/transaction_record.dart';
import '/backend/schema/wallet_record.dart';
import '/core/driver_country_service.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_trip_constants.dart';
import '/core/toury_country_registry.dart';

/// Wallet + ledger — read Backend truth; never invent or write balance in Flutter.
abstract final class DriverWalletService {
  DriverWalletService._();

  static const double minCashEligibility = DriverWalletRules.minCashWalletBalance;

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

  /// Read-only. Never creates wallets from the client (rules forbid it).
  static Future<WalletRecord?> loadWallet() async {
    final userRef = currentUserReference;
    if (userRef == null) return null;

    final existing = await WalletRecord.collection
        .where('userRef', isEqualTo: userRef)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) return null;
    return WalletRecord.fromSnapshot(existing.docs.first);
  }

  @Deprecated('Use loadWallet — client must not create wallets')
  static Future<WalletRecord> getOrCreateWallet() async {
    final wallet = await loadWallet();
    if (wallet != null) return wallet;
    // Synthetic zero wallet for UI only — not persisted.
    throw StateError('WALLET_MISSING');
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
        .map((snap) {
      if (snap.docs.isEmpty) return null;
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

  /// Missing wallet ⇒ 0 (not eligible for cash until server-side top-up).
  static Future<double> availableBalance() async {
    try {
      final wallet = await loadWallet();
      return wallet?.currentBalance ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  static Future<bool> meetsCashEligibility() async {
    final balance = await availableBalance();
    return balance >= minCashEligibility;
  }

  static Future<bool> acceptsTripCurrency(String? tripCurrency) async {
    final wallet = await loadWallet();
    final wc = (wallet?.currency ?? '').trim().toUpperCase();
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
