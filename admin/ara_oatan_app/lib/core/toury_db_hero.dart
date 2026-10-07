import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_image.dart';
import '/core/toury_image_cache.dart';

/// يُرجع أفضل رابط صورة متاح من الحالة أو من Firestore.
String touryResolveHeroImageUrl({
  String? primary,
  String? secondary,
  String? tertiary,
}) {
  for (final url in [primary, secondary, tertiary]) {
    if (url != null && url.trim().isNotEmpty) {
      return url.trim();
    }
  }
  return '';
}

Widget _heroImage({
  required String url,
  required double height,
  required double width,
  String? documentId,
  String? placeName,
  double? latitude,
  double? longitude,
}) {
  return RepaintBoundary(
    child: TouryNetworkImage(
      url: url,
      documentId: documentId,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
      width: width,
      height: height,
      fit: BoxFit.cover,
      fallbackAsset: kTouryImageFallback,
      useBrandedFallback: true,
    ),
  );
}

/// بانر علوي لصورة القرية من Firestore مباشرة (يتحدّث عند تعديل الأدمن).
///
/// Never prefer a global [FFAppState.IMGVILL] cache over the live document for
/// [villageRef] — that caused Makkah (empty img) to keep showing Taif's hero.
class TouryVillageHeroBanner extends StatelessWidget {
  const TouryVillageHeroBanner({
    super.key,
    this.height = 500,
    this.width = double.infinity,
    this.imageUrl,
    this.villageRef,
  });

  final double height;
  final double width;
  final String? imageUrl;
  final DocumentReference? villageRef;

  @override
  Widget build(BuildContext context) {
    final stateVillageRef = context.select<FFAppState, DocumentReference?>(
      (s) => s.villa,
    );
    final ref = villageRef ?? stateVillageRef;

    if (ref != null) {
      final cachedUrl = context.select<FFAppState, String>(
        (s) => s.IMGVILL,
      );
      final cachedVillagePath = context.select<FFAppState, String>(
        (s) => s.villa?.path ?? '',
      );
      // Optimistic flash only when cache belongs to THIS village.
      final cacheMatchesVillage =
          cachedUrl.trim().isNotEmpty && cachedVillagePath == ref.path;

      return FutureBuilder<VillagesRecord>(
        future: TouryFirestoreCache.villageDocumentOnce(ref),
        builder: (context, snapshot) {
          final record = snapshot.data;
          final liveImg = (record?.img ?? '').trim();
          final url = touryResolveHeroImageUrl(
            primary: liveImg.isNotEmpty ? liveImg : null,
            secondary: cacheMatchesVillage ? cachedUrl : null,
            tertiary: imageUrl,
          );
          if (liveImg.isNotEmpty && liveImg != FFAppState().IMGVILL) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (FFAppState().villa?.path == ref.path) {
                FFAppState().IMGVILL = liveImg;
              }
            });
          } else if (liveImg.isEmpty &&
              cacheMatchesVillage &&
              FFAppState().IMGVILL.isNotEmpty &&
              snapshot.connectionState == ConnectionState.done) {
            // Village has no image — clear stale cache so we don't keep a
            // neighbor city's hero.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (FFAppState().villa?.path == ref.path &&
                  FFAppState().IMGVILL.isNotEmpty) {
                FFAppState().IMGVILL = '';
              }
            });
          }
          return _heroImage(
            url: url,
            height: height,
            width: width,
            documentId: ref.id,
            placeName: record?.naim,
            latitude: record?.latLing?.latitude,
            longitude: record?.latLing?.longitude,
          );
        },
      );
    }

    final url = touryResolveHeroImageUrl(primary: imageUrl);
    return _heroImage(url: url, height: height, width: width);
  }
}

/// بانر علوي لصورة المدينة من Firestore مباشرة.
class TouryCityHeroBanner extends StatelessWidget {
  const TouryCityHeroBanner({
    super.key,
    this.height = 500,
    this.width = double.infinity,
    this.cityRef,
  });

  final double height;
  final double width;
  final DocumentReference? cityRef;

  @override
  Widget build(BuildContext context) {
    final stateCityRef = context.select<FFAppState, DocumentReference?>(
      (s) => s.mdenh,
    );
    final ref = cityRef ?? stateCityRef;
    if (ref == null) {
      return TouryVillageHeroBanner(
        height: height,
        width: width,
      );
    }

    return StreamBuilder<CitiesRecord>(
      stream: CitiesRecord.getDocument(ref),
      builder: (context, snapshot) {
        final url = touryResolveHeroImageUrl(
          primary: snapshot.data?.img,
        );
        return _heroImage(
          url: url,
          height: height,
          width: width,
          documentId: ref.id,
          placeName: snapshot.data?.naim,
        );
      },
    );
  }
}

/// بانر علوي لصورة الدولة من Firestore مباشرة.
class TouryCountryHeroBanner extends StatelessWidget {
  const TouryCountryHeroBanner({
    super.key,
    required this.countryRef,
    this.height = 230,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  final DocumentReference countryRef;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CountriesRecord>(
      stream: CountriesRecord.getDocument(countryRef),
      builder: (context, snapshot) {
        final url = snapshot.data?.img ?? '';
        return _heroImage(
          url: url,
          height: height,
          width: width,
          documentId: countryRef.id,
          placeName: snapshot.data?.naim,
        );
      },
    );
  }
}

/// عدد الوجهات (معالم) لمدينة من Firestore.
class TouryCityDestinationCount extends StatelessWidget {
  const TouryCityDestinationCount({
    super.key,
    required this.cityRef,
    this.style,
  });

  final DocumentReference cityRef;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: TouryFirestoreCache.mkanCount(
        cacheKey: 'city:${cityRef.path}',
        queryBuilder: (mkanRecord) => mkanRecord
            .where('id_cit', isEqualTo: cityRef)
            .where('acctev', isEqualTo: true),
      ),
      builder: (context, snapshot) {
        final count = snapshot.data;
        if (count == null) {
          return SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style?.color ?? Theme.of(context).colorScheme.primary,
            ),
          );
        }
        return Text(
          count.toString(),
          style: style,
        );
      },
    );
  }
}
