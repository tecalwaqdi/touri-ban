import 'package:cloud_firestore/cloud_firestore.dart';

/// Server-defined wallet top-up package (amounts are never trusted from UI).
class TouryWalletTopUpPackage {
  const TouryWalletTopUpPackage({
    required this.packageId,
    required this.amountMinor,
    required this.currency,
    required this.enabled,
    this.countryCode,
    this.sortOrder = 0,
  });

  final String packageId;
  final int amountMinor;
  final String currency;
  final bool enabled;
  final String? countryCode;
  final int sortOrder;

  double get amountMajor => amountMinor / 100.0;

  static TouryWalletTopUpPackage? tryParse(Map<String, dynamic> raw) {
    final packageId = (raw['packageId'] ?? '').toString().trim();
    final currency = (raw['currency'] ?? '').toString().trim().toUpperCase();
    final amountRaw = raw['amountMinor'];
    final amountMinor = amountRaw is int
        ? amountRaw
        : int.tryParse('$amountRaw');
    if (packageId.isEmpty || amountMinor == null || amountMinor <= 0) {
      return null;
    }
    if (currency.isEmpty) return null;
    return TouryWalletTopUpPackage(
      packageId: packageId,
      amountMinor: amountMinor,
      currency: currency,
      enabled: raw['enabled'] == true,
      countryCode: (raw['countryCode'] ?? '').toString().trim().isEmpty
          ? null
          : (raw['countryCode'] ?? '').toString().trim().toUpperCase(),
      sortOrder: int.tryParse('${raw['sortOrder'] ?? 0}') ?? 0,
    );
  }
}

/// Loads `settings/wallet_topup_packages` — enabled packages only.
Future<List<TouryWalletTopUpPackage>> touryLoadWalletTopUpPackages({
  String? countryCode,
}) async {
  final snap = await FirebaseFirestore.instance
      .doc('settings/wallet_topup_packages')
      .get();
  if (!snap.exists) return const [];
  final data = snap.data() ?? {};
  final rawPackages = data['packages'];
  if (rawPackages is! List) return const [];

  final requestedCountry = (countryCode ?? '').trim().toUpperCase();
  final packages = <TouryWalletTopUpPackage>[];
  for (final entry in rawPackages) {
    if (entry is! Map) continue;
    final parsed = TouryWalletTopUpPackage.tryParse(
      Map<String, dynamic>.from(entry),
    );
    if (parsed == null || !parsed.enabled) continue;
    if (requestedCountry.isNotEmpty &&
        (parsed.countryCode ?? '').isNotEmpty &&
        parsed.countryCode != requestedCountry) {
      continue;
    }
    packages.add(parsed);
  }
  packages.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return packages;
}
