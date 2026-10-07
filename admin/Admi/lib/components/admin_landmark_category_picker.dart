import '/backend/admin_geo_aliases.dart';
import '/backend/admin_landmark_category_catalog.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Dropdown for landmark `tsnef` — options from `landmark_categories`.
/// Shows Arabic labels; stores the chip `storage` string the customer filters on.
class AdminLandmarkCategoryPicker extends StatefulWidget {
  const AdminLandmarkCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current `mkan.tsnef` storage value (Arabic), e.g. `معالم سياحية`.
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<AdminLandmarkCategoryPicker> createState() =>
      _AdminLandmarkCategoryPickerState();
}

class _AdminLandmarkCategoryPickerState
    extends State<AdminLandmarkCategoryPicker> {
  List<AdminLandmarkCategory> _options = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await AdminLandmarkCategoryCatalog.loadAll();
      final selectable = all
          .where((c) => c.enabled && c.storage != 'الكل' && c.id != 'all')
          .toList();
      if (!mounted) return;
      setState(() {
        _options = selectable.isNotEmpty
            ? selectable
            : AdminLandmarkCategoryCatalog.builtIn
                .where((c) => c.id != 'all')
                .toList();
        _loading = false;
        _loadError = null;
      });
      _ensureValidSelection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = AdminLandmarkCategoryCatalog.builtIn
            .where((c) => c.id != 'all')
            .toList();
        _loading = false;
        _loadError = 'تعذر تحميل التصنيفات — تم استخدام القيم الافتراضية';
      });
      _ensureValidSelection();
    }
  }

  void _ensureValidSelection() {
    final current = (widget.value ?? '').trim();
    final known = _options.any((c) => c.storage == current);
    if (known) return;
    final fallback = _options.isNotEmpty
        ? _options.first.storage
        : AdminGeoAliases.defaultLandmarkCategory;
    // Preserve unknown legacy values by injecting a synthetic option.
    if (current.isNotEmpty && !known) {
      setState(() {
        _options = [
          AdminLandmarkCategory(
            id: '_legacy',
            storage: current,
            labelAr: current,
            labelEn: current,
            icon: 'attraction',
            sort: -1,
          ),
          ..._options,
        ];
      });
      return;
    }
    if (current.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(fallback);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selected = (widget.value ?? '').trim();
    final effectiveValue = _options.any((c) => c.storage == selected)
        ? selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: effectiveValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: uiTr(context, 'نوع المعلم / التصنيف'),
              hintText: uiTr(context, 'اختر التصنيف'),
              filled: true,
              fillColor: AdminUi.fieldFill(context),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primary, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              for (final c in _options)
                DropdownMenuItem<String>(
                  value: c.storage,
                  child: Row(
                    children: [
                      Icon(
                        AdminLandmarkCategoryCatalog.materialIcon(c.icon),
                        size: 20,
                        color: theme.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.labelAr.isNotEmpty ? c.labelAr : c.storage,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null || v.trim().isEmpty) return;
              widget.onChanged(v.trim());
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return uiTr(context, 'يرجى اختيار نوع المعلم');
              }
              return null;
            },
          ),
        if (_loadError != null) ...[
          const SizedBox(height: 6),
          Text(
            uiTr(context, _loadError!),
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.warning,
              letterSpacing: 0,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          uiTr(
            context,
            'يُحفظ في حقل tsnef ويظهر في فلاتر تطبيق العميل',
          ),
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            letterSpacing: 0,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
      ],
    );
  }
}
