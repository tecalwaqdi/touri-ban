import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// Explicit confirmation for destructive / financial actions.
///
/// Optional finance fields ([currency], [amount], [direction], [reference])
/// are shown when provided. Existing callers remain valid.
Future<bool> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String whatHappens,
  required String subject,
  String? impact,
  String confirmLabel = '',
  String cancelLabel = '',
  bool destructive = false,
  bool irreversible = false,
  String? currency,
  String? amount,
  String? direction,
  String? reference,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final hasFinance = (currency != null && currency.isNotEmpty) ||
          (amount != null && amount.isNotEmpty) ||
          (direction != null && direction.isNotEmpty) ||
          (reference != null && reference.isNotEmpty);

      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(whatHappens),
              const SizedBox(height: 10),
              Text('${uiTr(ctx, 'العنصر')}: $subject'),
              if (impact != null && impact.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${uiTr(ctx, 'التأثير')}: $impact'),
              ],
              if (irreversible) ...[
                const SizedBox(height: 10),
                Text(
                  uiTr(ctx, 'This action is irreversible.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (hasFinance) ...[
                const SizedBox(height: 12),
                Text(
                  uiTr(ctx, 'Finance details'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                if (currency != null && currency.isNotEmpty)
                  Text('${uiTr(ctx, 'العملة')}: $currency'),
                if (amount != null && amount.isNotEmpty)
                  Text('${uiTr(ctx, 'المبلغ')}: $amount'),
                if (direction != null && direction.isNotEmpty)
                  Text('${uiTr(ctx, 'Direction')}: $direction'),
                if (reference != null && reference.isNotEmpty)
                  Text('${uiTr(ctx, 'المرجع')}: $reference'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel.isEmpty ? uiTr(ctx, 'إلغاء') : cancelLabel,
            ),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel.isEmpty ? uiTr(ctx, 'تأكيد') : confirmLabel,
            ),
          ),
        ],
      );
    },
  );
  return ok == true;
}
