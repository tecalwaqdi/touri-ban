"""Replace hardcoded Arabic title/subtitle with appTr in admin screens."""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1] / 'lib'

# Arabic text -> translation key
REPLACEMENTS = {
    "title: 'شركات النقل'": "title: appTr(context, 'nav_transport_companies')",
    "subtitle: 'شركات مرخّصة'": "subtitle: appTr(context, 'dash_sub_transport_cos')",
    "title: 'التقارير الإدارية'": "title: appTr(context, 'nav_reports')",
    "subtitle: 'نظرة شاملة على أداء المنصة حسب الدولة'": "subtitle: appTr(context, 'scr_reports_subtitle')",
    "title: 'سجل العمليات'": "title: appTr(context, 'nav_audit_log')",
    "title: 'سجل التدقيق'": "title: appTr(context, 'scr_audit_title')",
    "subtitle: 'تتبع عمليات الحذف والتفعيل والإلغاء في لوحة الإدارة'": "subtitle: appTr(context, 'scr_audit_subtitle')",
    "feature: 'سجل العمليات'": "feature: appTr(context, 'nav_audit_log')",
    "title: 'سوبر أدمن'": "title: appTr(context, 'nav_super_admin')",
    "feature: 'إدارة سوبر أدمن'": "feature: appTr(context, 'scr_super_admin_mgmt')",
    "subtitle: 'إضافة وتعديل وحذف حسابات السوبر أدمن'": "subtitle: appTr(context, 'scr_super_admin_subtitle')",
    "title: 'إضافة وكيل'": "title: appTr(context, 'scr_add_agent')",
    "title: 'تعديل وكيل'": "title: appTr(context, 'scr_edit_agent')",
    "title: 'إضافة سوبر أدمن'": "title: appTr(context, 'scr_add_super_admin')",
    "title: 'تعديل سوبر أدمن'": "title: appTr(context, 'scr_edit_super_admin')",
    "title: 'شركات النقل المرخّصة'": "title: appTr(context, 'scr_transport_companies')",
    "title: 'تعديل شركة نقل'": "title: appTr(context, 'scr_edit_transport')",
    "title: 'تسجيل شركة نقل'": "title: appTr(context, 'scr_register_transport')",
    "title: 'إضافة شريك جديد'": "title: appTr(context, 'scr_add_partner')",
    "title: 'إدارة المستخدمين'": "title: appTr(context, 'scr_user_mgmt')",
    "subtitle: 'إدارة الوكلاء ومتابعة أدائهم'": "subtitle: appTr(context, 'scr_agents_subtitle')",
    "subtitle: 'إدارة الدول وعرض أعلامها'": "subtitle: appTr(context, 'scr_countries_subtitle')",
    "subtitle: 'إدارة المناطق السياحية ومعالمها'": "subtitle: appTr(context, 'scr_regions_subtitle')",
    "subtitle: 'إدارة المدن وربطها بالمناطق'": "subtitle: appTr(context, 'scr_cities_subtitle')",
    "subtitle: 'إدارة حسابات مستخدمي التطبيق'": "subtitle: appTr(context, 'scr_users_subtitle')",
    "subtitle: 'إدارة المناديب وعرض بياناتهم'": "subtitle: appTr(context, 'scr_reps_subtitle')",
    "subtitle: 'متابعة الحجوزات الحالية وإدارتها'": "subtitle: appTr(context, 'scr_bookings_subtitle')",
    "subtitle: 'متابعة تذاكر الدعم الفني وحلها'": "subtitle: appTr(context, 'scr_support_subtitle')",
    "title: 'سائقو الشركة'": "title: appTr(context, 'nav_company_drivers')",
    "subtitle: 'إدارة سائقي شركتك ومركباتهم'": "subtitle: appTr(context, 'scr_company_drivers_subtitle')",
    "title: 'حجوزات الشريك'": "title: appTr(context, 'nav_partner_bookings')",
    "title: 'حجوزاتي'": "title: appTr(context, 'scr_partner_bookings_title')",
    "title: 'تقرير الوكيل'": "title: appTr(context, 'scr_agent_report')",
    "title: 'المعالم والشركاء'": "title: appTr(context, 'scr_reports_landmarks')",
    "title: 'التغطية الجغرافية'": "title: appTr(context, 'scr_reports_geo')",
    "title: 'المستخدمون والفرق'": "title: appTr(context, 'scr_reports_users')",
    "title: 'الحجوزات والدعم'": "title: appTr(context, 'scr_reports_bookings')",
    "'سجل العمليات يعرض جميع الدول — غير مرتبط بفلتر الدولة'": "appTr(context, 'scr_audit_all_countries')",
    "AppBar(title: const Text('إضافة وكيل'))": "AppBar(title: Text(appTr(context, 'scr_add_agent')))",
    "label: 'إضافة معلم'": "label: appTr(context, 'dash_add_landmark')",
    "label: 'إضافة وكيل'": "label: appTr(context, 'dash_add_agent')",
    "'إجراءات سريعة'": "appTr(context, 'dash_quick_actions')",
    "'تعذر تحميل الإحصائيات'": "appTr(context, 'dash_stats_load_failed')",
    "title: 'المحتوى والمواقع'": "title: appTr(context, 'dash_section_content')",
    "title: 'المستخدمون والعمليات'": "title: appTr(context, 'dash_section_users')",
    "subtitle: 'معالم مسجلة'": "subtitle: appTr(context, 'dash_sub_landmarks')",
    "subtitle: 'معالم الشركاء المعتمدة'": "subtitle: appTr(context, 'dash_sub_partner_landmarks')",
    "subtitle: 'دول'": "subtitle: appTr(context, 'dash_sub_countries')",
    "subtitle: 'مناطق'": "subtitle: appTr(context, 'dash_sub_regions')",
    "subtitle: 'مدن'": "subtitle: appTr(context, 'dash_sub_cities')",
    "subtitle: 'مستخدمو التطبيق'": "subtitle: appTr(context, 'dash_sub_app_users')",
    "subtitle: 'وكلاء'": "subtitle: appTr(context, 'dash_sub_agents')",
    "subtitle: 'مناديب'": "subtitle: appTr(context, 'dash_sub_reps')",
    "subtitle: 'حجوزات نشطة'": "subtitle: appTr(context, 'dash_sub_active_bookings')",
    "subtitle: 'إجمالي التذاكر'": "subtitle: appTr(context, 'dash_sub_support_tickets')",
    "label: 'معالم'": "label: appTr(context, 'dash_chart_landmarks')",
    "label: 'مستخدمون'": "label: appTr(context, 'dash_chart_users')",
    "label: 'حجوزات'": "label: appTr(context, 'dash_chart_bookings')",
    "label: const Text('إعادة المحاولة')": "label: Text(appTr(context, 'adm_retry'))",
    "_QuickLink('سجل العمليات'": "_QuickLink(appTr(context, 'nav_audit_log')",
}

UTIL_IMPORT = "import '/flutter_flow/flutter_flow_util.dart';\n"

skip_dirs = {'flutter_flow', 'backend', 'l10n'}

for path in root.rglob('*.dart'):
    if any(p in path.parts for p in skip_dirs):
        continue
    text = path.read_text(encoding='utf-8')
    orig = text
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)
    if text != orig:
        if 'appTr(' in text and "flutter_flow_util.dart" not in text:
            # insert util import after first import block line
            lines = text.splitlines(keepends=True)
            inserted = False
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i + 1, UTIL_IMPORT)
                    inserted = True
                    break
            if inserted:
                text = ''.join(lines)
        path.write_text(text, encoding='utf-8')
        print('updated', path.relative_to(root.parent))
