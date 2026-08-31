import '/backend/admin_resource_guard.dart';
import '/backend/backend.dart';
import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/components/admin_edit_shell.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'driver_profile_body.dart';
import 'driver_profile_model.dart';
export 'driver_profile_model.dart';

class DriverProfileWidget extends StatefulWidget {
  const DriverProfileWidget({
    super.key,
    required this.iduser,
  });

  final DocumentReference? iduser;

  static String routeName = 'DriverProfile';
  static String routePath = '/driverProfile';

  @override
  State<DriverProfileWidget> createState() => _DriverProfileWidgetState();
}

class _DriverProfileWidgetState extends State<DriverProfileWidget> {
  late DriverProfileModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverProfileModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iduser == null) {
      return AdminMissingDocumentScaffold(
        title: uiTr(context, 'ملف المندوب'),
        message: uiTr(context, 'تعذر تحميل بيانات المندوب'),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(widget.iduser!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AdminDriverModuleScaffold(
            title: uiTr(context, 'ملف المندوب'),
            isLoading: true,
            body: const SizedBox.shrink(),
          );
        }

        final user = snapshot.data!;

        return FutureBuilder<bool>(
          future: AdminResourceGuard.canEditDriver(user),
          builder: (context, accessSnap) {
            if (!accessSnap.hasData) {
              return AdminDriverModuleScaffold(
                title: uiTr(context, 'ملف المندوب'),
                isLoading: true,
                body: const SizedBox.shrink(),
              );
            }
            if (accessSnap.data != true) {
              return AdminDriverModuleScaffold(
                title: uiTr(context, 'ملف المندوب'),
                body: Center(
                  child: Text(
                    uiTr(context, 'لا تملك صلاحية عرض ملف هذا السائق'),
                  ),
                ),
              );
            }

            final row = AdminDriverRow.fromUser(user);
            return AdminDriverModuleScaffold(
              title: uiTr(context, 'ملف المندوب'),
              subtitle: row.displayName,
              body: DriverProfileBody(
                user: user,
                userRef: widget.iduser!,
              ),
            );
          },
        );
      },
    );
  }
}
