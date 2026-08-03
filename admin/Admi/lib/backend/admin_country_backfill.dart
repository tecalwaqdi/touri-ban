
import '/backend/admin_country_sync.dart';
import '/backend/admin_landmark_country_backfill.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// One-time / maintenance backfill for `Rev_dolh` on legacy documents.
class AdminCountryBackfill {
  AdminCountryBackfill._();

  static Future<AdminCountryBackfillResult> run() async {
    var reps = 0;
    var support = 0;
    var appUsers = 0;
    var landmarks = 0;
    var agents = 0;

    try {
      reps = await _backfillRepresentatives();
      appUsers = await _backfillAppUsersFromOrders();
      support = await _backfillSupportTickets();

      final saudi = await AdminSaudiCountry.resolveRef();
      if (saudi != null) {
        final landmarkResult =
            await AdminLandmarkCountryBackfill.run(countryRef: saudi);
        landmarks = landmarkResult.landmarks;
        agents = landmarkResult.agents;
      }

      return AdminCountryBackfillResult(
        success: true,
        representatives: reps,
        appUsers: appUsers,
        supportTickets: support,
        landmarks: landmarks,
        agents: agents,
      );
    } catch (e) {
      return AdminCountryBackfillResult(
        success: false,
        error: e.toString(),
        representatives: reps,
        appUsers: appUsers,
        supportTickets: support,
      );
    }
  }

  static Future<int> _backfillRepresentatives() async {
    var updated = 0;
    DocumentSnapshot? last;

    while (true) {
      final batch = await queryUserRecordOnce(
        queryBuilder: (q) {
          var query = q.where('ismndob', isEqualTo: true);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: 200,
      );
      if (batch.isEmpty) break;

      for (final user in batch) {
        if (user.hasRevDolh() || !user.hasMndobVill()) continue;
        final country = await AdminCountrySync.countryFromVillage(user.mndobVill);
        if (country == null) continue;
        await user.reference.update({'Rev_dolh': country});
        updated++;
      }

      last = await batch.last.reference.get();
      if (batch.length < 200) break;
    }

    return updated;
  }

  static Future<int> _backfillAppUsersFromOrders() async {
    final countryByUser = <String, DocumentReference>{};
    DocumentSnapshot? last;

    while (true) {
      final orders = await queryOrderRecordOnce(
        queryBuilder: (q) {
          var query = q.orderBy('data_order', descending: true);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: 300,
      );
      if (orders.isEmpty) break;

      for (final order in orders) {
        if (!order.hasUser() || !order.hasRevDolh()) continue;
        final path = order.user!.path;
        countryByUser.putIfAbsent(path, () => order.revDolh!);
      }

      last = await orders.last.reference.get();
      if (orders.length < 300) break;
    }

    var updated = 0;
    for (final entry in countryByUser.entries) {
      final ref = FirebaseFirestore.instance.doc(entry.key);
      final snap = await ref.get();
      if (!snap.exists) continue;
      final user = UserRecord.fromSnapshot(snap);
      if (user.isagent || user.ismndob || user.hasRevDolh()) continue;
      await ref.update({'Rev_dolh': entry.value});
      updated++;
    }

    return updated;
  }

  static Future<int> _backfillSupportTickets() async {
    var updated = 0;
    DocumentSnapshot? last;

    while (true) {
      final tickets = await querySupportRecordOnce(
        queryBuilder: (q) {
          var query = q.orderBy('data', descending: true);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: 200,
      );
      if (tickets.isEmpty) break;

      for (final ticket in tickets) {
        if (ticket.hasRevDolh()) continue;
        final country = await AdminCountrySync.countryFromUser(ticket.refUser);
        if (country == null) continue;
        await ticket.reference.update({'Rev_dolh': country});
        updated++;
      }

      last = await tickets.last.reference.get();
      if (tickets.length < 200) break;
    }

    return updated;
  }
}

class AdminCountryBackfillResult {
  const AdminCountryBackfillResult({
    required this.success,
    this.error,
    this.representatives = 0,
    this.appUsers = 0,
    this.supportTickets = 0,
    this.landmarks = 0,
    this.agents = 0,
  });

  final bool success;
  final String? error;
  final int representatives;
  final int appUsers;
  final int supportTickets;
  final int landmarks;
  final int agents;
}
