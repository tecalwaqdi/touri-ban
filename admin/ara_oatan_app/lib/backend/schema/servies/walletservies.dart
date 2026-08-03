import 'package:ara_oatan_app/backend/schema/transactionrecord.dart';
import 'package:ara_oatan_app/backend/schema/walletrecord.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
class WalletService {
  static Future<WalletRecord> getOrCreateWallet(String userId) async {
    final userRef = UserRecord.collection.doc(userId);
    
    // Check if wallet exists
    final walletQuery = await FirebaseFirestore.instance
        .collection('wallets')
        .where('userRef', isEqualTo: userRef)
        .limit(1)
        .get();
    
    if (walletQuery.docs.isNotEmpty) {
      return WalletRecord.fromSnapshot(walletQuery.docs.first);
    } else {
      // Create new wallet
      final newWalletRef = FirebaseFirestore.instance.collection('wallets').doc();
      final walletData = createWalletRecordData(
        userRef: userRef,
        currentBalance: 0.0,
        lastUpdated: DateTime.now(),
        currency: 'SAR',
        isActive: true,
      );
      
      await newWalletRef.set(walletData);
      return WalletRecord.getDocumentOnce(newWalletRef);
    }
  }

  static Stream<WalletRecord> getWalletStream(String userId) {
    final userRef = UserRecord.collection.doc(userId);
    
    return FirebaseFirestore.instance
        .collection('wallets')
        .where('userRef', isEqualTo: userRef)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            // Create wallet if it doesn't exist
            return await getOrCreateWallet(userId);
          }
          return WalletRecord.fromSnapshot(snapshot.docs.first);
        });
  }

  static Future<void> addMoney({
    required String userId,
    required double amount,
    required String paymentMethodId,
    required String description,
    String? gatewayPaymentId,
  }) async {
    if (gatewayPaymentId != null && gatewayPaymentId.isNotEmpty) {
      final existing = await FirebaseFirestore.instance
          .collection('transactions')
          .where('referenceId', isEqualTo: gatewayPaymentId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return;
      }
    }

    final wallet = await getOrCreateWallet(userId);
    final paymentMethodRef = FirebaseFirestore.instance
        .collection('PaymentMethods')
        .doc(paymentMethodId);
    
    // Start a batch write for atomic operations
    final batch = FirebaseFirestore.instance.batch();
    
    // Update wallet balance
    final updatedBalance = wallet.currentBalance + amount;
    final walletUpdate = {
      'currentBalance': updatedBalance,
      'lastUpdated': DateTime.now(),
    };
    batch.update(wallet.reference, walletUpdate);
    
    // Create transaction record
    final transactionRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc();
    final transactionData = createTransactionRecordData(
      userRef: UserRecord.collection.doc(userId),
      walletRef: wallet.reference,
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: 'credit',
      description: description,
      paymentMethodRef: paymentMethodRef,
      status: 'completed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      referenceId: gatewayPaymentId,
      notes: gatewayPaymentId != null ? 'ngenius' : null,
    );
    batch.set(transactionRef, transactionData);
    
    await batch.commit();
  }

  static Future<void> withdrawMoney({
    required String userId,
    required double amount,
    required String paymentMethodId,
    required String description,
    String? gatewayPaymentId,
  }) async {
    if (amount <= 0) {
      throw Exception('Invalid amount');
    }

    final wallet = await getOrCreateWallet(userId);
    if (wallet.currentBalance < amount) {
      throw Exception('Insufficient balance');
    }

    final paymentMethodRef = FirebaseFirestore.instance
        .collection('PaymentMethods')
        .doc(paymentMethodId);

    final batch = FirebaseFirestore.instance.batch();
    final updatedBalance = wallet.currentBalance - amount;
    batch.update(wallet.reference, {
      'currentBalance': updatedBalance,
      'lastUpdated': DateTime.now(),
    });

    final transactionRef =
        FirebaseFirestore.instance.collection('transactions').doc();
    batch.set(
      transactionRef,
      createTransactionRecordData(
        userRef: UserRecord.collection.doc(userId),
        walletRef: wallet.reference,
        transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'debit',
        description: description,
        paymentMethodRef: paymentMethodRef,
        status: 'completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        referenceId: gatewayPaymentId,
        notes: gatewayPaymentId != null ? 'ngenius_refund' : null,
      ),
    );

    await batch.commit();
  }

  /// يبحث عن إيداع إلكتروني سابق بنفس البطاقة يكفي لمبلغ السحب.
  static Future<String?> findGatewayDepositPaymentId({
    required String userId,
    required String paymentMethodId,
    required double minAmount,
  }) async {
    final userRef = UserRecord.collection.doc(userId);
    final paymentMethodRef =
        FirebaseFirestore.instance.collection('PaymentMethods').doc(
              paymentMethodId,
            );

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userRef', isEqualTo: userRef)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    for (final doc in snapshot.docs) {
      final tx = TransactionRecord.fromSnapshot(doc);
      if (tx.type != 'credit') {
        continue;
      }
      if (tx.paymentMethodRef?.path != paymentMethodRef.path) {
        continue;
      }
      final refId = tx.referenceId.trim();
      if (refId.isEmpty || tx.amount < minAmount) {
        continue;
      }
      final debited = await FirebaseFirestore.instance
          .collection('transactions')
          .where('referenceId', isEqualTo: refId)
          .where('type', isEqualTo: 'debit')
          .limit(1)
          .get();
      if (debited.docs.isEmpty) {
        return refId;
      }
    }
    return null;
  }

  static Future<void> makePayment({
    required String userId,
    required double amount,
    required String description,
    String? paymentMethodId,
    String? referenceId,
  }) async {
    final wallet = await getOrCreateWallet(userId);
    
    if (wallet.currentBalance < amount) {
      throw Exception('Insufficient balance');
    }
    
    final batch = FirebaseFirestore.instance.batch();
    
    // Update wallet balance
    final updatedBalance = wallet.currentBalance - amount;
    final walletUpdate = {
      'currentBalance': updatedBalance,
      'lastUpdated': DateTime.now(),
    };
    batch.update(wallet.reference, walletUpdate);
    
    // Create transaction record
    final transactionRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc();
    DocumentReference? paymentMethodRef;
    
    if (paymentMethodId != null) {
      paymentMethodRef = FirebaseFirestore.instance
          .collection('PaymentMethods')
          .doc(paymentMethodId);
    }
    
    final transactionData = createTransactionRecordData(
      userRef: UserRecord.collection.doc(userId),
      walletRef: wallet.reference,
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: 'debit',
      description: description,
      paymentMethodRef: paymentMethodRef,
      status: 'completed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      referenceId: referenceId,
    );
    batch.set(transactionRef, transactionData);
    
    await batch.commit();
  }

  static Future<List<TransactionRecord>> getTransactions({
    required String userId,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userRef = UserRecord.collection.doc(userId);
    
    var query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userRef', isEqualTo: userRef)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionRecord.fromSnapshot(doc))
        .toList();
  }

  // Helper method to get current balance
  static Future<double> getCurrentBalance(String userId) async {
    final wallet = await getOrCreateWallet(userId);
    return wallet.currentBalance;
  }

  // Method to get transaction summary
  static Future<Map<String, dynamic>> getTransactionSummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    double totalCredits = 0;
    double totalDebits = 0;
    
    for (final transaction in transactions) {
      if (transaction.type == 'credit') {
        totalCredits += transaction.amount;
      } else if (transaction.type == 'debit') {
        totalDebits += transaction.amount;
      }
    }
    
    return {
      'totalTransactions': transactions.length,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'netChange': totalCredits - totalDebits,
    };
  }
}