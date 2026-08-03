import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/driver_bootstrap.dart';
import '/core/driver_i18n.dart';
import '/core/driver_session_router.dart';
import '/design_system/design_system.dart';
import '/index.dart';
import '/main.dart';
import '/onboarding/driver_onboarding_widget.dart';

/// Single entry for `/` — resolves bootstrap then shows destination widget.
class DriverAuthGate extends StatefulWidget {
  const DriverAuthGate({super.key});

  @override
  State<DriverAuthGate> createState() => _DriverAuthGateState();
}

class _DriverAuthGateState extends State<DriverAuthGate> {
  DriverBootstrapResult? _result;
  Object? _error;
  bool _resolving = true;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    unawaited(_runBootstrap());
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) unawaited(_runBootstrap());
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _runBootstrap() async {
    if (!mounted) return;
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final result = await DriverBootstrapService.resolve(
        hasActiveTrip: FFAppState().revOrder != null,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _resolving = false;
      });
      debugPrint(
        'DriverAuthGate status=${result.status} life=${result.lifecycle} '
        '→ ${DriverSessionRouter.namedRouteForLifecycle(result.lifecycle)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _resolving = false;
        _result = DriverBootstrapResult(
          status: DriverBootstrapStatus.bootstrapError,
          errorMessage: e.toString(),
        );
      });
    }
  }

  Widget _loading() {
    final colors = context.dsColors;

    return Container(
      color: colors.scaffold,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logoTory.png',
              width: 120,
              fit: BoxFit.contain,
            ),
            DsSpacing.gapXl,
            const DsLoading(size: 40),
          ],
        ),
      ),
    );
  }

  Widget _errorBody(String message) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Center(
        child: Padding(
          padding: DsSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                driverTr(context, 'Could not start the app'),
                style: typography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              DsSpacing.gapSm,
              Text(
                driverTr(context, 'No internet connection.'),
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              DsSpacing.gapXs,
              Text(
                message,
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              DsSpacing.gapLg,
              DsButton.primary(
                label: driverTr(context, 'Retry'),
                onPressed: _runBootstrap,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving && _result == null) {
      return _loading();
    }

    final result = _result;
    if (result == null ||
        result.status == DriverBootstrapStatus.bootstrapError) {
      return _errorBody(
        result?.errorMessage ?? _error?.toString() ?? 'bootstrap',
      );
    }

    switch (result.status) {
      case DriverBootstrapStatus.loading:
        return _loading();
      case DriverBootstrapStatus.firstLaunch:
        return DriverOnboardingWidget(
          onFinished: () {
            if (mounted) unawaited(_runBootstrap());
          },
        );
      case DriverBootstrapStatus.unauthenticated:
        return const Login1Widget();
      case DriverBootstrapStatus.authenticatedMissingDriverDocument:
      case DriverBootstrapStatus.registrationIncomplete:
        return const RegdreverWidget();
      case DriverBootstrapStatus.pendingApproval:
      case DriverBootstrapStatus.changesRequested:
      case DriverBootstrapStatus.rejected:
      case DriverBootstrapStatus.suspended:
        return const DriverPendingApprovalWidget();
      case DriverBootstrapStatus.activeOffline:
      case DriverBootstrapStatus.activeOnline:
        return NavBarPage(initialPage: 'home');
      case DriverBootstrapStatus.activeTrip:
        return NavBarPage(initialPage: 'Accepted');
      case DriverBootstrapStatus.bootstrapError:
        return _errorBody(result.errorMessage ?? '');
    }
  }
}
