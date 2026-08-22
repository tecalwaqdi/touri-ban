import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/components/admin_format.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
import 'package:admin_arawatan/backend/admin_role_matrix.dart';

void main() {
  test('AdminFormat null-safe money and count', () {
    expect(AdminFormat.count(null), '—');
    expect(AdminFormat.moneyMinor(null, 'SAR'), '—');
    final money = AdminFormat.money(
      MoneyAmount(currency: 'SAR', minorUnits: 124550),
    );
    expect(money.contains('SAR'), isTrue);
    expect(money.contains('1245.50') || money.contains('1,245.50'), isTrue);
  });

  test('role matrix includes settlements approve for finance', () {
    final s = kAdminRoleMatrix['Settlements']![AdminPermRole.finance]!;
    expect(s.contains(AdminPermAction.approve), isTrue);
    expect(
      kAdminRoleMatrix['Periods']![AdminPermRole.countryAdmin]!
          .contains(AdminPermAction.closePeriod),
      isFalse,
    );
  });
}
