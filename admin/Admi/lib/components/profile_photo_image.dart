import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/profile_photo_service.dart';
import '/components/admin_ui.dart';

Uint8List? decodeProfilePhotoDataUrl(String photoUrl) {
  if (!isProfilePhotoDataUrl(photoUrl)) {
    return null;
  }
  try {
    final comma = photoUrl.indexOf(',');
    if (comma == -1) {
      return null;
    }
    return base64Decode(photoUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

/// Avatar / thumbnail that supports https URLs and Firestore data-URL fallbacks.
class ProfilePhotoImage extends StatelessWidget {
  const ProfilePhotoImage({
    super.key,
    required this.photoUrl,
    this.size = 44,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.loadingColor,
  });

  final String photoUrl;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? loadingColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);
    final loaderColor = loadingColor ?? AdminUi.brandTeal;

    Widget child;
    if (photoUrl.isEmpty) {
      child = _fallback(loaderColor);
    } else {
      final embedded = decodeProfilePhotoDataUrl(photoUrl);
      if (embedded != null) {
        child = Image.memory(
          embedded,
          width: size,
          height: size,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(loaderColor),
        );
      } else {
        child = CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: fit,
          memCacheWidth: (size * 2).round(),
          memCacheHeight: (size * 2).round(),
          placeholder: (_, __) => Center(
            child: SpinKitThreeBounce(
              color: loaderColor,
              size: size * 0.35,
            ),
          ),
          errorWidget: (_, __, ___) => _fallback(loaderColor),
        );
      }
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _fallback(Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Icon(Icons.person_rounded, color: color, size: size * 0.5),
    );
  }
}
