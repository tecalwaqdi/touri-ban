/// Firestore tour-guide fields on `user/{uid}` (matches Admi / ara_oatan_app).
abstract final class TourGuideStatus {
  TourGuideStatus._();

  static const none = 'none';
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const suspended = 'suspended';

  static const fieldIsTourGuide = 'is_tour_guide';
  static const fieldStatus = 'tour_guide_status';
  static const fieldPermitUrl = 'tour_guide_permit_url';
  static const fieldReviewedAt = 'tour_guide_reviewed_at';
  static const fieldRejectionReason = 'tour_guide_rejection_reason';

  static bool isApproved(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data[fieldIsTourGuide] == true &&
        (data[fieldStatus] as String?) == approved;
  }

  static bool isPending(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data[fieldIsTourGuide] == true &&
        (data[fieldStatus] as String?) == pending;
  }

  static bool isSuspended(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data[fieldIsTourGuide] == true &&
        (data[fieldStatus] as String?) == suspended;
  }

  static bool isBookable(Map<String, dynamic>? data) {
    return isApproved(data);
  }
}
