import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppText extends StatelessWidget {
  final String keyText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const AppText(
    this.keyText, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      keyText.tr(),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}