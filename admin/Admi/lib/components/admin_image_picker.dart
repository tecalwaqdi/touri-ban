import 'dart:io';

import '/backend/firebase_storage/storage.dart';
import '/backend/profile_photo_service.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens gallery or camera and uploads the image. Returns download URL.
Future<String?> pickAndUploadAdminImage({
  required BuildContext context,
  required String storageFolder,
  bool useProfileCompression = false,
  bool useUserProfileCompression = false,
  bool useContentCompression = false,
  void Function(Uint8List bytes)? onLocalPreview,
}) async {
  final selected = await selectMediaWithSourceBottomSheet(
    context: context,
    allowPhoto: true,
    imageQuality: 85,
    maxWidth: 1400,
    maxHeight: 1400,
    storageFolderPath: storageFolder,
  );
  if (selected == null || selected.isEmpty) {
    return null;
  }

  final media = selected.first;
  if (!validateFileFormat(media.storagePath, context)) {
    return null;
  }

  Uint8List bytes = media.bytes;
  if (bytes.isEmpty && media.filePath != null && media.filePath!.isNotEmpty) {
    bytes = await File(media.filePath!).readAsBytes();
  }
  if (bytes.isEmpty) {
    throw Exception('لم يتم قراءة الصورة من الجوال');
  }

  onLocalPreview?.call(bytes);

  try {
    if (useUserProfileCompression) {
      return await uploadUserProfilePhoto(
        storagePath: media.storagePath,
        bytes: bytes,
        filePath: media.filePath,
      );
    }
    return await uploadAdminImage(
      storagePath: media.storagePath,
      bytes: bytes,
      filePath: media.filePath,
      maxEdge: useContentCompression
          ? kContentImageMaxEdge
          : (useProfileCompression ? kProfilePhotoMaxEdge : kAdminImageMaxEdge),
      jpegQuality: useContentCompression
          ? kContentImageJpegQuality
          : (useProfileCompression
              ? kProfilePhotoJpegQuality
              : kAdminImageJpegQuality),
      maxEmbeddedBytes: useContentCompression
          ? kContentImageMaxEmbeddedBytes
          : (useProfileCompression
              ? kUserProfileMaxEmbeddedBytes
              : kProfilePhotoMaxFirestoreBytes),
    );
  } catch (e) {
    throw Exception(uploadErrorMessage(e));
  }
}

/// Image picker card with preview for admin edit forms.
class AdminEditableImageCard extends StatelessWidget {
  const AdminEditableImageCard({
    super.key,
    required this.imageUrl,
    this.localBytes,
    required this.isUploading,
    required this.hint,
    required this.onPick,
    this.onDelete,
    this.height = 200,
  });

  final String imageUrl;
  final Uint8List? localBytes;
  final bool isUploading;
  final String hint;
  final Future<void> Function() onPick;
  final VoidCallback? onDelete;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasLocal = localBytes != null && localBytes!.isNotEmpty;
    final hasRemote = imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AdminUi.radiusMd),
          child: InkWell(
            onTap: isUploading ? null : onPick,
            borderRadius: BorderRadius.circular(AdminUi.radiusMd),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                border: Border.all(
                  color: AdminUi.brandTeal.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasLocal)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                      child: Image.memory(
                        localBytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  else if (hasRemote && isProfilePhotoDataUrl(imageUrl))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                      child: ProfilePhotoImage(
                        photoUrl: imageUrl,
                        size: height,
                        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (hasRemote)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AdminUi.brandTeal,
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(theme),
                      ),
                    )
                  else
                    _placeholder(theme),
                  if (isUploading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'تغيير الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isUploading &&
                      onDelete != null &&
                      (hasLocal || hasRemote))
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 48,
            color: AdminUi.brandTeal.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط لاختيار صورة من الجوال',
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              color: AdminUi.brandTeal,
              fontWeight: FontWeight.w600,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps existing image when user does not pick a new one.
String effectiveImageUrl({
  required String pickedUrl,
  required String existingUrl,
}) {
  if (pickedUrl.trim().isNotEmpty) {
    return pickedUrl.trim();
  }
  return existingUrl.trim();
}

/// Ensures the image is persisted for the client app (URL or compressed data-URL).
Future<String> resolveImageForFirestoreSave({
  required String pickedUrl,
  required String existingUrl,
  Uint8List? localBytes,
  int maxEmbeddedBytes = kContentImageMaxEmbeddedBytes,
}) async {
  final picked = pickedUrl.trim();
  if (picked.isNotEmpty) {
    return picked;
  }

  if (localBytes != null && localBytes.isNotEmpty) {
    final compressed = compressImageBytesForFirestore(
      localBytes,
      maxEdge: kContentImageMaxEdge,
      maxBytes: maxEmbeddedBytes,
    );
    if (compressed.length > maxEmbeddedBytes) {
      throw Exception(
        'الصورة كبيرة جداً لتخزينها في قاعدة البيانات. اختر صورة أصغر أو فعّل فوترة Firebase Storage.',
      );
    }
    return profilePhotoDataUrl(compressed);
  }

  return existingUrl.trim();
}

/// ImageProvider for network URLs and Firestore data-URL fallbacks.
ImageProvider? adminImageProvider({
  required String imageUrl,
  Uint8List? localBytes,
}) {
  if (localBytes != null && localBytes.isNotEmpty) {
    return MemoryImage(localBytes);
  }
  if (imageUrl.trim().isEmpty) {
    return null;
  }
  if (isProfilePhotoDataUrl(imageUrl)) {
    final embedded = decodeProfilePhotoDataUrl(imageUrl);
    if (embedded != null) {
      return MemoryImage(embedded);
    }
  }
  return NetworkImage(imageUrl);
}

/// Preview widget for add/edit forms (network + data-URL + local bytes).
Widget adminImagePreview({
  required String imageUrl,
  Uint8List? localBytes,
  double width = 200,
  double height = 200,
  BoxFit fit = BoxFit.cover,
  BorderRadius borderRadius = BorderRadius.zero,
}) {
  final provider = adminImageProvider(
    imageUrl: imageUrl,
    localBytes: localBytes,
  );

  Widget child;
  if (provider == null) {
    child = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: const Color(0xFFF0F4F4),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 48,
        color: AdminUi.brandTeal.withValues(alpha: 0.5),
      ),
    );
  } else {
    child = Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
    );
  }

  if (borderRadius == BorderRadius.zero) {
    return child;
  }
  return ClipRRect(borderRadius: borderRadius, child: child);
}

/// Thumbnail for admin list/table rows (https + Firestore data-URL).
class AdminRecordThumbnail extends StatelessWidget {
  const AdminRecordThumbnail({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final empty = SizedBox(
      width: width,
      height: height,
      child: fallback,
    );

    if (url.isEmpty) {
      return empty;
    }

    final provider = adminImageProvider(imageUrl: url);
    if (provider == null) {
      return empty;
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final decoded = provider is NetworkImage
        ? ResizeImage(
            provider,
            width: (width * dpr).round().clamp(48, 320),
            height: (height * dpr).round().clamp(48, 320),
          )
        : provider;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image(
        image: decoded,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => empty,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: AdminUi.brandTeal.withValues(alpha: 0.06),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AdminUi.brandTeal,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shared pick + upload handler for add/edit forms.
Future<void> handleAdminImagePick({
  required BuildContext context,
  required String storageFolder,
  required void Function(bool isUploading) setUploading,
  required void Function(FFUploadedFile local) setLocal,
  required void Function(String url) setUrl,
  bool useProfileCompression = false,
  bool useContentCompression = false,
}) async {
  setUploading(true);
  try {
    final url = await pickAndUploadAdminImage(
      context: context,
      storageFolder: storageFolder,
      useProfileCompression: useProfileCompression,
      useContentCompression: useContentCompression,
      onLocalPreview: (bytes) => setLocal(FFUploadedFile(bytes: bytes)),
    );
    if (url == null) {
      return;
    }
    setUrl(url);
    setLocal(FFUploadedFile(bytes: Uint8List.fromList([])));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appTr(context, 'adm_image_selected'))),
    );
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AdminCrudFeedback.uploadFailed(context, uploadErrorMessage(e)))),
    );
  } finally {
    setUploading(false);
  }
}
