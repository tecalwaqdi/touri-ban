# Touri Taxi Translation Glossary

Canonical terms for UI consistency across ar / en / ru / ky.

| Key | Arabic | English | Russian | Kyrgyz |
|-----|--------|---------|---------|--------|
| home_nav | الرئيسية | Home | Главная | Башкы бет |
| my_bookings_nav | حجوزاتي | My Bookings | Мои бронирования | Менин брондорум |
| my_account_nav | حسابي | My Account | Мой аккаунт | Менин аккаунтум |
| current_location_label | الموقع الحالي | Current location | Текущее местоположение | Учурдагы жайгашуу |
| pickup_location_label | نقطة الانطلاق | Pickup location | Место отправления | Баштапкы пункт |
| destination_label | الوجهة | Destination | Пункт назначения | Бара турган жер |
| stops_label | المحطات | Stops | Остановки | Токтоочу жайлар |
| view_route_label | عرض المسار | View route | Посмотреть маршрут | Багытты көрүү |
| trip_details_label | تفاصيل الرحلة | Trip details | Детали поездки | Сапардын чоо-жайы |
| choose_payment_method | اختر طريقة الدفع | Choose payment method | Выберите способ оплаты | Төлөм ыкмасын тандаңыз |
| pay_online_option | الدفع الإلكتروني | Pay online | Оплата картой | Электрондук төлөм |
| pay_cash_option | الدفع نقداً | Pay with cash | Оплата наличными | Накталай төлөм |
| driver_fee_label | رسوم السائق | Driver fee | Стоимость услуг водителя | Айдоочунун акысы |
| app_fee_label | رسوم التطبيق | App fee | Комиссия приложения | Колдонмонун комиссиясы |
| vat_label | ضريبة القيمة المضافة | VAT | НДС | Кошумча нарк салыгы |
| total_amount_label | المبلغ الإجمالي | Total amount | Итоговая сумма | Жалпы сумма |
| status_pending_driver | بانتظار قبول السائق | Waiting for driver acceptance | Ожидает подтверждения водителя | Айдоочунун кабыл алуусун күтүүдө |
| status_driver_assigned | تم تعيين السائق | Driver assigned | Водитель назначен | Айдоочу дайындалды |
| status_driver_arrived | وصل السائق | Driver arrived | Водитель прибыл | Айдоочу келди |
| status_trip_started | بدأت الرحلة | Trip started | Поездка началась | Сапар башталды |
| status_trip_completed | اكتملت الرحلة | Trip completed | Поездка завершена | Сапар аяктады |
| status_cancelled | تم الإلغاء | Cancelled | Отменено | Жокко чыгарылды |
| status_payment_pending | قيد الانتظار | Payment pending | Ожидает оплаты | Төлөм күтүлүүдө |
| status_paid | تم الدفع | Paid | Оплачено | Төлөндү |
| status_payment_failed | فشل الدفع | Payment failed | Ошибка оплаты | Төлөм ишке ашкан жок |
| map_selected_location | موقع محدد على الخريطة | Selected location on map | Точка, выбранная на карте | Картадан тандалган жер |
| brand | Touri Taxi | Touri Taxi | Touri Taxi | Touri Taxi |

## Internal codes (never show raw)

| Code | Localizer |
|------|-----------|
| `pending_driver` | BookingStatusLocalizer |
| `driver_assigned` | BookingStatusLocalizer |
| `driver_arrived` | BookingStatusLocalizer |
| `trip_in_progress` | BookingStatusLocalizer |
| `trip_completed` | BookingStatusLocalizer |
| `cancelled` | BookingStatusLocalizer |
| `TOURY_PAY_CASH` | touryPaymentDisplayLabel |
| `TOURY_PAY_NGENIUS` | touryPaymentDisplayLabel |
| `payment_failed` | ErrorLocalizer / PaymentStatusLocalizer |
