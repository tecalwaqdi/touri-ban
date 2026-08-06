/// Firestore tour-guide fields on `user/{uid}` (matches Admi / mndob-main).
abstract final class TourGuideStatus {
  TourGuideStatus._();

  static const none = 'none';
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static const fieldIsTourGuide = 'is_tour_guide';
  static const fieldStatus = 'tour_guide_status';
  static const fieldPermitUrl = 'tour_guide_permit_url';

  static bool isApproved(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data[fieldIsTourGuide] == true &&
        (data[fieldStatus] as String?) == approved;
  }
}
