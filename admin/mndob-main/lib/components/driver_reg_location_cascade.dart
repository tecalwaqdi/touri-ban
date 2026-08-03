import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/backend/schema/countries_record.dart';
import '/core/driver_country_service.dart';
import '/core/driver_location_catalog_service.dart';
import '/design_system/design_system.dart';

/// Country → Region (`cities`) → City/area (`villages`) for registration.
class DriverRegLocationCascade extends StatefulWidget {
  const DriverRegLocationCascade({
    super.key,
    required this.t,
    this.onChanged,
  });

  final String Function(String) t;
  final VoidCallback? onChanged;

  @override
  State<DriverRegLocationCascade> createState() =>
      _DriverRegLocationCascadeState();
}

class _DriverRegLocationCascadeState extends State<DriverRegLocationCascade> {
  List<CountriesRecord> _countries = const [];
  List<CitiesRecord> _regions = const [];
  List<VillagesRecord> _cities = const [];

  bool _loadingCountries = true;
  bool _loadingRegions = false;
  bool _loadingCities = false;
  String? _countriesError;
  String? _regionsError;
  String? _citiesError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadCountries();
    final country = FFAppState().dolh;
    if (country != null) {
      await _loadRegions(country);
      final region = FFAppState().mdenh;
      if (region != null) {
        await _loadCities(country: country, region: region);
      }
    }
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
      _countriesError = null;
    });
    try {
      final list = await DriverCountryService.listActiveCountries(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _countries = list;
        _loadingCountries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCountries = false;
        _countriesError = widget.t('Could not load countries');
      });
    }
  }

  Future<void> _loadRegions(DocumentReference country) async {
    setState(() {
      _loadingRegions = true;
      _regionsError = null;
      _regions = const [];
      _cities = const [];
      _citiesError = null;
    });
    try {
      final list = await DriverLocationCatalogService.listRegions(country);
      if (!mounted) return;
      setState(() {
        _regions = list;
        _loadingRegions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _regionsError = widget.t('Could not load regions');
      });
    }
  }

  Future<void> _loadCities({
    required DocumentReference country,
    DocumentReference? region,
  }) async {
    setState(() {
      _loadingCities = true;
      _citiesError = null;
      _cities = const [];
    });
    try {
      final list = await DriverLocationCatalogService.listCities(
        country: country,
        region: region,
      );
      if (!mounted) return;
      setState(() {
        _cities = list;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
        _citiesError = widget.t('Could not load cities');
      });
    }
  }

  void _clearRegionAndCity() {
    FFAppState().update(() {
      FFAppState().mdenh = null;
      FFAppState().naimmdenh = '';
      FFAppState().villmndoBREV = null;
      FFAppState().textvill = '';
    });
  }

  void _clearCityOnly() {
    FFAppState().update(() {
      FFAppState().villmndoBREV = null;
      FFAppState().textvill = '';
    });
  }

  Future<void> _onCountrySelected(CountriesRecord country) async {
    await DriverCountryService.applyCountry(FFAppState(), country);
    _clearRegionAndCity();
    FFAppState().textTypeCar = '';
    FFAppState().MNDOBTYPECARrev = null;
    widget.onChanged?.call();
    await _loadRegions(country.reference);
  }

  Future<void> _onRegionSelected(CitiesRecord region) async {
    FFAppState().update(() {
      FFAppState().mdenh = region.reference;
      FFAppState().naimmdenh = region.naim;
    });
    _clearCityOnly();
    widget.onChanged?.call();
    final country = FFAppState().dolh;
    if (country != null) {
      await _loadCities(country: country, region: region.reference);
    }
  }

  void _onCitySelected(VillagesRecord city) {
    FFAppState().update(() {
      FFAppState().villmndoBREV = city.reference;
      FFAppState().textvill = city.naim;
      if (city.cities != null) {
        FFAppState().mdenh = city.cities;
      }
      if (city.naimciteText.isNotEmpty && FFAppState().naimmdenh.isEmpty) {
        FFAppState().naimmdenh = city.naimciteText;
      }
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final countryRef = FFAppState().dolh;
    final regionRef = FFAppState().mdenh;
    final cityRef = FFAppState().villmndoBREV;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.t('Country / Region / City'),
          style: typography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        DsSpacing.gapXs,
        _sectionLabel(context, widget.t('Country')),
        if (_loadingCountries)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DsSpacing.sm),
            child: DsLoading(size: 36),
          )
        else if (_countriesError != null)
          _errorRow(context, _countriesError!, _loadCountries)
        else if (_countries.isEmpty)
          _emptyRow(context, widget.t('No countries available'))
        else
          DropdownButtonFormField<String>(
            value: _countries.any((c) => c.reference.path == countryRef?.path)
                ? countryRef?.path
                : null,
            isExpanded: true,
            decoration: _decoration(context, widget.t('Select country')),
            items: _countries
                .map(
                  (c) => DropdownMenuItem(
                    value: c.reference.path,
                    child: Text(
                      c.naim.isNotEmpty
                          ? c.naim
                          : (DriverCountryService.isoOfCountry(c) ??
                              c.reference.id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (path) async {
              final match =
                  _countries.where((c) => c.reference.path == path).firstOrNull;
              if (match != null) await _onCountrySelected(match);
            },
          ),
        DsSpacing.gapSm,
        _sectionLabel(context, widget.t('Region')),
        if (countryRef == null)
          _emptyRow(context, widget.t('Select a country first'))
        else if (_loadingRegions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DsSpacing.sm),
            child: DsLoading(size: 36),
          )
        else if (_regionsError != null)
          _errorRow(context, _regionsError!, () => _loadRegions(countryRef))
        else if (_regions.isEmpty)
          _emptyRow(context, widget.t('No regions available'))
        else
          DropdownButtonFormField<String>(
            value: _regions.any((r) => r.reference.path == regionRef?.path)
                ? regionRef?.path
                : null,
            isExpanded: true,
            decoration: _decoration(context, widget.t('Select region')),
            items: _regions
                .map(
                  (r) => DropdownMenuItem(
                    value: r.reference.path,
                    child: Text(r.naim, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (path) async {
              final match =
                  _regions.where((r) => r.reference.path == path).firstOrNull;
              if (match != null) await _onRegionSelected(match);
            },
          ),
        DsSpacing.gapSm,
        _sectionLabel(context, widget.t('City')),
        if (countryRef == null || regionRef == null)
          _emptyRow(context, widget.t('Select a region first'))
        else if (_loadingCities)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DsSpacing.sm),
            child: DsLoading(size: 36),
          )
        else if (_citiesError != null)
          _errorRow(
            context,
            _citiesError!,
            () => _loadCities(country: countryRef, region: regionRef),
          )
        else if (_cities.isEmpty)
          _emptyRow(context, widget.t('No cities available'))
        else
          DropdownButtonFormField<String>(
            value: _cities.any((c) => c.reference.path == cityRef?.path)
                ? cityRef?.path
                : null,
            isExpanded: true,
            decoration: _decoration(context, widget.t('Select city')),
            items: _cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c.reference.path,
                    child: Text(c.naim, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (path) {
              final match =
                  _cities.where((c) => c.reference.path == path).firstOrNull;
              if (match != null) _onCitySelected(match);
            },
          ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xxs),
      child: Text(
        text,
        style: typography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final colors = context.dsColors;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.card,
      border: OutlineInputBorder(borderRadius: DsRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: DsRadius.medium,
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DsRadius.medium,
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  Widget _emptyRow(BuildContext context, String message) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      padding: DsSpacing.cardPadding,
      child: Text(
        message,
        style: typography.bodyMedium.copyWith(color: colors.textSecondary),
      ),
    );
  }

  Widget _errorRow(
    BuildContext context,
    String message,
    Future<void> Function() onRetry,
  ) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      padding: DsSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: typography.bodyMedium.copyWith(color: colors.error),
          ),
          DsButton.text(
            label: widget.t('Retry'),
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}
