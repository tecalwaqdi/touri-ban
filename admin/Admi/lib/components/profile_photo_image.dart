import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/admin_media_resolver.dart';
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

/// Avatar / thumbnail that supports https URLs, data-URLs, gs://, and Storage
/// paths. Firebase Storage objects under `users/` are loaded via the Auth SDK
/// (avoids anonymous GET 403 / console "CORS" noise on Flutter Web).
class ProfilePhotoImage extends StatefulWidget {
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
  State<ProfilePhotoImage> createState() => _ProfilePhotoImageState();
}

class _ProfilePhotoImageState extends State<ProfilePhotoImage> {
  Future<AdminMediaResolved>? _future;

  @override
  void initState() {
    super.initState();
    _kick(widget.photoUrl);
  }

  @override
  void didUpdateWidget(covariant ProfilePhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _kick(widget.photoUrl);
    }
  }

  void _kick(String url) {
    _future = AdminMediaResolver.resolve(url);
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.size * 0.28);
    final loaderColor = widget.loadingColor ?? AdminUi.brandTeal;
    final url = widget.photoUrl.trim();

    Widget child;
    if (url.isEmpty) {
      child = _fallback(loaderColor);
    } else {
      // Fast path for embedded data-URLs (no async).
      final embedded = decodeProfilePhotoDataUrl(url);
      if (embedded != null) {
        child = Image.memory(
          embedded,
          width: widget.size,
          height: widget.size,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(loaderColor),
        );
      } else {
        child = FutureBuilder<AdminMediaResolved>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Center(
                child: SpinKitThreeBounce(
                  color: loaderColor,
                  size: widget.size * 0.35,
                ),
              );
            }
            final resolved = snap.data;
            if (resolved == null || !resolved.ok) {
              return _fallback(loaderColor);
            }
            if (resolved.hasBytes) {
              return Image.memory(
                resolved.bytes!,
                width: widget.size,
                height: widget.size,
                fit: widget.fit,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _fallback(loaderColor),
              );
            }
            final network = resolved.networkUrl!.trim();
            // Only public/non-gated HTTPS reaches here.
            return CachedNetworkImage(
              imageUrl: network,
              width: widget.size,
              height: widget.size,
              fit: widget.fit,
              memCacheWidth: (widget.size * 2).round(),
              memCacheHeight: (widget.size * 2).round(),
              placeholder: (_, __) => Center(
                child: SpinKitThreeBounce(
                  color: loaderColor,
                  size: widget.size * 0.35,
                ),
              ),
              errorWidget: (_, __, ___) => _fallback(loaderColor),
            );
          },
        );
      }
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: child,
      ),
    );
  }

  Widget _fallback(Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Icon(Icons.person_rounded, color: color, size: widget.size * 0.5),
    );
  }
}
