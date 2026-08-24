/// Result of a driver document upload — [storagePath] is the durable SoT.
class DriverDocumentUploadResult {
  const DriverDocumentUploadResult({
    required this.storagePath,
    this.previewUrl,
  });

  /// Firebase Storage object path, e.g. `users/{uid}/uploads/...`
  final String storagePath;

  /// Ephemeral URL for in-session UI preview only — not written to Firestore.
  final String? previewUrl;
}
