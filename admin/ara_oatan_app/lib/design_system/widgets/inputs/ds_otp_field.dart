import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../colors/ds_colors.dart';
import '../../radius/ds_radius.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

/// OTP / pin entry — manages its own focus chain.
class DsOtpField extends StatefulWidget {
  const DsOtpField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<DsOtpField> createState() => _DsOtpFieldState();
}

class _DsOtpFieldState extends State<DsOtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() =>
      widget.onChanged(_controllers.map((c) => c.text).join());

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        return Container(
          width: 48,
          margin: EdgeInsetsDirectional.only(
            end: i == widget.length - 1 ? 0 : DsSpacing.xs,
          ),
          child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: DsSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: DsRadius.medium,
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: DsRadius.medium,
                borderSide: BorderSide(color: colors.focus, width: 1.6),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < widget.length - 1) {
                _nodes[i + 1].requestFocus();
              } else if (v.isEmpty && i > 0) {
                _nodes[i - 1].requestFocus();
              }
              _emit();
            },
          ),
        );
      }),
    );
  }
}
