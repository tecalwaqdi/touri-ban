
import '/backend/backend.dart';

/// Resolves and writes country (`Rev_dolh`) on user/support documents.
class AdminCountrySync {
  AdminCountrySync._();

  static Future<DocumentReference?> countryFromVillage(
    DocumentReference? villageRef,
  ) async {
    if (villageRef == null) return null;
    try {
      final village = await VillagesRecord.getDocumentOnce(villageRef);
      return village.dolh;
    } catch (_) {
      return null;
    }
  }

  static Future<DocumentReference?> countryFromRegion(
    DocumentReference? regionRef,
  ) async {
    if (regionRef == null) return null;
    try {
      final region = await CitiesRecord.getDocumentOnce(regionRef);
      return region.dolh;
    } catch (_) {
      return null;
    }
  }

  static Future<DocumentReference?> countryFromUser(
    DocumentReference? userRef,
  ) async {
    if (userRef == null) return null;
    try {
      final user = await UserRecord.getDocumentOnce(userRef);
      if (user.hasRevDolh()) return user.revDolh;
      if (user.ismndob && user.hasMndobVill()) {
        return countryFromVillage(user.mndobVill);
      }
    } catch (_) {}
    return null;
  }
}
