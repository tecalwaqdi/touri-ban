# استبدال بيانات المحتوى

هذا الملف يشرح الخطوة الوحيدة التي تحتاج صلاحية مالك/مدير في Firebase. السكربت جاهز ويستبدل فقط:

- `countries`
- `cities`
- `villages`
- `mkan`
- `type_car`

لا يلمس المستخدمين، الطلبات، المحافظ، المدفوعات، أو سجل العمليات.

## الخيار الأسهل: ملف Service Account

1. افتح Firebase Console.
2. ادخل إلى Project settings.
3. افتح Service accounts.
4. اضغط Generate new private key.
5. احفظ الملف داخل هذا المسار باسم:

```text
firebase/functions/serviceAccount.toury.json
```

الملف محمي في `.gitignore` ولن يتم رفعه مع الكود.

بعد حفظ الملف شغل:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="D:\Projects\ara\admin\ara_oatan_app\firebase\functions\serviceAccount.toury.json"
node firebase/functions/scripts/seed_toury_content.js --confirm-delete
```

## ماذا سيضيف السكربت؟

- دول مع أعلامها: السعودية، الإمارات، قطر، الكويت، البحرين، عُمان.
- مدن أساسية للسعودية: الرياض، العلا، جدة.
- مناطق/قرى سياحية مرتبطة بالمدن.
- أنواع سيارات جاهزة للحجز مع صور وأسعار.

## ملاحظة مهمة

إذا لم يتم ضبط بيانات اعتماد Google على الجهاز سيظهر خطأ مثل:

```text
Could not load the default credentials
```

وهذا يعني أن الحذف لم يتم، وأن Firebase رفض الوصول قبل لمس البيانات.
