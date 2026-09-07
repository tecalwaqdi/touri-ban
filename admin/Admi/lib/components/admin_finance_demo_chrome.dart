import 'package:flutter/material.dart';

import '/core/admin_finance_demo_mode.dart';
import '/core/finance/admin_finance_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Discreet Demo Mode chrome for eligible finance personas.
class AdminFinanceDemoChrome extends StatefulWidget {
  const AdminFinanceDemoChrome({super.key, required this.child});

  final Widget child;

  @override
  State<AdminFinanceDemoChrome> createState() => _AdminFinanceDemoChromeState();
}

class _AdminFinanceDemoChromeState extends State<AdminFinanceDemoChrome> {
  @override
  void initState() {
    super.initState();
    AdminFinanceDemoMode.hydrateFromLocal();
    AdminFinanceDemoMode.enabledListenable.addListener(_onChanged);
  }

  @override
  void dispose() {
    AdminFinanceDemoMode.enabledListenable.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle(bool next) async {
    await AdminFinanceDemoMode.setEnabled(next);
    AdminFinanceRepository.instance.invalidateAllFinanceSource();
    AdminFinanceRepository.instance.invalidateSettlements();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminFinanceDemoMode.canToggle) {
      return widget.child;
    }
    final theme = FlutterFlowTheme.of(context);
    final on = AdminFinanceDemoMode.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: on
              ? theme.warning.withValues(alpha: 0.12)
              : theme.secondaryBackground,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: on ? theme.warning : theme.secondaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    on
                        ? uiTr(
                            context,
                            'أنت تشاهد بيانات تجريبية — لا تمثل معاملات فعلية',
                          )
                        : uiTr(context, 'عرض البيانات التجريبية'),
                    style: theme.bodySmall.override(
                      fontFamily: 'Readex Pro',
                      color: on ? theme.primaryText : theme.secondaryText,
                      fontSize: 12,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                if (on) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      uiTr(context, 'وضع تجريبي'),
                      style: theme.bodySmall.override(
                        fontFamily: 'Readex Pro',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Switch.adaptive(
                  value: on,
                  onChanged: _toggle,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
