import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';
import '../../radius/ds_radius.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

enum DsFieldVariant { filled, outlined }

/// Unified text field for Tory Taxi Design System.
class DsTextField extends StatelessWidget {
  const DsTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.variant = DsFieldVariant.outlined,
    this.autofillHints,
    this.textDirection,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final DsFieldVariant variant;
  final Iterable<String>? autofillHints;
  final TextDirection? textDirection;

  factory DsTextField.email({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) =>
      DsTextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        label: label,
        hint: hint,
        errorText: errorText,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        prefixIcon: const Icon(Icons.mail_outline_rounded),
      );

  factory DsTextField.phone({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) =>
      DsTextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        label: label,
        hint: hint,
        errorText: errorText,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        prefixIcon: const Icon(Icons.phone_outlined),
      );

  factory DsTextField.password({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    bool obscureText = true,
    Widget? suffixIcon,
  }) =>
      DsTextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        label: label,
        hint: hint,
        errorText: errorText,
        onChanged: onChanged,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: const [AutofillHints.password],
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: suffixIcon,
      );

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final filled = widgetVariantIsFilled;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textDirection: textDirection,
      style: typography.bodyLarge.copyWith(color: colors.textPrimary),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: !enabled
            ? colors.disabled.withValues(alpha: 0.35)
            : filled
                ? colors.primarySoft
                : colors.surface,
        contentPadding: DsSpacing.inputContentPadding,
        border: _border(colors.border),
        enabledBorder: _border(colors.border),
        focusedBorder: _border(colors.focus, width: 1.6),
        errorBorder: _border(colors.error),
        focusedErrorBorder: _border(colors.error, width: 1.6),
        disabledBorder: _border(colors.disabled),
      ),
    );
  }

  bool get widgetVariantIsFilled => variant == DsFieldVariant.filled;

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: DsRadius.medium,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Search field.
class DsSearchField extends StatelessWidget {
  const DsSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DsTextField(
      controller: controller,
      hint: hint,
      onChanged: onChanged,
      enabled: enabled,
      variant: DsFieldVariant.filled,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: onClear == null
          ? null
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: DsConstants.iconSm),
            ),
      textInputAction: TextInputAction.search,
    );
  }
}

/// Dropdown field wrapper.
class DsDropdown<T> extends StatelessWidget {
  const DsDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      style: typography.bodyLarge.copyWith(color: colors.textPrimary),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconMuted),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: colors.surface,
        contentPadding: DsSpacing.inputContentPadding,
        border: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.focus, width: 1.6),
        ),
      ),
    );
  }
}
