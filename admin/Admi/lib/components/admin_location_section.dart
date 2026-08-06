import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/components/admin_location_service.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminLocationSection extends StatefulWidget {
  const AdminLocationSection({
    super.key,
    required this.place,
    required this.mapController,
    required this.onPlaceChanged,
    this.initialCenter,
    this.googleMapsApiKey = kAdminGoogleMapsApiKey,
  });

  final FFPlace place;
  final Completer<GoogleMapController> mapController;
  final ValueChanged<FFPlace> onPlaceChanged;
  final LatLng? initialCenter;
  final String googleMapsApiKey;

  @override
  State<AdminLocationSection> createState() => _AdminLocationSectionState();
}

class _AdminLocationSectionState extends State<AdminLocationSection> {
  late final TextEditingController _searchController;
  late final TextEditingController _coordsController;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.place.address);
    _coordsController = TextEditingController(
      text: AdminLocationService.isValidLocation(widget.place.latLng)
          ? AdminLocationService.formatCoordinates(widget.place.latLng)
          : '',
    );
  }

  @override
  void didUpdateWidget(AdminLocationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.place.address != oldWidget.place.address &&
        widget.place.address != _searchController.text) {
      _searchController.text = widget.place.address;
    }
    if (AdminLocationService.isValidLocation(widget.place.latLng)) {
      final formatted =
          AdminLocationService.formatCoordinates(widget.place.latLng);
      if (formatted != _coordsController.text) {
        _coordsController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _coordsController.dispose();
    super.dispose();
  }

  LatLng get _mapCenter {
    if (AdminLocationService.isValidLocation(widget.place.latLng)) {
      return widget.place.latLng;
    }
    return widget.initialCenter ?? AdminLocationService.defaultCenter;
  }

  Future<void> _applyCoordinates() async {
    final parsed = AdminLocationService.parseCoordinates(_coordsController.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(context, 'صيغة غير صحيحة — استخدم: 24.713600, 46.675300 أو إحداثيات DMS من Google Earth'),
          ),
        ),
      );
      return;
    }

    final address = AdminLocationService.formatCoordinates(parsed);
    widget.onPlaceChanged(
      FFPlace(
        latLng: parsed,
        name: widget.place.name,
        address: address,
      ),
    );
    _searchController.text = address;

    try {
      final controller = await widget.mapController.future;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(parsed.toGoogleMaps(), 16),
      );
    } catch (_) {}
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'اكتب اسم المكان أو العنوان للبحث'))),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _searching = true);

    try {
      final result = await AdminLocationService.geocode(
        query,
        apiKey: widget.googleMapsApiKey,
      );
      if (!mounted) {
        return;
      }
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'لم يتم العثور على الموقع — جرّب وصفاً آخر'))),
        );
        return;
      }

      widget.onPlaceChanged(
        FFPlace(
          latLng: result.latLng,
          name: result.name,
          address: result.address,
        ),
      );

      try {
        final controller = await widget.mapController.future;
        await controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            result.latLng.toGoogleMaps(),
            16,
          ),
        );
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _onCameraIdle(LatLng latLng) {
    widget.onPlaceChanged(
      FFPlace(
        latLng: latLng,
        name: widget.place.name,
        address: widget.place.address,
      ),
    );
    if (AdminLocationService.isValidLocation(latLng)) {
      _coordsController.text = AdminLocationService.formatCoordinates(latLng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasLocation = AdminLocationService.isValidLocation(widget.place.latLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: uiTr(context, 'ابحث عن موقع أو عنوان'),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: uiTr(context, 'بحث'),
                    icon: Icon(
                      Icons.search,
                      color: theme.secondaryText,
                    ),
                    onPressed: _search,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _coordsController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _applyCoordinates(),
                decoration: InputDecoration(
                  hintText: uiTr(context, 'خط العرض، خط الطول (من Google Earth)'),
                  helperText: appTr(context, 'adm_coords_example'),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.my_location_rounded,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.icon(
                onPressed: _applyCoordinates,
                icon: const Icon(Icons.pin_drop_rounded, size: 18),
                label: Text(uiTr(context, 'تطبيق')),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminUi.brandTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          uiTr(context, 'حرّك الخريطة لوضع الدبوس على الموقع المطلوب'),
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                FlutterFlowGoogleMap(
                  controller: widget.mapController,
                  onCameraIdle: _onCameraIdle,
                  initialLocation: _mapCenter,
                  markers: const [],
                  markerColor: GoogleMarkerColor.violet,
                  mapType: MapType.normal,
                  style: GoogleMapStyle.standard,
                  initialZoom: 14,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: true,
                  showLocation: true,
                  showCompass: false,
                  showMapToolbar: false,
                  showTraffic: false,
                  centerMapOnMarkerTap: false,
                  mapTakesGesturePreference: true,
                ),
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFF7B1FA2),
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: 8),
          Text(
            widget.place.address.isNotEmpty
                ? widget.place.address
                : AdminLocationService.formatCoordinates(widget.place.latLng),
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.primaryText,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${uiTr(context, 'الإحداثيات')}: ${AdminLocationService.formatCoordinates(widget.place.latLng)}',
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
          ),
        ],
      ],
    );
  }
}
