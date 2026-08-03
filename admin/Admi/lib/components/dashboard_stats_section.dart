import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_agent_session_ready.dart';
import '/backend/admin_panel_session.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/backend/dashboard_stats_loader.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// Dashboard stats with accurate counts and grouped graphical cards.
class DashboardStatsSection extends StatefulWidget {
  const DashboardStatsSection({super.key});

  @override
  State<DashboardStatsSection> createState() => DashboardStatsSectionState();
}

class DashboardStatsSectionState extends State<DashboardStatsSection> {
  static final Set<DashboardStatsSectionState> _liveSections = {};

  DashboardStats? _stats;
  Object? _error;
  bool _loading = false;
  String? _loadedScope;
  String? _inFlightScope;
  String? _watchedScope;
  int _animationGeneration = 0;
  StreamSubscription? _userDocSub;
  StreamSubscription? _agentReadySub;
  StreamSubscription<int>? _statsInvalidationSub;
  int _loadGeneration = 0;
  bool _waitingForRole = false;

  static bool get hasLiveSections => _liveSections.isNotEmpty;

  static void invalidateAll() {
    if (_liveSections.isEmpty) return;
    for (final section
        in List<DashboardStatsSectionState>.from(_liveSections)) {
      if (!section.mounted) continue;
      section._watchedScope = null;
      section._loadedScope = null;
      section._loadGeneration++;
      section.setState(() {
        section._loading = true;
        section._error = null;
      });
      section._scheduleLoad(force: true);
    }
  }

  /// Re-read patched cache after optimistic delete adjustment.
  static void applyOptimisticPatch() {
    if (_liveSections.isEmpty) return;
    final cached = peekDashboardStats();
    if (cached == null) return;
    for (final section
        in List<DashboardStatsSectionState>.from(_liveSections)) {
      if (!section.mounted) continue;
      section.setState(() {
        section._stats = cached;
        section._loadedScope = dashboardStatsScopeKey();
        section._watchedScope = section._loadedScope;
        section._animationGeneration++;
      });
    }
  }

  /// Force server recount without blanking the UI.
  static void reloadAllFromServer() {
    for (final section
        in List<DashboardStatsSectionState>.from(_liveSections)) {
      if (!section.mounted) continue;
      section._scheduleLoad(force: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _liveSections.add(this);
    final cached = peekDashboardStats();
    if (cached != null) {
      _stats = cached;
      _loadedScope = dashboardStatsScopeKey();
      _watchedScope = _loadedScope;
    }
    _userDocSub = authenticatedUserStream.listen(_onUserProfileChanged);
    _agentReadySub = AdminAgentSessionReady.onReady.listen(_onAgentSessionReady);
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.dashboard).listen((_) {
      if (!mounted) return;
      _loadGeneration++;
      _scheduleLoad(force: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapThenLoad();
    });
  }

  void _onAgentSessionReady(void _) {
    if (!mounted) return;
    final scope = dashboardStatsScopeKey();
    if (AdminRoleService.isCountryAgent && scope.contains(':no-country')) {
      return;
    }
    // Scope just became valid — load once; ignore later stats warm-up signals.
    if (_watchedScope == scope &&
        _stats != null &&
        _stats!.loadComplete &&
        !_stats!.isExpired) {
      return;
    }
    final cached = peekDashboardStats();
    if (cached != null && !cached.isExpired) {
      final countsChanged = _stats == null ||
          _loadedScope != scope ||
          _stats!.attractions != cached.attractions ||
          _stats!.partners != cached.partners ||
          _stats!.appUsers != cached.appUsers ||
          _stats!.representatives != cached.representatives ||
          _stats!.activeBookings != cached.activeBookings ||
          _stats!.loadComplete != cached.loadComplete;
      if (countsChanged) {
        setState(() {
          _stats = cached;
          _loadedScope = scope;
          _watchedScope = scope;
          _loading = !cached.loadComplete;
          _error = null;
          _animationGeneration++;
        });
      }
      if (cached.loadComplete) return;
    }
    if (_stats != null &&
        _stats!.loadComplete &&
        _loadedScope == scope &&
        !_stats!.isExpired) {
      return;
    }
    if (_loading && _inFlightScope == scope) return;
    _watchedScope = scope;
    _scheduleLoad(force: _loadedScope != scope);
  }

  Future<void> _bootstrapThenLoad() async {
    if (!loggedIn) return;
    final forceFromDelete = consumeDashboardStatsStaleFlag();
    if (!AdminPanelSession.isScopeReady && AdminRoleService.hasPanelAccess) {
      await AdminPanelSession.ensureScopeReady();
    }
    if (!mounted) return;
    final scope = dashboardStatsScopeKey();
    final cached = peekDashboardStats();
    _watchedScope = scope;
    if (cached != null && mounted) {
      setState(() {
        _stats = cached;
        _loadedScope = scope;
        _loading = !cached.loadComplete;
      });
    }
    _scheduleLoad(
      force: forceFromDelete || cached == null || scope.contains(':no-country'),
    );
  }

  Future<void> _ensureAgentScopeBeforeLoad() async {
    if (!AdminRoleService.isCountryAgent) return;
    await AdminPanelDataBootstrap.ensureReady();
    await AdminAgentCountryLock.ensureCountryResolved();
    AdminAgentCountryLock.applyToAppState();
  }

  void _onUserProfileChanged(UserRecord? user) {
    if (!loggedIn || user == null) return;

    final scope = dashboardStatsScopeKey();
    if (AdminRoleService.currentRole == AdminRole.none) {
      if (!_waitingForRole) {
        _waitingForRole = true;
        _waitForRoleThenLoad();
      }
      return;
    }

    _waitingForRole = false;

    if (AdminRoleService.isCountryAgent && scope.contains(':no-country')) {
      _ensureAgentScopeBeforeLoad().then((_) {
        if (!mounted) return;
        final resolved = dashboardStatsScopeKey();
        if (resolved.contains(':no-country')) return;
        if (resolved == _watchedScope) return;
        _watchedScope = resolved;
        _scheduleLoad(force: true);
      });
      return;
    }

    if (scope == _watchedScope) return;
    _watchedScope = scope;

    final scopeChanged = _loadedScope != null && _loadedScope != scope;
    _scheduleLoad(force: scopeChanged);
  }

  Future<void> _waitForRoleThenLoad() async {
    final doc = currentUserDocument;
    if (doc != null && AdminRoleService.roleFrom(doc) != AdminRole.none) {
      if (!mounted) return;
      _waitingForRole = false;
      _watchedScope = dashboardStatsScopeKey();
      _scheduleLoad();
      return;
    }

    try {
      await ensureCurrentUserDocument().timeout(const Duration(seconds: 15));
    } catch (_) {}

    if (!mounted) return;
    _waitingForRole = false;
    _watchedScope = dashboardStatsScopeKey();
    _scheduleLoad(force: true);
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _agentReadySub?.cancel();
    _statsInvalidationSub?.cancel();
    _liveSections.remove(this);
    super.dispose();
  }

  Future<void> refresh() async {
    _scheduleLoad(force: true);
    final deadline = DateTime.now().add(const Duration(seconds: 25));
    while (_loading && mounted && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _scheduleLoad({bool force = false}) {
    final scope = dashboardStatsScopeKey();
    final role = AdminRoleService.currentRole;

    if (!loggedIn) {
      return;
    }

    if (role == AdminRole.countryAgent && scope.contains(':no-country')) {
      _ensureAgentScopeBeforeLoad().then((_) {
        if (!mounted) return;
        final resolved = dashboardStatsScopeKey();
        if (resolved.contains(':no-country')) return;
        _watchedScope = resolved;
        _scheduleLoad(force: true);
      });
      return;
    }

    if (role == AdminRole.none) {
      if (!_waitingForRole) {
        _waitingForRole = true;
        _waitForRoleThenLoad();
      }
      return;
    }

    if (!force &&
        _loadedScope == scope &&
        _stats != null &&
        _stats!.loadComplete &&
        !_stats!.isExpired &&
        _error == null) {
      return;
    }

    // Same scope already loading (e.g. FCM token write) — do not restart.
    if (!force && _loading && _inFlightScope == scope) {
      return;
    }

    final scopeChanged = _loadedScope != null && _loadedScope != scope;
    final generation =
        (force || scopeChanged) ? ++_loadGeneration : _loadGeneration;
    _inFlightScope = scope;

    final cachedPeek = peekDashboardStats();
    if (_stats == null && cachedPeek != null) {
      if (mounted) {
        setState(() {
          _stats = cachedPeek;
          _loadedScope = scope;
          _loading = true;
          _error = null;
        });
      }
    } else if (_stats == null || force || scopeChanged) {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    }

    final refreshFromServer = force ||
        scopeChanged ||
        (cachedPeek != null && !cachedPeek.loadComplete);

    final manualRefresh =
        force && _stats != null && _loadedScope == scope;

    loadDashboardStats(
      forceRefresh: refreshFromServer,
      quickLandmarks: AdminRoleService.isCountryAgent && !manualRefresh,
      priorityOnly: false,
    ).then((stats) {
      if (!mounted || generation != _loadGeneration) return;
      final appliedScope = dashboardStatsScopeKey();
      if (AdminRoleService.isCountryAgent &&
          appliedScope.contains(':no-country')) {
        return;
      }
      if (appliedScope != scope && _loadedScope != null) {
        if (appliedScope != _loadedScope) {
          _inFlightScope = null;
          _scheduleLoad(force: true);
          return;
        }
      }
      setState(() {
        _stats = stats;
        _loadedScope = appliedScope;
        _watchedScope = appliedScope;
        _inFlightScope = null;
        _loading = !stats.loadComplete;
        _error = null;
        if (stats.loadComplete) {
          _animationGeneration++;
        }
      });
    }).catchError((Object e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = e;
        _inFlightScope = null;
        _loading = false;
      });
    });
  }

  void _navigateTo(BuildContext context, _DashboardStatItem item) {
    closeDrawerIfOpen(context);
    context.pushNamed(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);

    if (_stats == null && _loading) {
      return AdminContentCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    if (_error != null && (_stats == null || !_stats!.loadComplete)) {
      return AdminContentCard(
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AdminUi.brandTeal.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              appTr(context, 'dash_stats_load_failed'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _scheduleLoad(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(appTr(context, 'adm_retry')),
            ),
          ],
        ),
      );
    }

    final stats = _stats ?? DashboardStats.empty();
    final contentSections = <_DashboardStatGroup>[
      _DashboardStatGroup(
        title: appTr(context, 'dash_section_content'),
        icon: Icons.travel_explore_rounded,
        items: [
          _DashboardStatItem(
            title: l10n.getText('wx29ht01'),
            subtitle: appTr(context, 'dash_sub_landmarks'),
            icon: Icons.place_rounded,
            count: stats.attractions,
            colors: const [Color(0xFF1F7372), Color(0xFF2A9D8A)],
            route: AdminM3almWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('f0wi63xt'),
            subtitle: appTr(context, 'dash_sub_partner_landmarks'),
            icon: Icons.handshake_rounded,
            count: stats.partners,
            colors: const [Color(0xFF39D2C0), Color(0xFF2EB8A6)],
            route: AdminPartnersWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('l0vvemch'),
            subtitle: appTr(context, 'dash_sub_countries'),
            icon: Icons.flag_rounded,
            count: stats.countries,
            colors: const [Color(0xFF2E8B87), Color(0xFF1F7372)],
            route: AdminDolWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('yssiqef1'),
            subtitle: appTr(context, 'dash_sub_regions'),
            icon: Icons.filter_hdr_rounded,
            count: stats.regions,
            colors: const [Color(0xFF7A9A95), Color(0xFF5F8580)],
            route: AdminregionWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('1yttxia9'),
            subtitle: appTr(context, 'dash_sub_cities'),
            icon: Icons.location_city_rounded,
            count: stats.cities,
            colors: const [Color(0xFF3A9E99), Color(0xFF2A8580)],
            route: AdminvillWidget.routeName,
          ),
        ].where((item) => AdminRoleService.canAccessRoute(item.route)).toList(),
      ),
      _DashboardStatGroup(
        title: appTr(context, 'dash_section_users'),
        icon: Icons.hub_rounded,
        items: [
          _DashboardStatItem(
            title: l10n.getText('s8utoq9k'),
            subtitle: appTr(context, 'dash_sub_app_users'),
            icon: Icons.groups_rounded,
            count: stats.appUsers,
            colors: const [Color(0xFF1F7372), Color(0xFF185E5D)],
            route: AdminuserWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('l1e7dn8b'),
            subtitle: appTr(context, 'dash_sub_agents'),
            icon: Icons.real_estate_agent_rounded,
            count: stats.agents,
            colors: const [Color(0xFF39D2C0), Color(0xFF1F9A8A)],
            route: AdminAgentWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('ondrq8ci'),
            subtitle: appTr(context, 'dash_sub_reps'),
            icon: Icons.directions_car_rounded,
            count: stats.representatives,
            colors: const [Color(0xFF4DB6AC), Color(0xFF2E9E94)],
            route: AdmindreverWidget.routeName,
          ),
          _DashboardStatItem(
            title: appTr(context, 'nav_transport_companies'),
            subtitle: appTr(context, 'dash_sub_transport_cos'),
            icon: Icons.local_shipping_rounded,
            count: stats.transportCompanies,
            colors: const [Color(0xFF6D4C41), Color(0xFF4E342E)],
            route: AdminTransportCompaniesWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('kw5c519x'),
            subtitle: appTr(context, 'dash_sub_active_bookings'),
            icon: Icons.event_available_rounded,
            count: stats.activeBookings,
            colors: const [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
            route: AdminALLhgZWidget.routeName,
          ),
          _DashboardStatItem(
            title: l10n.getText('8d66hs1w'),
            subtitle: appTr(context, 'dash_sub_support_tickets'),
            icon: Icons.support_agent_rounded,
            count: stats.supportTickets,
            colors: const [Color(0xFFFF8A65), Color(0xFFE64A19)],
            route: AdminSuportWidget.routeName,
          ),
        ].where((item) => AdminRoleService.canAccessRoute(item.route)).toList(),
      ),
    ].where((group) => group.items.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _DashboardSummaryStrip(
          stats: stats,
          loading: _loading || !stats.loadComplete,
        ),
        const SizedBox(height: 18),
        for (var g = 0; g < contentSections.length; g++) ...[
          _DashboardGroupSection(
            group: contentSections[g],
            animationGeneration: _animationGeneration,
            groupIndex: g,
            onNavigate: (item) => _navigateTo(context, item),
          ),
          if (g < contentSections.length - 1) const SizedBox(height: 20),
        ],
        const SizedBox(height: 12),
        _DashboardSyncNote(loadedAt: stats.loadedAt),
      ],
    );
  }
}

class _DashboardStatGroup {
  const _DashboardStatGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_DashboardStatItem> items;
}

class _DashboardStatItem {
  const _DashboardStatItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.colors,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final List<Color> colors;
  final String route;
}

class _DashboardSummaryStrip extends StatelessWidget {
  const _DashboardSummaryStrip({
    required this.stats,
    this.loading = false,
  });

  final DashboardStats stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final pills = [
      _SummaryPill(
        icon: Icons.place_rounded,
        label: appTr(context, 'dash_chart_landmarks'),
        value: stats.attractions,
        color: AdminUi.brandTeal,
        loading: loading && stats.attractions == 0,
      ),
      _SummaryPill(
        icon: Icons.groups_rounded,
        label: appTr(context, 'dash_chart_users'),
        value: stats.appUsers,
        color: const Color(0xFF2A9D8A),
        loading: loading && stats.appUsers == 0,
      ),
      _SummaryPill(
        icon: Icons.event_available_rounded,
        label: appTr(context, 'dash_chart_bookings'),
        value: stats.activeBookings,
        color: const Color(0xFF5C6BC0),
        loading: loading && stats.activeBookings == 0,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pills.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: AdminUi.brandTeal.withValues(alpha: 0.12),
                ),
              Expanded(child: pills[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          if (loading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: color,
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: theme.titleLarge.override(
                  fontFamily: theme.titleLargeFamily,
                  fontWeight: FontWeight.w800,
                  useGoogleFonts: !theme.titleLargeIsCustom,
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGroupSection extends StatelessWidget {
  const _DashboardGroupSection({
    required this.group,
    required this.animationGeneration,
    required this.groupIndex,
    required this.onNavigate,
  });

  final _DashboardStatGroup group;
  final int animationGeneration;
  final int groupIndex;
  final void Function(_DashboardStatItem item) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(group.icon, size: 18, color: AdminUi.brandTeal),
            const SizedBox(width: 8),
            Text(
              group.title,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w700,
                color: AdminUi.brandTeal,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 560;
            final columns = isWide ? 3 : 2;
            final gap = 12.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < group.items.length; i++)
                  SizedBox(
                    width: itemWidth,
                    child: _DashboardStatCard(
                      key: ValueKey('${group.title}_${group.items[i].route}'),
                      item: group.items[i],
                      onTap: () => onNavigate(group.items[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final _DashboardStatItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final item = this.item;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminUi.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: item.colors.first.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      item.count.toString(),
                      style: theme.headlineSmall.override(
                        fontFamily: theme.headlineSmallFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        useGoogleFonts: !theme.headlineSmallIsCustom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: Colors.white.withValues(alpha: 0.85),
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSyncNote extends StatelessWidget {
  const _DashboardSyncNote({required this.loadedAt});

  final DateTime loadedAt;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = dateTimeFormat(
      'Hm',
      loadedAt,
      locale: FFLocalizations.of(context).languageCode,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: theme.secondaryText.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'آخر تحديث $label',
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ],
    );
  }
}
