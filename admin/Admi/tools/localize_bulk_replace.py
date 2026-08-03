import pathlib

root = pathlib.Path(__file__).resolve().parents[1] / 'lib'
repls = [
    (
        "AdminCrudFeedback.error(context, 'تعذر الحفظ: $e')",
        'AdminCrudFeedback.error(context, AdminCrudFeedback.saveFailed(context, e))',
    ),
    (
        "AdminCrudFeedback.error(context, 'تعذر الحذف: $e')",
        'AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e))',
    ),
    (
        "SnackBar(content: Text('تعذر الحفظ: $e'))",
        'SnackBar(content: Text(AdminCrudFeedback.saveFailed(context, e)))',
    ),
    (
        "SnackBar(content: Text('تعذر الحذف: $e'))",
        'SnackBar(content: Text(AdminCrudFeedback.deleteFailed(context, e)))',
    ),
    (
        "SnackBar(content: Text('تعذر التحديث: $e'))",
        'SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e)))',
    ),
    (
        "Text('تعذر الحفظ: $e')",
        'Text(AdminCrudFeedback.saveFailed(context, e))',
    ),
    (
        "Text('تعذر الحذف: $e')",
        'Text(AdminCrudFeedback.deleteFailed(context, e))',
    ),
    (
        "'تعذر الحذف: $e'",
        'AdminCrudFeedback.deleteFailed(context, e)',
    ),
    (
        'message: AdminCrudFeedback.deleteSuccessMessage,',
        'message: AdminCrudFeedback.deleteSuccessMessage(context),',
    ),
    (
        "const SnackBar(content: Text('تم اختيار الصورة بنجاح'))",
        "SnackBar(content: Text(appTr(context, 'adm_image_selected')))",
    ),
    (
        "SnackBar(content: Text('تعذر رفع الصورة: ${uploadErrorMessage(e)}'))",
        "SnackBar(content: Text(AdminCrudFeedback.uploadFailed(context, uploadErrorMessage(e))))",
    ),
    (
        "title: const Text('تأكيد الحذف')",
        "title: Text(appTr(context, 'adm_delete_confirm_title'))",
    ),
    (
        "child: const Text('لا')",
        "child: Text(appTr(context, 'adm_no'))",
    ),
    (
        "child: const Text('نعم، احذف')",
        "child: Text(appTr(context, 'adm_yes_delete'))",
    ),
    (
        "child: const Text('إلغاء')",
        "child: Text(appTr(context, 'adm_cancel'))",
    ),
]

skip = {'internationalization.dart', 'admin_translations.dart'}

for path in root.rglob('*.dart'):
    if path.name in skip:
        continue
    text = path.read_text(encoding='utf-8')
    orig = text
    for old, new in repls:
        text = text.replace(old, new)
    if text != orig:
        path.write_text(text, encoding='utf-8')
        print('updated', path.relative_to(root.parent))
