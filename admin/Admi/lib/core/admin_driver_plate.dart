/// Plate normalize for Admin edit writes — mirrors Driver App contract.
abstract final class AdminDriverPlate {
  AdminDriverPlate._();

  static String normalize(String? raw) {
    return (raw ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('-', '')
        .toUpperCase();
  }

  static String display(String? raw) =>
      (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
}
