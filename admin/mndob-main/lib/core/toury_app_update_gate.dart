import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/design_system/design_system.dart';

/// True when Admin marked [minBuild] as required and this install is older.
bool touryBuildRequiresUpdate({
  required bool enabled,
  required int minBuild,
  required int localBuild,
}) {
  if (!enabled || minBuild <= 0 || localBuild <= 0) return false;
  return localBuild < minBuild;
}

/// Blocks the app with an update card when `app_release/{releaseDocId}` says so.
class TouryAppUpdateOverlay extends StatefulWidget {
  const TouryAppUpdateOverlay({
    super.key,
    required this.child,
    required this.releaseDocId,
    required this.androidPackageId,
    required this.iosBundleId,
    required this.appName,
    this.androidStoreUrl = '',
    this.iosStoreUrl = '',
  });

  final Widget child;
  final String releaseDocId;
  final String androidPackageId;
  final String iosBundleId;
  final String appName;
  final String androidStoreUrl;
  final String iosStoreUrl;

  @override
  State<TouryAppUpdateOverlay> createState() => _TouryAppUpdateOverlayState();
}

class _TouryAppUpdateOverlayState extends State<TouryAppUpdateOverlay>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _required = false;
  bool _opening = false;
  String _currentVersion = '';
  String _requiredVersion = '';
  String _androidUrl = '';
  String _iosUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_check());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (kIsWeb || _checking) return;
    _checking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;
      final snap = await FirebaseFirestore.instance
          .collection('app_release')
          .doc(widget.releaseDocId)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final data = snap.data() ?? const <String, dynamic>{};
      final minBuild = _readBuild(data['minBuild']);
      final minVersion = '${data['minVersion'] ?? ''}'.trim();
      setState(() {
        _required = touryBuildRequiresUpdate(
          enabled: data['enabled'] == true,
          minBuild: minBuild,
          localBuild: localBuild,
        );
        _currentVersion = info.version.trim();
        _requiredVersion =
            minVersion.isNotEmpty ? minVersion : minBuild.toString();
        _androidUrl = '${data['androidUrl'] ?? ''}'.trim();
        _iosUrl = '${data['iosUrl'] ?? ''}'.trim();
      });
    } catch (e) {
      debugPrint('app update check skipped: $e');
    } finally {
      _checking = false;
    }
  }

  int _readBuild(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      var url = isIos ? _iosUrl : _androidUrl;
      if (url.isEmpty) {
        url = isIos ? widget.iosStoreUrl : widget.androidStoreUrl;
      }
      if (url.isEmpty && isIos) {
        url = await _lookupIosStoreUrl() ?? '';
      }
      if (url.isEmpty && !isIos) {
        url =
            'https://play.google.com/store/apps/details?id=${widget.androidPackageId}';
      }
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('app update store open failed: $e');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<String?> _lookupIosStoreUrl() async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': widget.iosBundleId,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is! Map) return null;
    final results = body['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return null;
    }
    final url = (results.first as Map)['trackViewUrl'];
    if (url is String && url.startsWith('https://')) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _required,
          child: widget.child,
        ),
        if (_required)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF8E8E93).withValues(alpha: 0.55),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _UpdateCard(
                      title: 'update_required_title'.tr(),
                      message: 'update_required_body'.tr(namedArgs: {
                        'current': _currentVersion,
                        'required': _requiredVersion,
                        'app': widget.appName,
                      }),
                      action: 'update_required_action'.tr(),
                      loading: _opening,
                      onUpdate: _openStore,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.title,
    required this.message,
    required this.action,
    required this.loading,
    required this.onUpdate,
  });

  final String title;
  final String message;
  final String action;
  final bool loading;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: DsTypography.fontFamily,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: DsTypography.fontFamily,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DsButton.primary(
                label: action,
                loading: loading,
                onPressed: onUpdate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
