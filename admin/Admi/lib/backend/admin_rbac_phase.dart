/// RBAC resolution phase for Admin panel access.
///
/// [bootstrap] — profile may temporarily inform access while claims sync runs.
/// [authoritative] — Firebase Auth custom claims are the sole access source.
enum AdminRbacPhase {
  loading,
  bootstrap,
  authoritative,
}
