import '/components/admin_edit_shell.dart';
import '/components/admin_status_badge.dart' show AdminStatusBadgeUnified;
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/core/admin_qa_fixtures.dart';
import '/core/driver_review_visual_fixture.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';

/// Read-only driver review surface for visual QA (no Firestore / no callables).
///
/// Only reachable when compiled with `--dart-define=ADMIN_QA_FIXTURES=true`.
class AdminDriverReviewFixtureWidget extends StatelessWidget {
  const AdminDriverReviewFixtureWidget({
    super.key,
    required this.reviewState,
  });

  final String reviewState;

  static String routeName = 'AdminDriverReviewFixture';
  static String routePath = '/driverReviewFixture';

  /// True when this build may show fixture content.
  static bool get isQaBuild => AdminQaFixtures.enabled;

  Map<String, dynamic> get _data {
    assert(AdminQaFixtures.enabled, 'Fixture data must not load in production');
    return DriverReviewVisualFixture.dataFor(reviewState);
  }

  AdminDriverReviewBucket get _bucket =>
      AdminDriverProfileView.reviewBucketFromRaw(
        _data['registration_status'] as String? ?? '',
      );

  bool get _activated => _data['actev_mndob'] == true;

  bool get _showReviewActions =>
      reviewState == 'pending_review' ||
      reviewState == 'pending' ||
      reviewState == 'needs_changes' ||
      reviewState == 'changes_requested';

  Future<void> _showApproveDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appTr(context, 'adm_drv_approve_confirm_title')),
        content: Text(
          [
            '${appTr(context, 'adm_drv_driver')}: ${_data['displayName']}',
            '${appTr(context, 'adm_drv_vehicle')}: ${_data['text_type_car_mndob']}',
            'Documents: V2 required (fixture)',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _showReasonDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: appTr(context, 'adm_drv_reason_hint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showActivationDialog(BuildContext context, {required bool deactivate}) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          deactivate
              ? appTr(context, 'adm_drv_suspend_title')
              : appTr(context, 'adm_drv_activate_profile_title'),
        ),
        content: Text(
          deactivate
              ? appTr(context, 'adm_drv_suspend_body')
              : appTr(context, 'adm_drv_activate_profile_body'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      AdminQaFixtures.enabled,
      'AdminDriverReviewFixtureWidget requires ADMIN_QA_FIXTURES=true',
    );
    final theme = FlutterFlowTheme.of(context);
    final bucket = _bucket;

    return Semantics(
      identifier: 'qa-driver-review',
      label: 'qa-driver-review-fixture-$reviewState',
      child: AdminEditScaffold(
        title: uiTr(context, 'مراجعة مندوب (QA)'),
        subtitle: reviewState,
        child: AdminContentCard(
          padding: AdminUi.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminStatusBadgeUnified(
                label: AdminDriverProfileView.reviewLabel(context, bucket),
                kind: AdminDriverProfileView.reviewBadgeKind(bucket),
              ),
              const SizedBox(height: 16),
              Semantics(
                identifier: 'qa-driver-info',
                label: 'qa-driver-info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _data['displayName'] as String? ?? '',
                      style: theme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_data['email']}\n${_data['phoneNumber']}\n${_data['mndob_vill_text']}',
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodyMediumIsCustom,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'qa-driver-vehicle',
                label: 'qa-driver-vehicle',
                child: Text(
                  [
                    _data['text_type_car_mndob'],
                    _data['vehicle_make'],
                    _data['vehicle_model'],
                    _data['vehicle_year'],
                  ].whereType<String>().join(' · '),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-plate',
                label: 'qa-driver-plate',
                child: Text('Plate: ${_data['plate']}'),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-email-verified',
                label: 'qa-driver-email-verified',
                child: Text(
                  'Email verified: ${_data['email_verified'] == true}',
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-phone-present',
                label: 'qa-driver-phone-present',
                child: Text(
                  'Phone present: ${_data['phone_present'] == true}',
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-review-status',
                label: 'qa-driver-review-status',
                child: Text(
                  'Review status: ${_data['registration_status']}',
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-documents',
                label: 'qa-driver-documents',
                child: Text(
                  'Documents: ${((_data['documents'] as List?) ?? const []).join(', ')}',
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                identifier: 'qa-driver-review-history',
                label: 'qa-driver-review-history',
                child: Text(
                  'Review history: ${((_data['review_history'] as List?) ?? const []).join(' → ')}',
                ),
              ),
              if ((_data['reason'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'qa-driver-reason',
                  label: 'qa-driver-reason',
                  child: Text('Reason: ${_data['reason']}'),
                ),
              ],
              if (((_data['fieldsToFix'] as List?) ?? const []).isNotEmpty) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'qa-driver-fields-to-fix',
                  label: 'qa-driver-fields-to-fix',
                  child: Text(
                    'fieldsToFix: ${((_data['fieldsToFix'] as List?) ?? const []).join(', ')}',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_showReviewActions) ...[
                Semantics(
                  identifier: 'qa-driver-approve',
                  label: 'qa-driver-approve',
                  button: true,
                  child: FFButtonWidget(
                    onPressed: () => _showApproveDialog(context),
                    text: FFLocalizations.of(context).getText(
                      'nzykcws9' /* Activate Driver Account */,
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        color: theme.info,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  identifier: 'qa-driver-request-changes',
                  label: 'qa-driver-request-changes',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () => _showReasonDialog(
                      context,
                      appTr(context, 'adm_drv_request_changes_title'),
                    ),
                    child: Text(appTr(context, 'adm_drv_request_changes_btn')),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  identifier: 'qa-driver-reject',
                  label: 'qa-driver-reject',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () => _showReasonDialog(
                      context,
                      appTr(context, 'adm_drv_reject_title'),
                    ),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(appTr(context, 'adm_drv_reject_btn')),
                  ),
                ),
              ],
              if (reviewState == 'approved')
                Semantics(
                  identifier: 'qa-driver-deactivate',
                  label: 'qa-driver-deactivate',
                  button: true,
                  child: FFButtonWidget(
                    onPressed: () =>
                        _showActivationDialog(context, deactivate: true),
                    text: FFLocalizations.of(context).getText(
                      '6qdd06ry' /* Deactivate */,
                    ),
                    icon: const Icon(Icons.person_off_rounded, size: 20),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: theme.primaryBackground,
                      textStyle: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        color: theme.error,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                      borderSide: BorderSide(color: theme.error, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (reviewState == 'rejected' && !_activated)
                Semantics(
                  identifier: 'qa-driver-activate',
                  label: 'qa-driver-activate',
                  button: true,
                  child: FFButtonWidget(
                    onPressed: () =>
                        _showActivationDialog(context, deactivate: false),
                    text: appTr(context, 'adm_drv_activate_profile_title'),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
