import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_panel_session.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_agent_session_ready.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Fast paginated Firestore list: cache-first load, limited live sync on first page.
class AdminFirestoreList<T> extends StatefulWidget {
  const AdminFirestoreList({
    super.key,
    required this.query,
    required this.recordBuilder,
    this.queryBuilder,
    this.pageSize = kAdminPageSize,
    this.liveUpdates = false,
    required this.builder,
    this.empty,
    this.loading,
    this.refreshScope,
  });

  final Query query;
  final RecordBuilder<T> recordBuilder;
  final Query Function(Query)? queryBuilder;
  final int pageSize;
  /// Real-time listener on page 1 — off by default to cut Firestore reads.
  final bool liveUpdates;
  final Widget Function(
    BuildContext context,
    List<T> items,
    AdminFirestoreListMeta<T> state,
  ) builder;
  final Widget? empty;
  final Widget? loading;
  /// When set, [AdminListRefresh.notify] reloads this list after CRUD.
  final String? refreshScope;

  @override
  State<AdminFirestoreList<T>> createState() => _AdminFirestoreListState<T>();
}

class AdminFirestoreListMeta<T> {
  AdminFirestoreListMeta({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.fromCache,
    required this.hasError,
    required this.errorMessage,
    required this.refresh,
    required this.loadMore,
    required this.totalFetched,
    this.totalAvailable,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool fromCache;
  final bool hasError;
  final String? errorMessage;
  final Future<void> Function() refresh;
  final Future<void> Function() loadMore;
  final int totalFetched;
  /// Full list size when using client-side pagination (country agents).
  final int? totalAvailable;
}

class _AdminFirestoreListState<T> extends State<AdminFirestoreList<T>> {
  final List<T> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _fromCache = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDoc;
  StreamSubscription<QuerySnapshot>? _liveSub;
  StreamSubscription<void>? _agentReadySub;
  int _page = 1;
  int _loadAttempt = 0;
  int _syncGeneration = 0;
  late final void Function() _externalRefreshListener;
  late final Future<void> Function() _externalAsyncRefreshListener;
  late final void Function(String docId) _externalRemoveListener;

  Future<void> _ensureAgentScopeReady() async {
    if (!AdminRoleService.isCountryAgent) return;
    await AdminAgentCountryLock.ensureCountryResolved();
    AdminAgentCountryLock.applyToAppState();
    if (!AdminPanelDataBootstrap.isAgentScopeReady) {
      await AdminPanelDataBootstrap.ensureReady(force: true);
    }
  }

  Query _baseQuery() {
    final builder = widget.queryBuilder ?? (q) => q;
    return builder(widget.query);
  }

  List<T> _map(QuerySnapshot snap) =>
      mapQuerySnapshot(snap, widget.recordBuilder);

  @override
  void initState() {
    super.initState();
    _externalRefreshListener = () {
      if (mounted) unawaited(_lightRefresh());
    };
    _externalAsyncRefreshListener = () {
      if (!mounted) return Future<void>.value();
      return _lightRefresh();
    };
    _externalRemoveListener = (docId) {
      if (!mounted) return;
      _syncGeneration++;
      setState(() {
        _items.removeWhere(
          (item) =>
              item is FirestoreRecord && item.reference.id == docId,
        );
      });
    };
    final scope = widget.refreshScope;
    if (scope != null) {
      AdminListRefresh.register(scope, _externalRefreshListener);
      AdminListRefresh.registerAsync(scope, _externalAsyncRefreshListener);
      AdminListRefresh.registerRemove(scope, _externalRemoveListener);
    }
    if (AdminRoleService.isCountryAgent) {
      _agentReadySub = AdminAgentSessionReady.onReady.listen((_) {
        if (!mounted || _items.isNotEmpty) return;
        _loadInitial();
      });
    }
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });
    if (AdminRoleService.isCountryAgent) {
      try {
        await AdminAgentCountryLock.ensureCountryResolved();
        AdminAgentCountryLock.applyToAppState();
      } catch (_) {}
    } else {
      try {
        await AdminPanelSession.ensureScopeReady();
      } catch (_) {}
    }
    if (!mounted) return;
    await _loadInitial();
  }

  @override
  void didUpdateWidget(covariant AdminFirestoreList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.queryBuilder != widget.queryBuilder) {
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    _liveSub?.cancel();
    _items.clear();
    _lastDoc = null;
    _hasMore = true;
    _page = 1;
    _hasError = false;
    _errorMessage = null;
    _loading = true;
    _start();
  }

  Future<void> _loadInitial() async {
    final query = _baseQuery().limit(widget.pageSize);
    final generation = ++_syncGeneration;
    var showedCache = false;

    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty && mounted && generation == _syncGeneration) {
        showedCache = true;
        setState(() {
          _items
            ..clear()
            ..addAll(_map(cached));
          _lastDoc = cached.docs.last;
          _hasMore = cached.docs.length >= widget.pageSize;
          _loading = false;
          _fromCache = true;
          _hasError = false;
          _errorMessage = null;
        });
        unawaited(_refreshFromServerInBackground(query, generation));
        return;
      }
    } catch (_) {}

    await _fetchFromServer(query, showedCache: showedCache, generation: generation);
  }

  Future<void> _refreshFromServerInBackground(Query query, int generation) async {
    try {
      final snap = await query.get(const GetOptions(source: Source.server));
      if (!mounted || generation != _syncGeneration) return;
      setState(() {
        _items
          ..clear()
          ..addAll(_map(snap));
        _lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
        _hasMore = snap.docs.length >= widget.pageSize;
        _fromCache = false;
        _hasError = false;
        _errorMessage = null;
        _page = 1;
      });
      if (widget.liveUpdates) {
        _listenFirstPage(query);
      }
    } catch (e) {
      if (!mounted || generation != _syncGeneration) return;
      if (_items.isNotEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'adm_server_refresh_failed';
        });
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'adm_load_failed_network';
      });
    }
  }

  Future<void> _fetchFromServer(
    Query query, {
    required bool showedCache,
    required int generation,
  }) async {
    try {
      var snap = await query.get(const GetOptions(source: Source.server));
      if (!mounted || generation != _syncGeneration) return;

      if (snap.docs.isEmpty &&
          AdminRoleService.isCountryAgent &&
          _loadAttempt == 0) {
        _loadAttempt++;
        await _ensureAgentScopeReady();
        snap = await _baseQuery().limit(widget.pageSize).get(
              const GetOptions(source: Source.server),
            );
        if (!mounted || generation != _syncGeneration) return;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(_map(snap));
        _lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
        _hasMore = snap.docs.length >= widget.pageSize;
        _loading = false;
        _fromCache = false;
        _hasError = false;
        _errorMessage = null;
        _page = 1;
      });

      if (widget.liveUpdates) {
        _listenFirstPage(query);
      }
    } catch (e) {
      if (!mounted) return;
      if (showedCache && _items.isNotEmpty) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'adm_server_refresh_failed';
        });
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'adm_load_failed_network';
      });
    }
  }

  void _listenFirstPage(Query query) {
    _liveSub?.cancel();
    _liveSub = query.snapshots(includeMetadataChanges: false).listen((snap) {
      if (!mounted || _page > 1) return;
      setState(() {
        final firstPage = _map(snap);
        if (_items.length <= widget.pageSize) {
          _items
            ..clear()
            ..addAll(firstPage);
          _lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
          _hasMore = snap.docs.length >= widget.pageSize;
        }
      });
    });
  }

  Future<void> refresh() => _resetAndReload();

  /// Reload first page without clearing the list first (safe after CRUD).
  Future<void> _lightRefresh() async {
    if (!mounted) return;
    final generation = ++_syncGeneration;
    final query = _baseQuery().limit(widget.pageSize);
    try {
      final snap = await query.get(const GetOptions(source: Source.server));
      if (!mounted || generation != _syncGeneration) return;
      setState(() {
        _items
          ..clear()
          ..addAll(_map(snap));
        _lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
        _hasMore = snap.docs.length >= widget.pageSize;
        _fromCache = false;
        _hasError = false;
        _errorMessage = null;
        _page = 1;
      });
      if (widget.liveUpdates) {
        _listenFirstPage(query);
      }
    } catch (e) {
      if (!mounted) return;
      if (_items.isNotEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'adm_server_refresh_failed';
        });
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'adm_load_failed_network';
      });
    }
  }

  Future<void> _resetAndReload() async {
    _liveSub?.cancel();
    _loadAttempt = 0;
    setState(() {
      _loading = true;
      _items.clear();
      _lastDoc = null;
      _hasMore = true;
      _page = 1;
      _hasError = false;
      _errorMessage = null;
    });
    if (AdminRoleService.isCountryAgent) {
      try {
        await AdminAgentCountryLock.ensureCountryResolved();
        AdminAgentCountryLock.applyToAppState();
      } catch (_) {}
    } else {
      try {
        await AdminPanelSession.ensureScopeReady();
      } catch (_) {}
    }
    if (!mounted) return;
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    if (_page >= kAdminMaxPages) return;

    setState(() => _loadingMore = true);

    try {
      final query = _baseQuery()
          .startAfterDocument(_lastDoc!)
          .limit(widget.pageSize);

      QuerySnapshot snap;
      try {
        snap = await query.get(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          snap = await query.get();
        }
      } catch (_) {
        snap = await query.get();
      }

      if (!mounted) return;

      final batch = _map(snap);
      setState(() {
        _items.addAll(batch);
        _lastDoc = snap.docs.isEmpty ? _lastDoc : snap.docs.last;
        _hasMore = snap.docs.length >= widget.pageSize;
        _loadingMore = false;
        if (batch.isNotEmpty) {
          _page++;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
          _hasError = true;
          _errorMessage = 'adm_load_more_failed';
        });
      }
    }
  }

  @override
  void dispose() {
    final scope = widget.refreshScope;
    if (scope != null) {
      AdminListRefresh.unregister(scope, _externalRefreshListener);
      AdminListRefresh.unregisterAsync(scope, _externalAsyncRefreshListener);
      AdminListRefresh.unregisterRemove(scope, _externalRemoveListener);
    }
    _liveSub?.cancel();
    _agentReadySub?.cancel();
    super.dispose();
  }

  AdminFirestoreListMeta<T> _meta() => AdminFirestoreListMeta<T>(
        isLoading: _loading,
        isLoadingMore: _loadingMore,
        hasMore: _hasMore,
        fromCache: _fromCache,
        hasError: _hasError,
        errorMessage: _errorMessage,
        refresh: refresh,
        loadMore: loadMore,
        totalFetched: _items.length,
      );

  String _localizedError(BuildContext context, String? key) {
    if (key == null) {
      return appTr(context, 'adm_load_failed');
    }
    if (key.startsWith('adm_')) {
      return appTr(context, key);
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return widget.loading ??
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
    }

    if (_hasError && _items.isEmpty) {
      return AdminListErrorState(
        message: _localizedError(context, _errorMessage),
        onRetry: refresh,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasError && _items.isNotEmpty)
          AdminListErrorBanner(
            message: _localizedError(context, _errorMessage),
            onRetry: refresh,
          ),
        widget.builder(
          context,
          List<T>.unmodifiable(_items),
          _meta(),
        ),
      ],
    );
  }
}

/// Shown when the first page fails to load.
class AdminListErrorState extends StatelessWidget {
  const AdminListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: theme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: theme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(appTr(context, 'adm_retry')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminUi.brandTeal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline warning when cached data is shown but server refresh failed.
class AdminListErrorBanner extends StatelessWidget {
  const AdminListErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 20, color: theme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: theme.labelMedium),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(appTr(context, 'adm_refresh')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer: load-more button + subtle cache indicator.
class AdminListLoadMoreFooter extends StatelessWidget {
  const AdminListLoadMoreFooter({
    super.key,
    required this.state,
    this.labelKey = 'adm_load_more',
  });

  final AdminFirestoreListMeta<dynamic> state;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (!state.hasMore && !state.isLoadingMore) {
      final total = state.totalAvailable ?? state.totalFetched;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            appTrFormat(context, 'adm_records_shown', total),
            style: theme.labelMedium.override(
              fontFamily: theme.labelMediumFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelMediumIsCustom,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: state.isLoadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : OutlinedButton.icon(
                onPressed: state.loadMore,
                icon: const Icon(Icons.expand_more_rounded, size: 20),
                label: Text(
                  state.totalAvailable != null
                      ? '${appTr(context, labelKey)} (${state.totalFetched} / ${state.totalAvailable})'
                      : appTr(context, labelKey),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminUi.brandTeal,
                  side: BorderSide(color: AdminUi.brandTeal.withValues(alpha: 0.5)),
                ),
              ),
      ),
    );
  }
}
