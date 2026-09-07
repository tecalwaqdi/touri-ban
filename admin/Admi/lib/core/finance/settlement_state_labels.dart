/// Arabic labels for settlement directions, statuses, and payment methods (FIN-8).
abstract final class SettlementStateLabels {
  SettlementStateLabels._();

  static String directionAr(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'DRIVER_PAYS_COMPANY':
      case 'DRIVER_OWES_COMPANY':
        return 'مستحق للشركة على المندوب';
      case 'COMPANY_PAYS_DRIVER':
      case 'COMPANY_OWES_DRIVER':
        return 'مستحق للمندوب على الشركة';
      case 'COMPANY_PAYS_AGENT':
      case 'COMPANY_OWES_AGENT':
        return 'مستحق للوكيل على الشركة';
      case 'AGENT_PAYS_COMPANY':
        return 'مستحق للشركة على الوكيل';
      case 'BALANCED':
        return 'متوازن';
      default:
        return 'غير محدد';
    }
  }

  static String paymentDirectionAr(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'DRIVER_TO_COMPANY':
        return 'دفعة من المندوب للشركة';
      case 'COMPANY_TO_DRIVER':
        return 'دفعة من الشركة للمندوب';
      default:
        return directionAr(raw);
    }
  }

  static String statusAr(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'draft':
        return 'غير مسددة';
      case 'locked':
        return 'غير مسددة';
      case 'partially_paid':
        return 'مسددة جزئيًا';
      case 'settled':
        return 'مسددة';
      case 'voided':
        return 'ملغاة';
      case 'pending':
        return 'غير مسددة';
      case 'confirmed':
        return 'مؤكد';
      case 'reversed':
        return 'معكوس';
      case 'failed':
        return 'فشل';
      default:
        return 'غير مسددة';
    }
  }

  static String methodAr(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'cash':
        return 'نقدي';
      case 'bank_transfer':
        return 'تحويل بنكي';
      case 'external_transfer':
        return 'تحويل خارجي';
      case 'wallet':
        return 'محفظة';
      case 'existing_company_payment':
        return 'دفعة شركة سابقة';
      case 'other':
        return 'أخرى';
      default:
        return 'غير محدد';
    }
  }
}
