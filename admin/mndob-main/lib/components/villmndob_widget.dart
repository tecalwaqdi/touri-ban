import '/backend/backend.dart';
import '/backend/schema/countries_record.dart';
import '/core/driver_country_service.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'villmndob_model.dart';
export 'villmndob_model.dart';

/// اختيار الدولة ثم المحافظة ثم منطقة العمل.
class VillmndobWidget extends StatefulWidget {
  const VillmndobWidget({super.key});

  @override
  State<VillmndobWidget> createState() => _VillmndobWidgetState();
}

class _VillmndobWidgetState extends State<VillmndobWidget> {
  late VillmndobModel _model;
  bool _pickingCountry = false;
  bool _showVillages = false;
  DocumentReference? _selectedProvince;
  List<CountriesRecord> _countries = const [];
  bool _loadingCountries = true;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VillmndobModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DriverCountryService.primeRegistrationCountry(FFAppState());
      final countries = await DriverCountryService.listActiveCountries();
      if (!mounted) return;
      safeSetState(() {
        _countries = countries;
        _loadingCountries = false;
        _pickingCountry = FFAppState().dolh == null;
      });
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final countryRef = FFAppState().dolh;
    final countryName = FFAppState().naimdolh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsCard(
          margin: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.xs,
            DsSpacing.md,
            DsSpacing.sm,
          ),
          color: context.dsIsDark ? colors.card : colors.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      countryName.isNotEmpty
                          ? 'الدولة: $countryName'
                          : 'اختر الدولة أولاً',
                      style: typography.titleSmall.copyWith(
                        color: colors.primaryStrong,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DsButton.text(
                    label: 'تغيير',
                    onPressed: _loadingCountries
                        ? null
                        : () => safeSetState(() {
                              _pickingCountry = true;
                              _showVillages = false;
                              _selectedProvince = null;
                            }),
                  ),
                ],
              ),
              DsSpacing.gapXxs,
              Text(
                _pickingCountry
                    ? 'اختر دولة العمل'
                    : _showVillages
                        ? 'اختر منطقة العمل'
                        : 'اختر المحافظة / المنطقة',
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!_pickingCountry && _showVillages)
          Padding(
            padding: DsSpacing.pagePaddingHorizontal,
            child: DsButton.text(
              label: 'العودة للمحافظات',
              icon: Icons.arrow_back,
              onPressed: () => safeSetState(() {
                _showVillages = false;
                _selectedProvince = null;
              }),
            ),
          ),
        if (!_pickingCountry && !_showVillages && countryRef != null)
          Padding(
            padding: DsSpacing.pagePaddingHorizontal,
            child: DsButton.text(
              label: 'العودة لاختيار الدولة',
              icon: Icons.public,
              onPressed: () => safeSetState(() {
                _pickingCountry = true;
                _selectedProvince = null;
              }),
            ),
          ),
        Expanded(
          child: _pickingCountry
              ? _buildCountriesList(context)
              : countryRef == null
                  ? _buildNeedCountry(context)
                  : _showVillages
                      ? _buildVillagesList(context, countryRef)
                      : _buildProvincesList(context, countryRef),
        ),
      ],
    );
  }

  Widget _buildNeedCountry(BuildContext context) {
    return DsEmptyState(
      title: 'يجب اختيار الدولة لعرض المحافظات',
      icon: Icons.public_outlined,
      action: DsButton.primary(
        label: 'اختيار الدولة',
        onPressed: () => safeSetState(() => _pickingCountry = true),
      ),
    );
  }

  Widget _buildCountriesList(BuildContext context) {
    if (_loadingCountries) {
      return const Center(child: DsLoading(size: 48));
    }
    if (_countries.isEmpty) {
      return const DsEmptyState(
        title: 'لا توجد دول متاحة',
        icon: Icons.public_off_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(DsSpacing.md, 0, DsSpacing.md, DsSpacing.md),
      itemCount: _countries.length,
      separatorBuilder: (_, __) => DsSpacing.gapXs,
      itemBuilder: (context, index) {
        final country = _countries[index];
        final selected = FFAppState().dolh?.path == country.reference.path;
        return _regionTile(
          context,
          title: country.naim,
          subtitle: DriverCountryService.isoOfCountry(country),
          selected: selected,
          onTap: () async {
            await DriverCountryService.applyCountry(FFAppState(), country);
            if (!mounted) return;
            safeSetState(() {
              _pickingCountry = false;
              _showVillages = false;
              _selectedProvince = null;
            });
          },
        );
      },
    );
  }

  Widget _buildProvincesList(
    BuildContext context,
    DocumentReference countryRef,
  ) {
    final refs = TouryCountryRegistry.regionCountryRefs(countryRef);
    final dolhRefs = <DocumentReference>[
      ...refs,
      if (!refs.any((r) => r.path == countryRef.path)) countryRef,
    ];

    return StreamBuilder<List<CitiesRecord>>(
      stream: queryCitiesRecord(
        queryBuilder: (q) => q
            .whereIn('dolh', dolhRefs.take(10).toList())
            .where('acctev', isEqualTo: true),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DsErrorState(
            title: 'تعذر تحميل المحافظات',
            message: 'تحقق من الاتصال ثم أعد المحاولة.',
            onRetry: () => safeSetState(() {}),
            retryLabel: 'إعادة المحاولة',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: DsLoading(size: 48));
        }

        final provinces = snapshot.data!.toList()
          ..sort((a, b) => a.naim.compareTo(b.naim));

        if (provinces.isEmpty) {
          return DsEmptyState(
            title: 'لا توجد محافظات لهذه الدولة',
            message: 'يمكنك اختيار المناطق مباشرة إن وُجدت.',
            icon: Icons.location_city_outlined,
            action: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsButton.primary(
                  label: 'عرض المناطق',
                  onPressed: () => safeSetState(() {
                    _showVillages = true;
                    _selectedProvince = null;
                  }),
                  expanded: true,
                ),
                DsSpacing.gapXs,
                DsButton.text(
                  label: 'تغيير الدولة',
                  onPressed: () => safeSetState(() => _pickingCountry = true),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(DsSpacing.md, 0, DsSpacing.md, DsSpacing.md),
          itemCount: provinces.length,
          separatorBuilder: (_, __) => DsSpacing.gapXs,
          itemBuilder: (context, index) {
            final province = provinces[index];
            return _regionTile(
              context,
              title: province.naim,
              onTap: () => safeSetState(() {
                _selectedProvince = province.reference;
                _showVillages = true;
                FFAppState().mdenh = province.reference;
                FFAppState().naimmdenh = province.naim;
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildVillagesList(
    BuildContext context,
    DocumentReference countryRef,
  ) {
    final refs = TouryCountryRegistry.regionCountryRefs(countryRef);
    final dolhRefs = <DocumentReference>[
      ...refs,
      if (!refs.any((r) => r.path == countryRef.path)) countryRef,
    ];

    return StreamBuilder<List<VillagesRecord>>(
      stream: queryVillagesRecord(
        queryBuilder: (q) {
          var query = q.where('acctev', isEqualTo: true);
          if (_selectedProvince != null) {
            query = query.where('cities', isEqualTo: _selectedProvince);
          } else {
            query = query.whereIn('dolh', dolhRefs.take(10).toList());
          }
          return query;
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DsErrorState(
            title: 'تعذر تحميل المناطق',
            onRetry: () => safeSetState(() {}),
            retryLabel: 'إعادة المحاولة',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: DsLoading(size: 48));
        }
        final villages = snapshot.data!.toList()
          ..sort((a, b) => a.naim.compareTo(b.naim));
        if (villages.isEmpty) {
          return const DsEmptyState(
            title: 'لا توجد مناطق متاحة لهذه المحافظة حالياً',
            icon: Icons.map_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(DsSpacing.md, 0, DsSpacing.md, DsSpacing.md),
          itemCount: villages.length,
          separatorBuilder: (_, __) => DsSpacing.gapXs,
          itemBuilder: (context, index) {
            final village = villages[index];
            return _regionTile(
              context,
              title: village.naim,
              subtitle: village.naimciteText.isNotEmpty
                  ? village.naimciteText
                  : null,
              onTap: () async {
                FFAppState().villmndoBREV = village.reference;
                FFAppState().textvill = village.naim;
                if (village.cities != null) {
                  FFAppState().mdenh = village.cities;
                }
                if (village.dolh != null) {
                  final countries =
                      await DriverCountryService.listActiveCountries();
                  final match = countries
                      .where((c) => c.reference.path == village.dolh!.path)
                      .firstOrNull;
                  if (match != null) {
                    await DriverCountryService.applyCountry(
                      FFAppState(),
                      match,
                    );
                    FFAppState().villmndoBREV = village.reference;
                    FFAppState().textvill = village.naim;
                    if (village.cities != null) {
                      FFAppState().mdenh = village.cities;
                    }
                  } else {
                    FFAppState().dolh = village.dolh;
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _regionTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      onTap: onTap,
      color: selected ? colors.selected : null,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  DsSpacing.gapXxs,
                  Text(
                    subtitle,
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.chevron_left,
            color: colors.primaryStrong,
          ),
        ],
      ),
    );
  }
}
