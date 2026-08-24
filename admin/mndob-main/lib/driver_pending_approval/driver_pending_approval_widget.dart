import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_auto_activation_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_logout_service.dart';
import '/core/driver_registration_submission_service.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Pending / changes requested / rejected / suspended — live Firestore sync.
/// Navigation out uses [context.go('/')] so DriverAuthGate re-resolves.
class DriverPendingApprovalWidget extends StatefulWidget {
  const DriverPendingApprovalWidget({super.key});

  static String routeName = 'DriverPendingApproval';
  static String routePath = '/driverPendingApproval';

  @override
  State<DriverPendingApprovalWidget> createState() =>
      _DriverPendingApprovalWidgetState();
}

class _DriverPendingApprovalWidgetState
    extends State<DriverPendingApprovalWidget> {
  bool _refreshing = false;
  bool _navigatingAway = false;
  bool _repairAttempted = false;

  Future<void> _refresh() async {
    if (currentUserReference == null) return;
    setState(() => _refreshing = true);
    try {
      // V2 accounts must wait for admin review — do not call autoActivate.
      final flow = currentUserDocument?.snapshotData['registration_flow_version'];
      final isV2 = flow is num
          ? flow.toInt() == 2
          : int.tryParse('$flow') == 2;
      if (!isV2) {
        await DriverAutoActivationService.tryAutoActivate();
      }
      await currentUserReference!.get(const GetOptions(source: Source.server));
      try {
        currentUserDocument =
            await UserRecord.getDocumentOnce(currentUserReference!);
      } catch (_) {}
    } catch (e) {
      debugPrint('DriverPendingApproval refresh failed: $e');
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Error'),
          message: driverTr(context, 'No internet connection.'),
          type: DriverMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _signOut() async {
    GoRouter.of(context).prepareAuthEvent();
    await DriverLogoutService.logout();
    GoRouter.of(context).clearRedirectLocation();
    if (mounted) context.go('/');
  }

  void _maybeLeaveWhenApproved(UserRecord? doc) {
    if (doc == null || !mounted || _navigatingAway) return;
    final life = DriverLifecycleState.resolveFromDocument(doc);
    if (life == DriverLifecycle.activeOffline ||
        life == DriverLifecycle.activeOnline ||
        life == DriverLifecycle.onTrip) {
      _navigatingAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/');
      });
      return;
    }
    // Auto-activate once while waiting — Legacy only (not Registration V2).
    final flow = doc.snapshotData['registration_flow_version'];
    final isV2 = flow is num
        ? flow.toInt() == 2
        : int.tryParse('$flow') == 2;
    if (!isV2 &&
        !_repairAttempted &&
        (doc.registrationStatus.trim().toLowerCase() != 'approved' ||
            life == DriverLifecycle.pendingApproval)) {
      _repairAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await DriverAutoActivationService.tryAutoActivate();
      });
    }
  }

  Future<void> _openRegistration() async {
    if (!mounted) return;
    context.pushNamed(RegdreverWidget.routeName);
  }

  List<String> _fieldsToFixLabels(BuildContext context, dynamic raw) {
    final codes = <String>[];
    if (raw is List) {
      for (final e in raw) {
        final s = e.toString().trim();
        if (s.isNotEmpty) codes.add(s);
      }
    }
    if (codes.isEmpty) {
      return [driverTr(context, 'other')];
    }
    return codes.map((c) {
      switch (c) {
        case 'personal_info':
          return driverTr(context, 'Personal information');
        case 'vehicle':
          return driverTr(context, 'Vehicle');
        case 'national_id':
          return driverTr(context, 'National ID');
        case 'vehicle_registration':
          return driverTr(context, 'Vehicle registration');
        case 'driver_license':
          return driverTr(context, 'Driver license');
        case 'plate':
          return driverTr(context, 'Plate number');
        default:
          return driverTr(context, 'Other');
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          if (!loggedIn || currentUserReference == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/');
            });
            return Scaffold(
              backgroundColor: colors.scaffold,
              body: const DsLoading(),
            );
          }

          return Scaffold(
            backgroundColor: colors.scaffold,
            appBar: DsAppBar(
              title: driverTr(context, 'Account under review'),
              actions: [
                DsIconButton(
                  icon: Icons.logout,
                  tooltip: driverTr(context, 'Sign out'),
                  onPressed: _signOut,
                ),
              ],
            ),
            body: StreamBuilder<UserRecord>(
              stream: UserRecord.getDocument(currentUserReference!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return DsErrorState(
                    title: driverTr(context, 'Error'),
                    message: driverTr(context, 'No internet connection.'),
                    onRetry: _refresh,
                    retryLabel: driverTr(context, 'Retry'),
                  );
                }
                if (!snapshot.hasData) {
                  return const DsLoading();
                }

                final doc = snapshot.data!;
                _maybeLeaveWhenApproved(doc);

                final life = DriverLifecycleState.resolveFromDocument(doc);
                final rejected = life == DriverLifecycle.rejected;
                final suspended = life == DriverLifecycle.suspended;
                final changes = life == DriverLifecycle.changesRequested;
                final incomplete = life == DriverLifecycle.incompleteProfile;
                final pending = life == DriverLifecycle.pendingApproval;
                final reason = doc.rejectionReason.trim();
                final statusRaw = doc.registrationStatus.trim();
                final requested = DriverRequestedChange.listFrom(
                  doc.snapshotData['requested_changes'],
                ).where((c) => !c.resolved).toList();

                final title = rejected
                    ? driverTr(context, 'Your application was rejected.')
                    : suspended
                        ? driverTr(context, 'This account has been disabled.')
                        : changes
                            ? driverTr(
                                context,
                                'Admin requested changes to your application.',
                              )
                            : incomplete
                                ? driverTr(
                                    context, 'Please complete your profile.')
                                : driverTr(
                                    context,
                                    'Your account is waiting for admin approval before going online.',
                                  );

                final subtitle = rejected
                    ? driverTr(
                        context, 'Update the rejected details and resubmit.')
                    : changes
                        ? driverTr(
                            context,
                            'Review the admin notes, update the required sections, and resubmit.',
                          )
                        : incomplete
                            ? driverTr(
                                context,
                                'Continue registration to finish missing fields.',
                              )
                            : suspended
                                ? driverTr(
                                    context,
                                    'Contact support if you believe this is a mistake.',
                                  )
                                : driverTr(
                                    context,
                                    'We will notify you when an admin reviews your account. Pull to refresh or tap Refresh.',
                                  );

                final showEdit = rejected || changes || incomplete;
                final statusIcon = rejected
                    ? Icons.cancel_outlined
                    : suspended
                        ? Icons.block
                        : changes
                            ? Icons.edit_note
                            : incomplete
                                ? Icons.assignment_late_outlined
                                : Icons.hourglass_top_rounded;
                final statusColor = rejected || suspended
                    ? colors.error
                    : changes
                        ? colors.warning
                        : colors.primary;

                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: _refresh,
                  child: DriverFormWidth(
                    child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.lg,
                      DsSpacing.xxl,
                      DsSpacing.lg,
                      DsSpacing.xxxl,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, size: 48, color: statusColor),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: typography.headlineSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (statusRaw.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.md),
                        _InfoRow(
                          label: driverTr(context, 'Status'),
                          value: statusRaw,
                        ),
                      ],
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.lg),
                        DsCard(
                          padding: DsSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverTr(
                                  context,
                                  changes
                                      ? 'Requested changes'
                                      : 'Rejection reason',
                                ),
                                style: typography.titleSmall.copyWith(
                                  color: colors.error,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xs),
                              Text(
                                reason,
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (pending) ...[
                        const SizedBox(height: DsSpacing.md),
                        DsCard(
                          padding: DsSpacing.cardPadding,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: driverTr(context, 'Email'),
                                value: currentUserEmailVerified
                                    ? '${driverTr(context, 'Verified')} ✓'
                                    : driverTr(context, 'Not verified'),
                              ),
                              const DsDivider(),
                              _InfoRow(
                                label: driverTr(context, 'Phone number'),
                                value: doc.phoneNumber.trim().isNotEmpty
                                    ? '${driverTr(context, 'Added')} ✓'
                                    : driverTr(context, 'Missing'),
                              ),
                              const DsDivider(),
                              _InfoRow(
                                label: driverTr(context, 'Documents'),
                                value: (() {
                                  final raw = '${doc.snapshotData['registration_documents_status'] ?? ''}'
                                      .trim();
                                  if (raw == 'complete') {
                                    return '${driverTr(context, 'Complete')} ✓';
                                  }
                                  if (raw == 'needs_reupload') {
                                    return driverTr(context, 'Needs reupload');
                                  }
                                  if (raw == 'missing') {
                                    return driverTr(context, 'Missing');
                                  }
                                  return driverTr(context, 'Unknown');
                                })(),
                              ),
                              const DsDivider(),
                              _InfoRow(
                                label: driverTr(context, 'Status'),
                                value: driverTr(context, 'Pending review'),
                              ),
                              const DsDivider(),
                              _InfoRow(
                                label: driverTr(context, 'Review attempt'),
                                value:
                                    '${doc.snapshotData['reviewAttemptCount'] ?? 1}',
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (changes) ...[
                        const SizedBox(height: DsSpacing.md),
                        DsCard(
                          padding: DsSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverTr(context, 'Fields to fix'),
                                style: typography.titleSmall.copyWith(
                                  color: colors.warning,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xs),
                              ..._fieldsToFixLabels(
                                context,
                                doc.snapshotData['fieldsToFix'],
                              ).map(
                                (label) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: DsSpacing.xs),
                                  child: Text('• $label'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (requested.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.sm),
                        ...requested.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: DsSpacing.xs),
                            child: _InfoRow(
                              label: c.section.isEmpty
                                  ? driverTr(context, 'Requested changes')
                                  : c.section,
                              value: c.adminMessage.isNotEmpty
                                  ? c.adminMessage
                                  : reason,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: DsSpacing.md),
                      DsCard(
                        padding: DsSpacing.cardPadding,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: driverTr(context, 'Name'),
                              value: doc.displayName.isEmpty
                                  ? '—'
                                  : doc.displayName,
                            ),
                            const DsDivider(),
                            _InfoRow(
                              label: driverTr(context, 'Email'),
                              value: doc.email.isEmpty
                                  ? currentUserEmail
                                  : doc.email,
                            ),
                            const DsDivider(),
                            _InfoRow(
                              label: driverTr(context, 'Phone'),
                              value: doc.phoneNumber.isEmpty
                                  ? '—'
                                  : doc.phoneNumber,
                            ),
                            const DsDivider(),
                            _InfoRow(
                              label: driverTr(context, 'Submitted'),
                              value: doc.createdTime != null
                                  ? dateTimeFormat('yMMMd', doc.createdTime)
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      if (pending || changes || rejected || suspended)
                        DsButton.primary(
                          label: _refreshing
                              ? driverTr(context, 'Refreshing…')
                              : driverTr(context, 'Refresh status'),
                          loading: _refreshing,
                          enabled: !_refreshing,
                          expanded: true,
                          size: DsButtonSize.lg,
                          onPressed: _refresh,
                        ),
                      if (showEdit) ...[
                        const SizedBox(height: DsSpacing.sm),
                        DsButton.outlined(
                          label: incomplete
                              ? driverTr(context, 'Continue registration')
                              : driverTr(context, 'Edit and resubmit'),
                          expanded: true,
                          size: DsButtonSize.lg,
                          onPressed: _openRegistration,
                        ),
                      ],
                      const SizedBox(height: DsSpacing.sm),
                      DsButton.outlined(
                        label: driverTr(context, 'Contact support'),
                        expanded: true,
                        size: DsButtonSize.lg,
                        onPressed: () =>
                            context.pushNamed(SuportWidget.routeName),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
