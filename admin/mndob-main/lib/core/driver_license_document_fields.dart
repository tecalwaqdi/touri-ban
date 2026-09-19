/// Canonical driver-license V2 slots used by Driver App + Admin.
///
/// New registration requires both front and back uploads.
/// Legacy single-slot `doc_driver_license` is still read for prefill/compat.
abstract final class DriverLicenseDocumentFields {
  DriverLicenseDocumentFields._();

  static const legacy = 'doc_driver_license';
  static const front = 'doc_driver_license_front';
  static const back = 'doc_driver_license_back';

  static const frontTitleKey = 'Driver license (front)';
  static const backTitleKey = 'Driver license (back)';
}
