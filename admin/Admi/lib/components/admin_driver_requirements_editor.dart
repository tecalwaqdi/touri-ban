import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Super Admin editor for `countries.driver_requirements`.
class AdminDriverRequirementsEditor extends StatefulWidget {
  const AdminDriverRequirementsEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool readOnly;

  static const knownTypes = <String>[
    'profilePhoto',
    'nationalId',
    'vehicleRegistration',
    'driverLicense',
    'vehicleInsurance',
  ];

  static Map<String, dynamic> baselineConfig() => {
        for (final t in knownTypes)
          t: {
            'enabled': t != 'vehicleInsurance',
            'required': t != 'vehicleInsurance',
            'expiryRequired':
                t == 'driverLicense' || t == 'vehicleRegistration',
            'operationalBlockingOnExpiry':
                t == 'driverLicense' || t == 'vehicleRegistration',
            'expiryWarningDays': 30,
            'effectiveFrom': null,
            'gracePeriodDays': null,
            'displayOrder': knownTypes.indexOf(t),
          },
      };

  /// Auto-seed baseline for new countries — safe defaults (no operational blocking).
  static Map<String, dynamic> operationalAutoBaselineConfig() => {
        for (final t in knownTypes)
          t: {
            'enabled': true,
            'required': t != 'vehicleInsurance',
            'expiryRequired':
                t == 'driverLicense' || t == 'vehicleRegistration',
            'operationalBlockingOnExpiry': false,
            'expiryWarningDays': 30,
            'effectiveFrom': null,
            'gracePeriodDays': null,
            'displayOrder': knownTypes.indexOf(t),
          },
      };

  @override
  State<AdminDriverRequirementsEditor> createState() =>
      _AdminDriverRequirementsEditorState();
}

class _AdminDriverRequirementsEditorState
    extends State<AdminDriverRequirementsEditor> {
  late Map<String, Map<String, dynamic>> _local;

  @override
  void initState() {
    super.initState();
    _local = _normalize(widget.value);
  }

  @override
  void didUpdateWidget(covariant AdminDriverRequirementsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value.isNotEmpty) {
      _local = _normalize(widget.value);
    }
  }

  Map<String, Map<String, dynamic>> _normalize(Map<String, dynamic> raw) {
    final out = <String, Map<String, dynamic>>{};
    for (final t in AdminDriverRequirementsEditor.knownTypes) {
      final base = AdminDriverRequirementsEditor.baselineConfig()[t]!
          as Map<String, dynamic>;
      final incoming = raw[t];
      if (incoming is Map) {
        out[t] = {
          ...base,
          ...Map<String, dynamic>.from(incoming),
        };
      } else {
        out[t] = Map<String, dynamic>.from(base);
        // Unconfigured country: start disabled until Super Admin seeds.
        if (raw.isEmpty) {
          out[t]!['enabled'] = false;
          out[t]!['required'] = false;
        }
      }
    }
    return out;
  }

  void _emit() {
    widget.onChanged({
      for (final e in _local.entries) e.key: Map<String, dynamic>.from(e.value),
    });
  }

  String _label(String type) {
    switch (type) {
      case 'profilePhoto':
        return uiTr(context, 'صورة الملف');
      case 'nationalId':
        return uiTr(context, 'الهوية');
      case 'vehicleRegistration':
        return uiTr(context, 'استمارة المركبة');
      case 'driverLicense':
        return uiTr(context, 'رخصة القيادة');
      case 'vehicleInsurance':
        return uiTr(context, 'تأمين المركبة');
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final configured = widget.value.isNotEmpty ||
        _local.values.any((e) => e['enabled'] == true);

    return AdminContentCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'متطلبات وثائق المندوب'),
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w800,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            configured
                ? uiTr(
                    context,
                    'اضبط الوثائق المطلوبة لهذه الدولة. لا يُطبَّق افتراض دولة أخرى.',
                  )
                : uiTr(
                    context,
                    'لم تُضبط المتطلبات بعد. زرع الإعدادات الأساسية أو فعّل الوثائق يدوياً قبل قبول طلبات المناديب.',
                  ),
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        _local = _normalize(
                          AdminDriverRequirementsEditor.baselineConfig(),
                        );
                      });
                      _emit();
                    },
              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: Text(uiTr(context, 'زرع الإعدادات الأساسية')),
            ),
          ),
          const SizedBox(height: 8),
          for (final type in AdminDriverRequirementsEditor.knownTypes)
            _DocConfigTile(
              title: _label(type),
              config: _local[type]!,
              readOnly: widget.readOnly,
              onChanged: (next) {
                if (widget.readOnly) return;
                setState(() => _local[type] = next);
                _emit();
              },
            ),
        ],
      ),
    );
  }
}

class _DocConfigTile extends StatelessWidget {
  const _DocConfigTile({
    required this.title,
    required this.config,
    required this.onChanged,
    this.readOnly = false,
  });

  final String title;
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final enabled = config['enabled'] == true;
    final requiredDoc = config['required'] == true;
    final expiryRequired = config['expiryRequired'] == true;
    final blocking = config['operationalBlockingOnExpiry'] == true;
    final warningDays = (config['expiryWarningDays'] as num?)?.toInt() ?? 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(title, style: theme.titleSmall),
              value: enabled,
              onChanged: readOnly
                  ? null
                  : (v) {
                      final next = Map<String, dynamic>.from(config);
                      next['enabled'] = v;
                      if (!v) {
                        next['required'] = false;
                        next['operationalBlockingOnExpiry'] = false;
                      }
                      onChanged(next);
                    },
            ),
            if (enabled) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(uiTr(context, 'مطلوب')),
                value: requiredDoc,
                onChanged: readOnly
                    ? null
                    : (v) async {
                        final turningOn = v == true && !requiredDoc;
                        if (turningOn) {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(uiTr(ctx, 'تنبيه')),
                              content: Text(
                                uiTr(
                                  ctx,
                                  'هذا التغيير قد يؤثر على المندوبين المعتمدين حاليًا.\n'
                                  'حدد تاريخ بدء التطبيق وفترة السماح قبل تفعيل المنع التشغيلي.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: Text(uiTr(ctx, 'إلغاء')),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: Text(uiTr(ctx, 'متابعة')),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                        }
                        final next = Map<String, dynamic>.from(config);
                        next['required'] = v == true;
                        if (turningOn &&
                            (next['effectiveFrom'] == null ||
                                next['gracePeriodDays'] == null)) {
                          next['effectiveFrom'] =
                              DateTime.now().toUtc().toIso8601String();
                          next['gracePeriodDays'] =
                              next['gracePeriodDays'] ?? 30;
                        }
                        onChanged(next);
                      },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(uiTr(context, 'يتطلب تاريخ انتهاء')),
                value: expiryRequired,
                onChanged: readOnly
                    ? null
                    : (v) {
                        final next = Map<String, dynamic>.from(config);
                        next['expiryRequired'] = v == true;
                        if (v != true) {
                          next['operationalBlockingOnExpiry'] = false;
                        }
                        onChanged(next);
                      },
              ),
              if (expiryRequired)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    uiTr(context, 'يمنع التشغيل عند الانتهاء'),
                  ),
                  value: blocking,
                  onChanged: readOnly
                      ? null
                      : (v) {
                          final next = Map<String, dynamic>.from(config);
                          next['operationalBlockingOnExpiry'] = v == true;
                          onChanged(next);
                        },
                ),
              if (expiryRequired)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        uiTr(context, 'أيام التحذير قبل الانتهاء'),
                        style: theme.labelMedium,
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        initialValue: '$warningDays',
                        enabled: !readOnly,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: readOnly
                            ? null
                            : (raw) {
                                final n = int.tryParse(raw.trim()) ?? 30;
                                final next =
                                    Map<String, dynamic>.from(config);
                                next['expiryWarningDays'] = n.clamp(1, 365);
                                onChanged(next);
                              },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                uiTr(context, 'تاريخ بدء التطبيق (effectiveFrom)'),
                style: theme.labelMedium,
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: '${config['effectiveFrom'] ?? ''}',
                enabled: !readOnly,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: uiTr(context, 'YYYY-MM-DD أو ISO'),
                ),
                onChanged: readOnly
                    ? null
                    : (raw) {
                        final next = Map<String, dynamic>.from(config);
                        final t = raw.trim();
                        next['effectiveFrom'] = t.isEmpty ? null : t;
                        onChanged(next);
                      },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      uiTr(context, 'فترة السماح (أيام)'),
                      style: theme.labelMedium,
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      initialValue: config['gracePeriodDays'] == null
                          ? ''
                          : '${config['gracePeriodDays']}',
                      enabled: !readOnly,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: readOnly
                          ? null
                          : (raw) {
                              final next = Map<String, dynamic>.from(config);
                              final n = int.tryParse(raw.trim());
                              next['gracePeriodDays'] = n;
                              onChanged(next);
                            },
                    ),
                  ),
                ],
              ),
              if (requiredDoc &&
                  (config['effectiveFrom'] == null ||
                      config['gracePeriodDays'] == null))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    uiTr(
                      context,
                      'بدون effectiveFrom + gracePeriodDays لن يُطبَّق المنع على المناديب المعتمدين سابقًا.',
                    ),
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: Colors.deepOrange.shade800,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
