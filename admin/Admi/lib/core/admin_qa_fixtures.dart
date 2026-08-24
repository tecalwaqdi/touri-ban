/// Compile-time gate for Admin visual-QA fixtures.
///
/// Enable only for local/QA builds:
/// `flutter build web --dart-define=ADMIN_QA_FIXTURES=true`
///
/// Default (production release): disabled.
abstract final class AdminQaFixtures {
  AdminQaFixtures._();

  static const bool enabled = bool.fromEnvironment(
    'ADMIN_QA_FIXTURES',
    defaultValue: false,
  );
}
