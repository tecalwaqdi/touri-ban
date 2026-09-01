import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';

/// One financial period bucket from [getDriverFinancialSummaryV2].
class DriverFinancePeriodSummary {
  const DriverFinancePeriodSummary({
    this.completedTrips = 0,
    this.gross = 0,
    this.platformFee = 0,
    this.vat = 0,
    this.driverNet = 0,
    this.companyDue = 0,
    this.cashTrips = 0,
    this.onlineTrips = 0,
    this.derivedDriverNetCount = 0,
    this.excludedIncompleteCount = 0,
  });

  final int completedTrips;
  final double gross;
  final double platformFee;
  final double vat;
  final double driverNet;
  final double companyDue;
  final int cashTrips;
  final int onlineTrips;
  final int derivedDriverNetCount;
  final int excludedIncompleteCount;

  static DriverFinancePeriodSummary fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const DriverFinancePeriodSummary();
    double n(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    return DriverFinancePeriodSummary(
      completedTrips: (raw['completedTrips'] as num?)?.round() ?? 0,
      gross: n(raw['gross']),
      platformFee: n(raw['platformFee']),
      vat: n(raw['vat']),
      driverNet: n(raw['driverNet']),
      companyDue: n(raw['companyDue']),
      cashTrips: (raw['cashTrips'] as num?)?.round() ?? 0,
      onlineTrips: (raw['onlineTrips'] as num?)?.round() ?? 0,
      derivedDriverNetCount:
          (raw['derivedDriverNetCount'] as num?)?.round() ?? 0,
      excludedIncompleteCount:
          (raw['excludedIncompleteCount'] as num?)?.round() ?? 0,
    );
  }

  String get driverNetLabel => _money(driverNet);
  String get companyDueLabel => _money(companyDue);

  static String _money(double v) => v.toStringAsFixed(2);
}

class DriverFinanceSettlementsSummary {
  const DriverFinanceSettlementsSummary({
    this.paid = 0,
    this.pending = 0,
    this.outstanding = 0,
  });

  final double paid;
  final double pending;
  final double outstanding;

  static DriverFinanceSettlementsSummary fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const DriverFinanceSettlementsSummary();
    double n(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    return DriverFinanceSettlementsSummary(
      paid: n(raw['paid']),
      pending: n(raw['pending']),
      outstanding: n(raw['outstanding']),
    );
  }
}

/// Server-authoritative driver finance snapshot (read-only).
class DriverFinancialSummary {
  const DriverFinancialSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.lifetime,
    required this.settlements,
    this.currency = 'SAR',
    this.timezone = 'Asia/Riyadh',
    this.anomalies = const [],
  });

  final DriverFinancePeriodSummary today;
  final DriverFinancePeriodSummary week;
  final DriverFinancePeriodSummary month;
  final DriverFinancePeriodSummary lifetime;
  final DriverFinanceSettlementsSummary settlements;
  final String currency;
  final String timezone;
  final List<Map<String, dynamic>> anomalies;

  static DriverFinancialSummary fromResponse(Map<String, dynamic> raw) {
    return DriverFinancialSummary(
      today: DriverFinancePeriodSummary.fromMap(
        Map<String, dynamic>.from(raw['today'] as Map? ?? {}),
      ),
      week: DriverFinancePeriodSummary.fromMap(
        Map<String, dynamic>.from(raw['week'] as Map? ?? {}),
      ),
      month: DriverFinancePeriodSummary.fromMap(
        Map<String, dynamic>.from(raw['month'] as Map? ?? {}),
      ),
      lifetime: DriverFinancePeriodSummary.fromMap(
        Map<String, dynamic>.from(raw['lifetime'] as Map? ?? {}),
      ),
      settlements: DriverFinanceSettlementsSummary.fromMap(
        Map<String, dynamic>.from(raw['settlements'] as Map? ?? {}),
      ),
      currency: (raw['currency'] ?? 'SAR').toString(),
      timezone: (raw['timezone'] ?? 'Asia/Riyadh').toString(),
      anomalies: (raw['anomalies'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

class DriverFinancialSummaryResult {
  const DriverFinancialSummaryResult({
    required this.ok,
    this.summary,
    this.error,
  });

  final bool ok;
  final DriverFinancialSummary? summary;
  final String? error;

  factory DriverFinancialSummaryResult.failure([String? error]) =>
      DriverFinancialSummaryResult(ok: false, error: error ?? 'unavailable');
}

/// Loads canonical driver finance from Cloud Function V2.
abstract final class DriverFinancialSummaryService {
  DriverFinancialSummaryService._();

  static DriverFinancialSummary? _cache;
  static DateTime? _cacheAt;
  static const _cacheTtl = Duration(seconds: 45);

  static Future<DriverFinancialSummaryResult> load({
    String? driverId,
    String currency = 'SAR',
    bool forceRefresh = false,
  }) async {
    final uid = (driverId ?? currentUserUid).trim();
    if (uid.isEmpty) {
      return DriverFinancialSummaryResult.failure('not_signed_in');
    }

    if (!forceRefresh &&
        _cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      return DriverFinancialSummaryResult(ok: true, summary: _cache);
    }

    final raw = await makeCloudCall(
      'getDriverFinancialSummaryV2',
      {
        'driverId': uid,
        'currency': currency,
      },
      timeout: const Duration(seconds: 25),
    );

    if (raw['ok'] != true) {
      final err = (raw['error'] ?? raw['errorCode'] ?? 'summary_failed')
          .toString();
      if (_cache != null) {
        return DriverFinancialSummaryResult(ok: true, summary: _cache);
      }
      return DriverFinancialSummaryResult.failure(err);
    }

    final summary = DriverFinancialSummary.fromResponse(raw);
    _cache = summary;
    _cacheAt = DateTime.now();
    return DriverFinancialSummaryResult(ok: true, summary: summary);
  }

  static void invalidateCache() {
    _cache = null;
    _cacheAt = null;
  }
}
