const LOCALES = ["ar", "en", "ru", "ky", "fr", "ur", "pt"];

const COPY = {
  "notification_default_title": {
    "ar": "إشعار جديد",
    "en": "New notification",
    "ru": "Новое уведомление",
    "ky": "Жаңы билдирме",
    "fr": "Nouvelle notification",
    "ur": "نیا اطلاع",
    "pt": "Nova notificação"
  },
  "notification_driver_arrived_body": {
    "ar": "وصل السائق {driver} إلى نقطة الانطلاق.",
    "en": "Driver {driver} has arrived at the pickup location.",
    "ru": "Водитель {driver} прибыл к месту подачи.",
    "ky": "Айдоочу {driver} алуу жерине келди.",
    "fr": "Le chauffeur {driver} est arrivé au point de prise en charge.",
    "ur": "ڈرائیور {driver} پک اپ مقام پر پہنچ گیا ہے۔",
    "pt": "O motorista {driver} chegou ao local de embarque."
  },
  "notification_driver_arrived_title": {
    "ar": "وصل السائق",
    "en": "Driver arrived",
    "ru": "Водитель прибыл",
    "ky": "Айдоочу келди",
    "fr": "Chauffeur arrivé",
    "ur": "ڈرائیور پہنچ گیا",
    "pt": "Motorista chegou"
  },
  "notification_new_order_driver_body": {
    "ar": "حجز تاكسي Touri جديد متاح لمدة {hours} ساعة مع أرباح {amount} {currency}. افتح تطبيق برنامج التشغيل لمراجعته.",
    "en": "A new Touri Taxi booking is available for {hours} hours with earnings of {amount} {currency}. Open the driver app to review it.",
    "ru": "Новое бронирование Touri Taxi доступно на {hours} часов с доходом {amount} {currency}. Откройте приложение для водителя, чтобы просмотреть его.",
    "ky": "Жаңы Touri Taxi ээлөө {amount} {currency} кирешеси менен {hours} саатка жеткиликтүү. Аны карап чыгуу үчүн айдоочу колдонмосун ачыңыз.",
    "fr": "Une nouvelle réservation Touri Taxi est disponible pour {hours} heures avec des gains de {amount} {currency}. Ouvrez l'application du pilote pour l'examiner.",
    "ur": "{amount} {currency} کی آمدنی کے ساتھ ایک نئی ٹوری ٹیکسی بکنگ {hours} گھنٹے کے لئے دستیاب ہے۔ اس کا جائزہ لینے کے لیے ڈرائیور ایپ کھولیں۔",
    "pt": "Uma nova reserva Touri Taxi está disponível por {hours} horas com ganhos de {amount} {currency}. Abra o app do motorista para revisar."
  },
  "notification_new_order_driver_title": {
    "ar": "حجز جديد",
    "en": "New booking",
    "ru": "Новое бронирование",
    "ky": "Жаңы ээлөө",
    "fr": "Nouvelle réservation",
    "ur": "نئی بکنگ",
    "pt": "Nova reserva"
  },
  "notification_order_accepted_body": {
    "ar": "تم قبول طلب تاكسي توري بواسطة: {driver}",
    "en": "Your Touri Taxi request was accepted by: {driver}",
    "ru": "Ваш заказ Touri Taxi принял: {driver}",
    "ky": "Сиздин Touri Taxi буйрутмаңызды кабыл алды: {driver}",
    "fr": "Votre demande Touri Taxi a été acceptée par : {driver}",
    "ur": "آپ کی ٹوری ٹیکسی درخواست قبول کر لی گئی: {driver}",
    "pt": "Seu pedido Touri Taxi foi aceito por: {driver}"
  },
  "notification_order_accepted_title": {
    "ar": "تم قبول الطلب",
    "en": "Order accepted",
    "ru": "Заказ принят",
    "ky": "Буйрутма кабыл алынды",
    "fr": "Course acceptée",
    "ur": "آرڈر قبول ہو گیا",
    "pt": "Pedido aceito"
  },
  "notification_order_cancelled_by_driver_body": {
    "ar": "ألغى السائق طلب تاكسي توري الخاص بك.",
    "en": "Your Touri Taxi request was cancelled by the driver.",
    "ru": "Водитель отменил ваш заказ Touri Taxi.",
    "ky": "Айдоочу сиздин Touri Taxi буйрутмаңызды жокко чыгарды.",
    "fr": "Le chauffeur a annulé votre demande Touri Taxi.",
    "ur": "ڈرائیور نے آپ کی ٹوری ٹیکسی درخواست منسوخ کر دی۔",
    "pt": "O motorista cancelou seu pedido Touri Taxi."
  },
  "notification_order_cancelled_by_driver_title": {
    "ar": "تم إلغاء الطلب",
    "en": "Order cancelled",
    "ru": "Заказ отменён",
    "ky": "Буйрутма жокко чыгарылды",
    "fr": "Course annulée",
    "ur": "آرڈر منسوخ",
    "pt": "Pedido cancelado"
  },
  "notification_paid_order_admin_body": {
    "ar": "الحجز المدفوع الجديد #{bookingId}: {hours} ساعات، {amount} {currency}.",
    "en": "New paid booking #{bookingId}: {hours} hours, {amount} {currency}.",
    "ru": "Новое платное бронирование №{bookingId}: {hours} часов, {amount} {currency}.",
    "ky": "Жаңы акы төлөнүүчү брондоо #{bookingId}: {hours} саат, {amount} {currency}.",
    "fr": "Nouvelle réservation payante n°{bookingId} : {hours} heures, {amount} {currency}.",
    "ur": "نئی بامعاوضہ بکنگ #{bookingId}: {hours} گھنٹے، {amount} {currency}۔",
    "pt": "Nova reserva paga #{bookingId}: {hours} horas, {amount} {currency}."
  },
  "notification_paid_order_admin_title": {
    "ar": "حجز مدفوع جديد",
    "en": "New paid booking",
    "ru": "Новое платное бронирование",
    "ky": "Жаңы төлөнүүчү ээлөө",
    "fr": "Nouvelle réservation payante",
    "ur": "نئی بامعاوضہ بکنگ",
    "pt": "Nova reserva paga"
  },
  "notification_payment_success_body": {
    "ar": "تم تأكيد الدفع للحجز #{bookingId}. نحن نبحث عن سائق لك.",
    "en": "Payment for booking #{bookingId} was confirmed. We are finding a driver for you.",
    "ru": "Оплата бронирования №{bookingId} подтверждена. Мы находим для вас водителя.",
    "ky": "#{bookingId} ээлөө үчүн төлөм ырасталды. Биз сиз үчүн айдоочу издеп жатабыз.",
    "fr": "Le paiement de la réservation n°{bookingId} a été confirmé. Nous recherchons un chauffeur pour vous.",
    "ur": "بکنگ #{bookingId} کے لیے ادائیگی کی تصدیق ہوگئی۔ ہم آپ کے لیے ڈرائیور تلاش کر رہے ہیں۔",
    "pt": "Pagamento for booking #{bookingId} was confirmed. We are finding a driver for you."
  },
  "notification_payment_success_title": {
    "ar": "تم الدفع بنجاح",
    "en": "Payment successful",
    "ru": "Платеж успешен",
    "ky": "Төлөм ийгиликтүү болду",
    "fr": "Paiement réussi",
    "ur": "ادائیگی کامیاب",
    "pt": "Pagamento successful"
  },
  "notification_private_message_body": {
    "ar": "لديك رسالة جديدة من {sender}.",
    "en": "You have a new message from {sender}.",
    "ru": "У вас новое сообщение от {sender}.",
    "ky": "Сизде {sender} жаңы билдирүү бар.",
    "fr": "Vous avez un nouveau message de {sender}.",
    "ur": "آپ کے پاس {sender} کی طرف سے ایک نیا پیغام ہے۔",
    "pt": "Você tem uma nova mensagem de {sender}."
  },
  "notification_private_message_title": {
    "ar": "رسالة خاصة جديدة",
    "en": "New private message",
    "ru": "Новое личное сообщение",
    "ky": "Жаңы купуя билдирүү",
    "fr": "Nouveau message privé",
    "ur": "نیا نجی پیغام",
    "pt": "Nova mensagem privada"
  },
  "notification_trip_started_body": {
    "ar": "بدأت رحلتك مع {driver}. تابع السائق من التطبيق.",
    "en": "Your trip with {driver} has started. Track your driver in the app.",
    "ru": "Ваша поездка с {driver} началась. Отслеживайте водителя в приложении.",
    "ky": "{driver} менен сапарыңыз башталды. Колдонмодо айдоочуну көзөмөлдөңүз.",
    "fr": "Votre trajet avec {driver} a commencé. Suivez le chauffeur dans l'application.",
    "ur": "{driver} کے ساتھ آپ کا سفر شروع ہو گیا ہے۔ ایپ میں ڈرائیور کو ٹریک کریں۔",
    "pt": "Sua viagem com {driver} começou. Acompanhe o motorista no app."
  },
  "notification_trip_started_title": {
    "ar": "بدأت الرحلة",
    "en": "Trip started",
    "ru": "Поездка началась",
    "ky": "Сапар башталды",
    "fr": "Trajet démarré",
    "ur": "سفر شروع ہو گیا",
    "pt": "Viagem iniciada"
  },
  "notification_wallet_topup_body": {
    "ar": "{amount} تمت إضافة الريال السعودي إلى محفظتك بنجاح.",
    "en": "{amount} SAR was added to your wallet successfully.",
    "ru": "{amount} SAR был успешно добавлен в ваш кошелек.",
    "ky": "{amount} SAR сиздин капчыгыңызга ийгиликтүү кошулду.",
    "fr": "{amount} SAR a été ajouté à votre portefeuille avec succès.",
    "ur": "{amount} SAR کامیابی کے ساتھ آپ کے بٹوے میں شامل کر دیا گیا تھا۔",
    "pt": "{amount} SAR foram adicionados à sua carteira com sucesso."
  },
  "notification_wallet_topup_title": {
    "ar": "المحفظة تعلوها",
    "en": "Wallet topped up",
    "ru": "Кошелек пополнен",
    "ky": "Капчык толукталды",
    "fr": "Portefeuille rechargé",
    "ur": "پرس اوپر ہو گیا۔",
    "pt": "Carteira topped up"
  }
};

function normalizeLocale(raw) {
  const code = String(raw || "en").replace("_", "-").split("-")[0].toLowerCase();
  return LOCALES.includes(code) ? code : "en";
}

function resolvePushCopy(type, locale) {
  const key = String(type || "");
  const table = COPY[key];
  if (!table) return null;
  const lang = normalizeLocale(locale);
  return {
    locale: lang,
    title: table[lang],
    body: COPY[key.replace(/_title$/, "_body")]
      ? undefined
      : table[lang],
    text: table[lang],
  };
}

function interpolate(template, payload) {
  const data = payload && typeof payload === "object" ? payload : {};
  return String(template || "").replace(/\{(\w+)\}/g, (_, key) => {
    const value = data[key];
    return value == null ? "" : String(value);
  });
}

function resolvePair(type, locale, payload) {
  const lang = normalizeLocale(locale);
  const titleKey = String(type || "");
  const bodyKey = titleKey.endsWith("_title")
    ? titleKey.replace(/_title$/, "_body")
    : `${titleKey}_body`;
  const title = COPY[titleKey] && COPY[titleKey][lang];
  const body = COPY[bodyKey] && COPY[bodyKey][lang];
  if (!title || !body) return null;
  const message =
    payload && payload.message != null ? String(payload.message).trim() : "";
  const resolvedBody =
    titleKey.includes("private_message") && message
      ? message.slice(0, 500)
      : interpolate(body, payload);
  return {
    locale: lang,
    title: interpolate(title, payload),
    body: resolvedBody,
  };
}

module.exports = {
  LOCALES,
  COPY,
  normalizeLocale,
  resolvePushCopy,
  resolvePair,
  interpolate,
};
