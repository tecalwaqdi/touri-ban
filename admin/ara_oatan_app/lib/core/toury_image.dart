import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '/backend/firebase/firebase_app_options.dart';
import '/core/app_design_system.dart';
import '/core/toury_place_photo_service.dart';
import '/core/toury_image_cache.dart';

/// مسارات صور احتياطية عند غياب رابط صالح (ليست شعار التطبيق).
const kTouryImageFallback = 'assets/images/error_image.png';
const kTouryAvatarFallback = 'assets/images/avatar.jpg';
const kTouryRegionFallback = 'assets/images/regions.jpg';

const kTouryFirebaseStorageBucket = FirebaseAppOptions.storageBucket;

/// دلو Storage القديم (FlutterFlow) — بعض السجلات ما زالت تشير إليه.
const kTouryLegacyStorageBuckets = <String>[
  'tutorial-multi-language-70gx4j.appspot.com',
];

const kFlutterFlowGcsBase =
    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com';

const kFlutterFlowProjects = [
  'tutorial-multi-language-app-aavlbx',
  'tutorial-multi-language-70gx4j',
];

double? _finiteDimension(double? value) =>
    value != null && value.isFinite && value > 0 ? value : null;

/// صور مضمّنة في Firestore (نفس تنسيق تطبيق الأدمن عند فشل Storage).
bool touryIsEmbeddedImageDataUrl(String? raw) {
  if (raw == null) return false;
  return raw.trim().startsWith('data:image/');
}

Uint8List? touryDecodeEmbeddedImageDataUrl(String raw) {
  if (!touryIsEmbeddedImageDataUrl(raw)) return null;
  try {
    final comma = raw.indexOf(',');
    if (comma == -1) return null;
    return base64Decode(raw.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

String _firebaseStorageApiUrl(String bucket, String objectPath) {
  final clean = objectPath.startsWith('/') ? objectPath.substring(1) : objectPath;
  return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(clean)}?alt=media';
}

List<String> _splitRawImageSources(String? raw) {
  if (raw == null) return const [];
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  // لا تقسّم data-URL — الفواصل ; و , جزء من التنسيق
  if (touryIsEmbeddedImageDataUrl(trimmed)) {
    return [trimmed];
  }
  return trimmed
      .split(RegExp(r'[,;|\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

void _pushUrl(String? candidate, Set<String> seen, List<String> out) {
  final normalized = touryNormalizeImageUrl(candidate);
  if (normalized != null && seen.add(normalized)) {
    out.add(normalized);
  }
}

void _pushFlutterFlowVariants(String trimmed, Set<String> seen, List<String> out) {
  if (trimmed.startsWith('projects/')) {
    _pushUrl('$kFlutterFlowGcsBase/$trimmed', seen, out);
  }
  for (final project in kFlutterFlowProjects) {
    if (trimmed.startsWith('assets/')) {
      _pushUrl('$kFlutterFlowGcsBase/projects/$project/$trimmed', seen, out);
    }
    if (trimmed.startsWith('projects/$project/')) {
      _pushUrl('$kFlutterFlowGcsBase/$trimmed', seen, out);
    }
  }
  final assetHash = RegExp(r'^[a-z0-9]{8,}/[^/]+\.(jpg|jpeg|png|webp|gif)$',
      caseSensitive: false);
  if (assetHash.hasMatch(trimmed)) {
    for (final project in kFlutterFlowProjects) {
      _pushUrl(
        '$kFlutterFlowGcsBase/projects/$project/assets/$trimmed',
        seen,
        out,
      );
    }
  }
}

/// يولّد كل صيغ الرابط المحتملة لمصدر واحد.
List<String> touryExpandImageUrlCandidates(String? raw) {
  if (raw == null) return const [];
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  if (touryIsEmbeddedImageDataUrl(trimmed)) {
    return [trimmed];
  }

  final seen = <String>{};
  final out = <String>[];

  for (final part in _splitRawImageSources(trimmed)) {
    _pushUrl(part, seen, out);
    _pushFlutterFlowVariants(part, seen, out);

    if (!part.startsWith('http') && part.contains('/')) {
      final buckets = <String>{
        kTouryFirebaseStorageBucket,
        ...kTouryLegacyStorageBuckets,
      };
      for (final bucket in buckets) {
        _pushUrl(_firebaseStorageApiUrl(bucket, part), seen, out);
      }
    }

    if (part.contains('%')) {
      try {
        final decoded = Uri.decodeComponent(part);
        _pushUrl(decoded, seen, out);
        _pushFlutterFlowVariants(decoded, seen, out);
      } catch (_) {}
    }

    final firebaseMatch = RegExp(
      r'https?://firebasestorage\.googleapis\.com/v0/b/([^/]+)/o/([^?]+)',
    ).firstMatch(part);
    if (firebaseMatch != null) {
      final bucket = firebaseMatch.group(1)!;
      final encodedPath = firebaseMatch.group(2)!;
      _pushUrl(
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media',
        seen,
        out,
      );
      try {
        final decodedPath = Uri.decodeComponent(encodedPath);
        if (bucket != kTouryFirebaseStorageBucket) {
          _pushUrl(
            _firebaseStorageApiUrl(kTouryFirebaseStorageBucket, decodedPath),
            seen,
            out,
          );
        }
      } catch (_) {}
    }
  }

  return out;
}

/// يحمّل بايتات الصورة مباشرة من Storage (عند فشل رابط HTTP).
Future<Uint8List?> touryLoadFirebaseImageBytes(String url, {int maxBytes = 5 * 1024 * 1024}) async {
  try {
    final ref = FirebaseStorage.instance.refFromURL(url);
    return await ref.getData(maxBytes);
  } catch (_) {
    final match = RegExp(r'/o/(.+?)(\?|$)').firstMatch(url);
    if (match != null) {
      try {
        final path = Uri.decodeComponent(match.group(1)!);
        return await FirebaseStorage.instance.ref(path).getData(maxBytes);
      } catch (_) {}
    }
  }
  return null;
}

/// يجدد رابط Firebase منتهي الصلاحية.
Future<String?> touryRefreshFirebaseDownloadUrl(String url) async {
  try {
    final fresh = await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
    return touryNormalizeImageUrl(fresh);
  } catch (_) {
    final match = RegExp(r'/o/(.+?)(\?|$)').firstMatch(url);
    if (match != null) {
      try {
        final path = Uri.decodeComponent(match.group(1)!);
        final fresh = await FirebaseStorage.instance.ref(path).getDownloadURL();
        return touryNormalizeImageUrl(fresh);
      } catch (_) {}
    }
  }
  return null;
}

/// تطبيع روابط الصور من Firestore / Firebase Storage.
String? touryNormalizeImageUrl(String? raw) {
  if (raw == null) return null;
  var u = raw.trim();
  if (u.isEmpty) return null;
  if (u.startsWith('data:image/')) return u;

  final gs = RegExp(r'^gs://([^/]+)/(.+)$').firstMatch(u);
  if (gs != null) {
    return _firebaseStorageApiUrl(gs.group(1)!, gs.group(2)!);
  }

  if (u.startsWith('//')) u = 'https:$u';
  if (u.startsWith('http://')) {
    u = 'https://${u.substring(7)}';
  }
  if (!u.startsWith('http')) {
    if (u.contains('.') && !u.contains(' ')) {
      u = 'https://$u';
    } else if (u.contains('/')) {
      return _firebaseStorageApiUrl(kTouryFirebaseStorageBucket, u);
    } else {
      return null;
    }
  }

  try {
    var uri = Uri.parse(u);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    if (uri.host.endsWith('.firebasestorage.app') &&
        !uri.path.startsWith('/v0/')) {
      final bucket = uri.host;
      final objectPath = uri.path.startsWith('/')
          ? uri.path.substring(1)
          : uri.path;
      if (objectPath.isNotEmpty) {
        return _firebaseStorageApiUrl(bucket, objectPath);
      }
    }

    if (uri.host.contains('firebasestorage.googleapis.com') &&
        !uri.queryParameters.containsKey('alt')) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'alt': 'media',
        },
      );
      u = uri.toString();
    }

    return u;
  } catch (_) {
    return null;
  }
}

/// يجمع كل الروابط الصالحة بدون تكرار — الموثوقة أولاً.
List<String> touryResolveImageUrls(
  String? primary, [
  List<String?> alternates = const [],
]) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in [primary, ...alternates]) {
    for (final url in touryExpandImageUrlCandidates(raw)) {
      if (seen.add(url)) out.add(url);
    }
  }
  return touryPrioritizeReliableImageUrls(out);
}

/// يضع روابط Google/JetAdmin في نهاية القائمة لتحميل Firebase أولاً.
List<String> touryPrioritizeReliableImageUrls(List<String> urls) {
  final reliable = <String>[];
  final unreliable = <String>[];
  for (final url in urls) {
    if (touryIsEmbeddedImageDataUrl(url) ||
        !touryIsUnreliableHotlinkUrl(url)) {
      reliable.add(url);
    } else {
      unreliable.add(url);
    }
  }
  return [...reliable, ...unreliable];
}

/// مزوّد صورة للخلفيات (DecorationImage).
ImageProvider touryNetworkImageProvider(
  String? raw, {
  String fallbackAsset = kTouryImageFallback,
}) {
  if (touryIsEmbeddedImageDataUrl(raw)) {
    final bytes = touryDecodeEmbeddedImageDataUrl(raw!.trim());
    if (bytes != null) {
      return MemoryImage(bytes);
    }
  }
  final url = touryNormalizeImageUrl(raw);
  if (url != null) {
    return CachedNetworkImageProvider(url);
  }
  return AssetImage(fallbackAsset);
}

/// نص منسّق — يمنع التداخل ويحسّن القراءة العربية.
class TouryText extends StatelessWidget {
  const TouryText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.fontWeight,
    this.fontSize,
    this.color,
    this.lineHeight = 1.45,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: true,
      style: base?.copyWith(
        fontFamily: 'cairo',
        fontWeight: fontWeight ?? base.fontWeight,
        fontSize: fontSize ?? base.fontSize,
        color: color ?? base.color,
        height: lineHeight,
      ),
    );
  }
}

/// صورة من الشبكة مع محاولات متعددة وبدون شعار كبديل افتراضي.
class TouryNetworkImage extends StatefulWidget {
  const TouryNetworkImage({
    super.key,
    required this.url,
    this.alternateUrls = const [],
    this.documentId,
    this.placeName,
    this.latitude,
    this.longitude,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset,
    this.useBrandedFallback = false,
  });

  /// صور معالم: img1 ثم img2 ثم img3 مع بديل تلقائي عند الروابط المحظورة.
  factory TouryNetworkImage.fromPlaceImages({
    Key? key,
    required String? img1,
    String? img2,
    String? img3,
    String? documentId,
    String? placeName,
    double? latitude,
    double? longitude,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    String? fallbackAsset,
    bool useBrandedFallback = true,
  }) {
    final id = documentId?.trim();
    final resolvedKey = key ??
        (id != null && id.isNotEmpty
            ? ValueKey<String>('$id:${img1 ?? ''}:${img2 ?? ''}:${img3 ?? ''}')
            : null);
    return TouryNetworkImage(
      key: resolvedKey,
      url: img1,
      alternateUrls: [img2, img3],
      documentId: documentId,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      fallbackAsset: fallbackAsset ?? kTouryImageFallback,
      useBrandedFallback: useBrandedFallback,
    );
  }

  final String? url;
  final List<String?> alternateUrls;
  final String? documentId;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;
  final bool useBrandedFallback;

  @override
  State<TouryNetworkImage> createState() => _TouryNetworkImageState();
}

class _TouryNetworkImageState extends State<TouryNetworkImage> {
  int _attemptIndex = 0;
  bool _refreshingFirebase = false;
  bool _fetchingPlacePhoto = false;
  bool _placePhotoFetchDone = false;
  bool _placePhotoPrefetchStarted = false;
  bool _loadingFirebaseBytes = false;
  Uint8List? _memoryBytes;
  String? _firebaseBytesAttemptedFor;
  String? _cachedPlacePhotoUrl;
  final List<String> _extraUrls = [];

  bool get _hasReliableFirestoreImageUrls =>
      touryHasReliableImageSources(widget.url, widget.alternateUrls);

  List<String> get _urls {
    // جرّب روابط Firestore أولاً (حتى hotlinks) — البديل من ويكيبيديا فقط عند الفشل.
    final base = touryResolveImageUrls(widget.url, widget.alternateUrls);
    return <String>[...base, ..._extraUrls];
  }

  @override
  void initState() {
    super.initState();
    _maybePrefetchPlacePhoto();
  }

  @override
  void didUpdateWidget(covariant TouryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.alternateUrls != widget.alternateUrls ||
        oldWidget.documentId != widget.documentId ||
        oldWidget.placeName != widget.placeName ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      final oldUrls = touryResolveImageUrls(
        oldWidget.url,
        oldWidget.alternateUrls,
      );
      final newUrls = touryResolveImageUrls(widget.url, widget.alternateUrls);
      final urlsChanged = oldUrls.join('|') != newUrls.join('|') ||
          oldWidget.documentId != widget.documentId;
      // لا تمسح كاش الصور الجديدة — ذلك يبطّئ التمرير والقوائم المعاد تدويرها.
      if (urlsChanged && oldUrls.isNotEmpty) {
        unawaited(TouryImageCache.evictAll(
          oldUrls,
          documentId: oldWidget.documentId,
        ));
        if (oldWidget.documentId != widget.documentId) {
          touryInvalidatePlacePhotoCache(documentId: oldWidget.documentId);
        }
      }
      _memoryBytes = null;
      _loadingFirebaseBytes = false;
      _firebaseBytesAttemptedFor = null;
      _attemptIndex = 0;
      _refreshingFirebase = false;
      _fetchingPlacePhoto = false;
      _placePhotoFetchDone = false;
      _placePhotoPrefetchStarted = false;
      _cachedPlacePhotoUrl = null;
      _extraUrls.clear();
      _maybePrefetchPlacePhoto();
    }
  }

  bool get _canFetchPlacePhoto {
    final name = widget.placeName?.trim();
    return name != null && name.isNotEmpty;
  }

  /// لا تضرب ويكيبيديا إلا عند غياب صورة موثوقة من Firestore.
  void _maybePrefetchPlacePhoto() {
    if (!_canFetchPlacePhoto || _placePhotoPrefetchStarted) {
      return;
    }
    if (_hasReliableFirestoreImageUrls) {
      return;
    }
    _placePhotoPrefetchStarted = true;
    _fetchingPlacePhoto = true;
    touryResolvePlacePhotoUrl(
      documentId: widget.documentId,
      placeName: widget.placeName!.trim(),
      latitude: widget.latitude,
      longitude: widget.longitude,
    )
        .timeout(const Duration(seconds: 8))
        .then((photoUrl) {
      if (!mounted) return;
      _placePhotoFetchDone = true;
      _fetchingPlacePhoto = false;
      _cachedPlacePhotoUrl = photoUrl;
      if (photoUrl == null) {
        if (mounted) setState(() {});
        return;
      }
      if (_extraUrls.contains(photoUrl)) return;
      setState(() {
        _extraUrls.add(photoUrl);
        _attemptIndex = _urls.length - 1;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _placePhotoFetchDone = true;
        _fetchingPlacePhoto = false;
      });
    });
  }

  bool _activateCachedPlacePhoto() {
    final photoUrl = _cachedPlacePhotoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return false;
    if (_extraUrls.contains(photoUrl)) {
      setState(() => _attemptIndex = _urls.length - 1);
      return true;
    }
    setState(() {
      _extraUrls.add(photoUrl);
      _attemptIndex = _urls.length - 1;
    });
    return true;
  }

  Future<void> _fetchPlacePhotoOnFailure() async {
    if (!_canFetchPlacePhoto) return;
    if (_activateCachedPlacePhoto()) return;
    if (_placePhotoFetchDone) return;
    if (_fetchingPlacePhoto) {
      if (mounted) setState(() {});
      return;
    }
    _fetchingPlacePhoto = true;
    String? photoUrl;
    try {
      photoUrl = await touryResolvePlacePhotoUrl(
        documentId: widget.documentId,
        placeName: widget.placeName!.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      photoUrl = null;
    }
    if (!mounted) return;
    _placePhotoFetchDone = true;
    _fetchingPlacePhoto = false;
    _cachedPlacePhotoUrl = photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty && !_extraUrls.contains(photoUrl)) {
      final url = photoUrl;
      setState(() {
        _extraUrls.add(url);
        _attemptIndex = _urls.length - 1;
      });
      return;
    }
    setState(() {});
  }

  bool get _expandWidth => widget.width != null && !widget.width!.isFinite;
  bool get _expandHeight => widget.height != null && !widget.height!.isFinite;

  int _memCacheDim(double? logical, BuildContext context, {double fallbackLogical = 420}) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final base = (logical != null && logical.isFinite && logical > 0)
        ? logical
        : fallbackLogical;
    return (base * dpr).round().clamp(64, 900);
  }

  bool _isFirebaseStorageUrl(String url) =>
      url.contains('firebasestorage.googleapis.com') ||
      url.contains('.firebasestorage.app');

  void _tryNextUrl() {
    if (_attemptIndex < _urls.length - 1) {
      setState(() => _attemptIndex++);
    }
  }

  Future<void> _tryFirebaseBytesFallback(String failedUrl) async {
    if (_loadingFirebaseBytes || !mounted) return;
    _loadingFirebaseBytes = true;
    final bytes = await touryLoadFirebaseImageBytes(failedUrl);
    if (!mounted) return;
    if (bytes != null && bytes.isNotEmpty) {
      setState(() {
        _memoryBytes = bytes;
        _loadingFirebaseBytes = false;
      });
      return;
    }
    setState(() => _loadingFirebaseBytes = false);
  }

  Future<void> _refreshFirebaseUrl(String failedUrl) async {
    if (_refreshingFirebase) return;
    _refreshingFirebase = true;
    final fresh = await touryRefreshFirebaseDownloadUrl(failedUrl);
    if (!mounted) {
      _refreshingFirebase = false;
      return;
    }
    if (fresh != null && !_urls.contains(fresh)) {
      setState(() {
        _extraUrls.add(fresh);
        _attemptIndex = _urls.length - 1;
        _refreshingFirebase = false;
      });
      return;
    }
    _refreshingFirebase = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = _finiteDimension(widget.width);
    final imageHeight = _finiteDimension(widget.height);
    final urls = _urls;
    final waitingForPlacePhoto =
        _fetchingPlacePhoto && _canFetchPlacePhoto && urls.isEmpty;

    if (waitingForPlacePhoto || _loadingFirebaseBytes) {
      Widget child = _loadingBox(imageWidth, imageHeight);
      if (_expandWidth || _expandHeight) {
        child = SizedBox(
          width: _expandWidth ? double.infinity : imageWidth,
          height: _expandHeight ? double.infinity : imageHeight,
          child: child,
        );
      }
      if (widget.borderRadius != null) {
        child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
      }
      return child;
    }

    final activeUrl =
        urls.isNotEmpty && _attemptIndex < urls.length ? urls[_attemptIndex] : null;

    Widget child;
    if (_memoryBytes != null && _memoryBytes!.isNotEmpty) {
      child = Image.memory(
        _memoryBytes!,
        width: imageWidth,
        height: imageHeight,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _failureWidget(imageWidth, imageHeight),
      );
    } else if (activeUrl == null) {
      child = _fetchingPlacePhoto
          ? _loadingBox(imageWidth, imageHeight)
          : _failureWidget(imageWidth, imageHeight);
    } else if (touryIsEmbeddedImageDataUrl(activeUrl)) {
      final bytes = touryDecodeEmbeddedImageDataUrl(activeUrl);
      child = bytes != null
          ? Image.memory(
              bytes,
              width: imageWidth,
              height: imageHeight,
              fit: widget.fit,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  _failureWidget(imageWidth, imageHeight),
            )
          : _failureWidget(imageWidth, imageHeight);
    } else {
      final screenW = MediaQuery.sizeOf(context).width;
      final memW = _memCacheDim(
        imageWidth ?? screenW,
        context,
        fallbackLogical: screenW.clamp(160.0, 720.0).toDouble(),
      );
      final memH = _memCacheDim(
        imageHeight,
        context,
        fallbackLogical: (imageHeight ?? 220.0).clamp(120.0, 480.0).toDouble(),
      );
      child = CachedNetworkImage(
        key: ValueKey(
          TouryImageCache.keyFor(
            activeUrl,
            documentId: widget.documentId,
          ),
        ),
        imageUrl: activeUrl,
        cacheKey: TouryImageCache.keyFor(
          activeUrl,
          documentId: widget.documentId,
        ),
        cacheManager: TouryImageCache.manager,
        width: imageWidth,
        height: imageHeight,
        fit: widget.fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        fadeInDuration: const Duration(milliseconds: 80),
        httpHeaders: const {
          'Accept': 'image/*',
          'User-Agent': kTouryHttpUserAgent,
        },
        placeholder: (_, __) => _loadingBox(imageWidth, imageHeight),
        errorWidget: (_, __, ___) {
          if (_attemptIndex < urls.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tryNextUrl();
            });
            return _loadingBox(imageWidth, imageHeight);
          }
          if (!_refreshingFirebase &&
              !_loadingFirebaseBytes &&
              _isFirebaseStorageUrl(activeUrl) &&
              _firebaseBytesAttemptedFor != activeUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _firebaseBytesAttemptedFor = activeUrl;
              _tryFirebaseBytesFallback(activeUrl);
            });
            return _loadingBox(imageWidth, imageHeight);
          }
          if (!_refreshingFirebase &&
              _isFirebaseStorageUrl(activeUrl) &&
              _firebaseBytesAttemptedFor == activeUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _refreshFirebaseUrl(activeUrl);
            });
            return _loadingBox(imageWidth, imageHeight);
          }
          if (_canFetchPlacePhoto) {
            if (_cachedPlacePhotoUrl != null &&
                !_extraUrls.contains(_cachedPlacePhotoUrl)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _activateCachedPlacePhoto();
              });
              return _loadingBox(imageWidth, imageHeight);
            }
            if (!_placePhotoFetchDone && !_fetchingPlacePhoto) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchPlacePhotoOnFailure();
              });
              return _loadingBox(imageWidth, imageHeight);
            }
            if (_fetchingPlacePhoto) {
              return _loadingBox(imageWidth, imageHeight);
            }
          }
          return _failureWidget(imageWidth, imageHeight);
        },
      );
    }

    if (_expandWidth || _expandHeight) {
      child = SizedBox(
        width: _expandWidth ? double.infinity : imageWidth,
        height: _expandHeight ? double.infinity : imageHeight,
        child: child,
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _failureWidget(double? imageWidth, double? imageHeight) {
    if (widget.useBrandedFallback && widget.fallbackAsset != null) {
      return Image.asset(
        widget.fallbackAsset!,
        width: imageWidth,
        height: imageHeight,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _errorBox(imageWidth, imageHeight),
      );
    }
    return _errorBox(imageWidth, imageHeight);
  }

  Widget _loadingBox(double? imageWidth, double? imageHeight) => Container(
        width: imageWidth,
        height: imageHeight,
        constraints: imageWidth == null && imageHeight == null
            ? const BoxConstraints(minHeight: 80, minWidth: 80)
            : null,
        alignment: Alignment.center,
        color: TouryBrand.tealLight,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _errorBox(double? imageWidth, double? imageHeight) => Container(
        width: imageWidth,
        height: imageHeight,
        constraints: imageWidth == null && imageHeight == null
            ? const BoxConstraints(minHeight: 80, minWidth: 80)
            : null,
        color: TouryBrand.tealLight,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: TouryBrand.tealDark.withValues(alpha: 0.5),
          size: imageHeight != null && imageHeight < 60 ? 24 : 36,
        ),
      );
}

/// صورة محلية آمنة.
class TouryAssetImage extends StatelessWidget {
  const TouryAssetImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallbackAsset = kTouryImageFallback,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final imageWidth = _finiteDimension(width);
    final imageHeight = _finiteDimension(height);

    Widget child = Image.asset(
      asset,
      width: imageWidth,
      height: imageHeight,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        width: imageWidth,
        height: imageHeight,
        fit: fit,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          size: imageHeight ?? 40,
          color: TouryBrand.tealDark,
        ),
      ),
    );

    if ((width != null && !width!.isFinite) ||
        (height != null && !height!.isFinite)) {
      child = SizedBox(
        width: width != null && !width!.isFinite ? double.infinity : imageWidth,
        height:
            height != null && !height!.isFinite ? double.infinity : imageHeight,
        child: child,
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// صورة شخصية دائرية.
class TouryAvatarImage extends StatelessWidget {
  const TouryAvatarImage({
    super.key,
    required this.url,
    this.size = 100,
  });

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: TouryNetworkImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallbackAsset: kTouryAvatarFallback,
        useBrandedFallback: true,
      ),
    );
  }
}
