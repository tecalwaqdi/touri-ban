import '/app_state.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// حقول Firestore الإضافية لربط الطلب بالدولة (للوحة الإدارة).
Map<String, dynamic> touryOrderCountryExtras() {
  final dolh = FFAppState().dolh;
  if (dolh == null) return {};
  return mapToFirestore({'Rev_dolh': dolh});
}
