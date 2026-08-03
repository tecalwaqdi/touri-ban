import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '/core/toury_cache_config.dart';

/// إدارة تخزين صور الشبكة — يُحدَّث عند تغيير الروابط من الأدمن.
class TouryImageCache {
  TouryImageCache._();

  static final CacheManager manager = CacheManager(
    Config(
      'toury_firestore_images',
      stalePeriod: const Duration(hours: 12),
      maxNrOfCacheObjects: TouryCacheConfig.imageMaxCacheObjects,
    ),
  );

  static String keyFor(
    String url, {
    String? documentId,
    String field = 'img',
  }) {
    final id = documentId?.trim();
    if (id != null && id.isNotEmpty) {
      return '$id:$field:$url';
    }
    return url;
  }

  static Future<void> evict(
    String url, {
    String? documentId,
    String field = 'img',
  }) async {
    if (url.trim().isEmpty) return;
    final key = keyFor(url, documentId: documentId, field: field);
    try {
      await manager.removeFile(key);
      await manager.removeFile(url);
      await DefaultCacheManager().removeFile(url);
      await CachedNetworkImage.evictFromCache(url, cacheKey: key);
      await CachedNetworkImage.evictFromCache(url);
    } catch (_) {}
  }

  static Future<void> evictAll(
    Iterable<String> urls, {
    String? documentId,
    String field = 'img',
  }) async {
    for (final url in urls) {
      await evict(url, documentId: documentId, field: field);
    }
  }
}
