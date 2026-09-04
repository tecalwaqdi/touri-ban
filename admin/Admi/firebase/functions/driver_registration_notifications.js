/**
 * Driver Registration V2 — notifications (secondary to review SoT).
 * Push failure must never fail/rollback review.
 */
'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const SUPPORTED = new Set(['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt']);

function normalizeLocale(raw) {
  const code = String(raw || 'en').split(/[_-]/)[0].toLowerCase();
  return SUPPORTED.has(code) ? code : 'en';
}

/** Central copy — templates with {reason} only; no string concat of RTL/LTR. */
const COPY = {
  admin_new_application: {
    ar: {
      title: 'طلب مندوب جديد بانتظار المراجعة',
      body: 'يوجد طلب تسجيل مندوب جديد بانتظار مراجعتك.',
    },
    en: {
      title: 'New driver application pending review',
      body: 'A new driver registration is waiting for your review.',
    },
    ru: {
      title: 'Новая заявка водителя на проверке',
      body: 'Новая регистрация водителя ожидает проверки.',
    },
    ky: {
      title: 'Жаңы айдоочу арызы күтүүдө',
      body: 'Жаңы айдоочу каттоосу текшерүүнү күтүүдө.',
    },
    fr: {
      title: 'Nouvelle demande chauffeur en attente',
      body: 'Une nouvelle inscription chauffeur attend votre revue.',
    },
    ur: {
      title: 'نیا ڈرائیور درخواست زیر جائزہ',
      body: 'نیا ڈرائیور رجسٹریشن آپ کے جائزے کا منتظر ہے۔',
    },
    pt: {
      title: 'Nova inscrição de motorista pendente',
      body: 'Uma nova inscrição de motorista aguarda a sua revisão.',
    },
  },
  admin_resubmitted: {
    ar: {
      title: 'أعاد المندوب إرسال طلبه للمراجعة',
      body: 'أعاد المندوب تقديم طلب التسجيل بعد التعديلات.',
    },
    en: {
      title: 'Driver resubmitted for review',
      body: 'The driver resubmitted their registration after changes.',
    },
    ru: {
      title: 'Водитель отправил заявку повторно',
      body: 'Водитель повторно отправил регистрацию после правок.',
    },
    ky: {
      title: 'Айдоочу кайра тапшырды',
      body: 'Айдоочу өзгөртүүлөрдөн кийин каттоону кайра жөнөттү.',
    },
    fr: {
      title: 'Chauffeur a resoumis sa demande',
      body: 'Le chauffeur a renvoyé son inscription après modifications.',
    },
    ur: {
      title: 'ڈرائیور نے دوبارہ جمع کرایا',
      body: 'ڈرائیور نے ترمیم کے بعد رجسٹریشن دوبارہ جمع کروائی۔',
    },
    pt: {
      title: 'Motorista reenviou para revisão',
      body: 'O motorista reenviou o registo após alterações.',
    },
  },
  driver_approved: {
    ar: {
      title: 'تم تفعيل حسابك',
      body: 'تمت الموافقة على طلبك ويمكنك الآن استخدام تطبيق المندوب.',
    },
    en: {
      title: 'Your account is activated',
      body: 'Your application was approved. You can now use the driver app.',
    },
    ru: {
      title: 'Аккаунт активирован',
      body: 'Ваша заявка одобрена. Теперь можно пользоваться приложением водителя.',
    },
    ky: {
      title: 'Аккаунтуңуз активдешти',
      body: 'Арызыңыз жактырылды. Эми айдоочу колдонмосун колдоно аласыз.',
    },
    fr: {
      title: 'Compte activé',
      body: 'Votre demande a été approuvée. Vous pouvez utiliser l’app chauffeur.',
    },
    ur: {
      title: 'آپ کا اکاؤنٹ فعال ہو گیا',
      body: 'آپ کی درخواست منظور ہو گئی۔ اب آپ ڈرائیور ایپ استعمال کر سکتے ہیں۔',
    },
    pt: {
      title: 'Conta ativada',
      body: 'A sua inscrição foi aprovada. Já pode usar a app de motorista.',
    },
  },
  driver_rejected: {
    ar: {
      title: 'تم رفض طلبك',
      body: 'سبب الرفض: {reason}',
    },
    en: {
      title: 'Your application was rejected',
      body: 'Rejection reason: {reason}',
    },
    ru: {
      title: 'Заявка отклонена',
      body: 'Причина отказа: {reason}',
    },
    ky: {
      title: 'Арыз четке кагылды',
      body: 'Четке кагуунун себеби: {reason}',
    },
    fr: {
      title: 'Demande refusée',
      body: 'Motif du refus : {reason}',
    },
    ur: {
      title: 'آپ کی درخواست مسترد کر دی گئی',
      body: 'مسترد ہونے کی وجہ: {reason}',
    },
    pt: {
      title: 'Inscrição rejeitada',
      body: 'Motivo da rejeição: {reason}',
    },
  },
  driver_needs_changes: {
    ar: {
      title: 'طلبك يحتاج إلى تعديل',
      body: 'يرجى تعديل البيانات المطلوبة وإعادة التقديم.',
    },
    en: {
      title: 'Your application needs changes',
      body: 'Please update the requested fields and resubmit.',
    },
    ru: {
      title: 'Нужны изменения в заявке',
      body: 'Обновите указанные поля и отправьте снова.',
    },
    ky: {
      title: 'Арызды оңдоо керек',
      body: 'Талап кылынган талааларды жаңыртып, кайра жөнөтүңүз.',
    },
    fr: {
      title: 'Modifications requises',
      body: 'Mettez à jour les champs demandés puis renvoyez.',
    },
    ur: {
      title: 'آپ کی درخواست میں ترمیم درکار ہے',
      body: 'مطلوبہ خانے اپ ڈیٹ کر کے دوبارہ جمع کروائیں۔',
    },
    pt: {
      title: 'Alterações necessárias',
      body: 'Atualize os campos pedidos e reenvie.',
    },
  },
  driver_document_approved: {
    ar: {
      title: 'تم اعتماد وثيقتك',
      body: 'تمت مراجعة الوثيقة واعتمادها.',
    },
    en: {
      title: 'Document approved',
      body: 'Your document was reviewed and approved.',
    },
    ru: {
      title: 'Документ одобрен',
      body: 'Ваш документ проверен и одобрен.',
    },
    ky: {
      title: 'Документ жактырылды',
      body: 'Документиңиз текшерилип, жактырылды.',
    },
    fr: {
      title: 'Document approuvé',
      body: 'Votre document a été examiné et approuvé.',
    },
    ur: {
      title: 'دستاویز منظور ہو گئی',
      body: 'آپ کی دستاویز کا جائزہ لے کر منظور کر دی گئی۔',
    },
    pt: {
      title: 'Documento aprovado',
      body: 'O seu documento foi revisto e aprovado.',
    },
  },
  driver_document_needs_changes: {
    ar: {
      title: 'وثيقتك تحتاج إلى تعديل',
      body: 'حدّث الوثيقة: {reason}',
    },
    en: {
      title: 'Document needs changes',
      body: 'Update document: {reason}',
    },
    ru: {
      title: 'Документ требует изменений',
      body: 'Обновите документ: {reason}',
    },
    ky: {
      title: 'Документ өзгөртүүнү талап кылат',
      body: 'Документти жаңыртыңыз: {reason}',
    },
    fr: {
      title: 'Document à modifier',
      body: 'Mettez à jour le document : {reason}',
    },
    ur: {
      title: 'دستاویز میں ترمیم درکار ہے',
      body: 'دستاویز اپ ڈیٹ کریں: {reason}',
    },
    pt: {
      title: 'Documento precisa de alterações',
      body: 'Atualize o documento: {reason}',
    },
  },
  driver_document_expired: {
    ar: {
      title: 'انتهت صلاحية إحدى وثائقك',
      body: 'حدّث الوثيقة المطلوبة لاستعادة إمكانية استقبال الرحلات.',
    },
    en: {
      title: 'A document has expired',
      body: 'Update the required document to receive trips again.',
    },
    ru: {
      title: 'Срок действия документа истёк',
      body: 'Обновите документ, чтобы снова получать поездки.',
    },
    ky: {
      title: 'Документтин мөөнөтү бүттү',
      body: 'Сапарларды кабыл алуу үчүн талап кылынган документти жаңыртыңыз.',
    },
    fr: {
      title: 'Un document a expiré',
      body: 'Mettez à jour le document requis pour recevoir à nouveau des courses.',
    },
    ur: {
      title: 'ایک دستاویز کی میعاد ختم ہو گئی',
      body: 'سفر وصول کرنے کے لیے مطلوبہ دستاویز اپ ڈیٹ کریں۔',
    },
    pt: {
      title: 'Um documento expirou',
      body: 'Atualize o documento exigido para voltar a receber viagens.',
    },
  },
  driver_document_expiring: {
    ar: {
      title: 'وثيقة ستنتهي قريبًا',
      body: 'حدّث الوثيقة قبل انتهاء صلاحيتها لتجنب توقف استقبال الرحلات.',
    },
    en: {
      title: 'Document expiring soon',
      body: 'Update the document before it expires to keep receiving trips.',
    },
    ru: {
      title: 'Срок действия документа скоро истечёт',
      body: 'Обновите документ до истечения срока, чтобы продолжать получать поездки.',
    },
    ky: {
      title: 'Документ жакында бүтөт',
      body: 'Сапарларды кабыл алууну улантуу үчүн мөөнөт бүткөнчө документти жаңыртыңыз.',
    },
    fr: {
      title: 'Document bientôt expiré',
      body: 'Mettez à jour le document avant expiration pour continuer à recevoir des courses.',
    },
    ur: {
      title: 'دستاویز جلد ختم ہو رہی ہے',
      body: 'سفر وصول کرتے رہنے کے لیے میعاد ختم ہونے سے پہلے دستاویز اپ ڈیٹ کریں۔',
    },
    pt: {
      title: 'Documento a expirar em breve',
      body: 'Atualize o documento antes de expirar para continuar a receber viagens.',
    },
  },
};

function localize(key, locale, args = {}) {
  const loc = normalizeLocale(locale);
  const pack = COPY[key] || {};
  const entry = pack[loc] || pack.en || {title: key, body: ''};
  let body = entry.body || '';
  for (const [k, v] of Object.entries(args)) {
    body = body.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v ?? ''));
  }
  return {title: entry.title || key, body};
}

function shortReason(reason, max = 80) {
  const t = String(reason || '').trim().replace(/\s+/g, ' ');
  if (!t) return '—';
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

function isAdminUser(u) {
  return (
    u.isAdmin === true ||
    u.IsAdmin === true ||
    u.isAdminRule === 1 ||
    u.IsAdminRule === 1 ||
    u.super_admin === true
  );
}

function isCountryAdminUser(u) {
  return u.isagent === true || u.Isagent === true || u.country_admin === true;
}

function collectAdminTokens(doc, tokenSet) {
  const user = doc.data() || {};
  if (user.fcm_token) tokenSet.add(String(user.fcm_token));
  (user.fcm_tokens || []).forEach((t) => {
    if (t) tokenSet.add(String(t));
  });
}

async function cleanupInvalidAdminTokens(adminDocs, invalidTokens) {
  if (!invalidTokens.length) return;
  const batch = db.batch();
  let writes = 0;
  for (const doc of adminDocs) {
    const data = doc.data() || {};
    const current = new Set(
      [data.fcm_token, ...(data.fcm_tokens || [])].filter(Boolean).map(String),
    );
    let changed = false;
    for (const bad of invalidTokens) {
      if (current.delete(bad)) changed = true;
    }
    if (!changed) continue;
    const remaining = Array.from(current);
    const update = {fcm_tokens: remaining};
    if (remaining.length > 0) {
      update.fcm_token = remaining[remaining.length - 1];
    } else {
      update.fcm_token = admin.firestore.FieldValue.delete();
    }
    batch.update(doc.ref, update);
    writes++;
  }
  if (writes > 0) await batch.commit();
}

async function loadDriverTokens(driverId) {
  const tokens = new Set();
  const snap = await db.collection(`user/${driverId}/fcm_tokens`).limit(20).get();
  snap.forEach((d) => {
    const t = d.data().fcm_token || d.data().token;
    if (t) tokens.add(String(t));
  });
  const userSnap = await db.doc(`user/${driverId}`).get();
  if (userSnap.exists) {
    const u = userSnap.data() || {};
    if (u.fcm_token) tokens.add(String(u.fcm_token));
    (u.fcm_tokens || []).forEach((t) => {
      if (t) tokens.add(String(t));
    });
  }
  return {tokens: Array.from(tokens), userSnap};
}

async function cleanupInvalidDriverTokens(driverId, invalidTokens) {
  if (!invalidTokens.length) return;
  const snap = await db.collection(`user/${driverId}/fcm_tokens`).get();
  const batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    const t = String(doc.data().fcm_token || doc.data().token || '');
    if (invalidTokens.includes(t)) {
      batch.delete(doc.ref);
      n++;
    }
  }
  if (n > 0) await batch.commit();
}

async function findAdminDocs(countryRef) {
  const adminDocs = [];
  const seen = new Set();
  const superSnap = await db
    .collection('user')
    .where('fcm_token', '>', '')
    .limit(200)
    .get();
  for (const doc of superSnap.docs) {
    const u = doc.data() || {};
    if (!isAdminUser(u) && !isCountryAdminUser(u)) continue;
    if (isCountryAdminUser(u) && !isAdminUser(u)) {
      const agentCountry = u.Rev_dloh_agent;
      if (
        countryRef &&
        agentCountry &&
        agentCountry.path &&
        countryRef.path &&
        agentCountry.path !== countryRef.path
      ) {
        continue;
      }
      if (!countryRef) continue;
    }
    if (seen.has(doc.id)) continue;
    seen.add(doc.id);
    adminDocs.push(doc);
  }
  if (countryRef) {
    const agentsSnap = await db
      .collection('user')
      .where('Rev_dloh_agent', '==', countryRef)
      .where('fcm_token', '>', '')
      .limit(100)
      .get();
    for (const doc of agentsSnap.docs) {
      if (seen.has(doc.id)) continue;
      seen.add(doc.id);
      adminDocs.push(doc);
    }
  }
  return adminDocs;
}

async function writePersistentAdminNotification(eventId, payload) {
  const ref = db.doc(`admin_panel_notifications/${eventId}`);
  const existing = await ref.get();
  if (existing.exists) {
    return {ref, created: false, data: existing.data()};
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  const doc = {
    ...payload,
    unread: true,
    read: false,
    createdAt: now,
    deliveryStatus: 'queued',
  };
  await ref.set(doc);
  return {ref, created: true, data: doc};
}

async function sendMulticast({tokens, title, body, data, channelId}) {
  if (!tokens.length) {
    return {successCount: 0, failureCount: 0, invalidTokens: []};
  }
  const message = {
    notification: {title, body},
    data: Object.fromEntries(
      Object.entries(data || {}).map(([k, v]) => [k, String(v ?? '')]),
    ),
    android: {
      priority: 'high',
      notification: {
        channelId: channelId || 'admin_bookings',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {payload: {aps: {sound: 'default', badge: 1}}},
    tokens,
  };
  const response = await admin.messaging().sendEachForMulticast(message);
  const invalidTokens = [];
  response.responses.forEach((res, i) => {
    if (res.success) return;
    const code = res.error && res.error.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidTokens.push(tokens[i]);
    }
  });
  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
  };
}

async function auditNotification(action, metadata) {
  try {
    await db.collection('admin_audit_log').add({
      action,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: metadata || {},
    });
  } catch (_) {
    /* never block */
  }
}

/**
 * After successful submit/resubmit → notify admins.
 */
async function notifyAdminsDriverApplication({
  driverId,
  countryRef,
  reviewVersion,
  reviewAttemptCount,
  isResubmit,
  registrationStatus,
}) {
  const eventId = isResubmit
    ? `drv_resub_${driverId}_v${reviewVersion}`
    : `drv_sub_${driverId}_v${reviewVersion}`;
  const type = isResubmit
    ? 'driver_application_resubmitted'
    : 'driver_application_submitted';
  const copyKey = isResubmit ? 'admin_resubmitted' : 'admin_new_application';

  let persist;
  try {
    persist = await writePersistentAdminNotification(eventId, {
      type,
      driverId,
      driverRef: db.doc(`user/${driverId}`),
      countryRef: countryRef || null,
      countryPath: countryRef && countryRef.path ? countryRef.path : null,
      registrationStatus: registrationStatus || 'pending_review',
      reviewVersion: Number(reviewVersion || 0),
      reviewAttemptCount: Number(reviewAttemptCount || 0),
      targetRoute: 'DriverActivation',
      targetType: 'driver_review',
    });
  } catch (e) {
    await auditNotification('NOTIFICATION_FAILED', {
      eventId,
      stage: 'persist',
      error: String(e && e.message),
    });
    return {ok: false, stage: 'persist'};
  }

  if (!persist.created) {
    await auditNotification('NOTIFICATION_QUEUED', {
      eventId,
      idempotent: true,
      type,
    });
    return {ok: true, idempotent: true};
  }

  await auditNotification('NOTIFICATION_QUEUED', {eventId, type});

  try {
    const adminDocs = await findAdminDocs(countryRef);
    const byLocale = new Map();
    for (const doc of adminDocs) {
      const u = doc.data() || {};
      const locale = normalizeLocale(u.preferred_locale);
      if (!byLocale.has(locale)) {
        byLocale.set(locale, {tokens: new Set(), docs: []});
      }
      const bucket = byLocale.get(locale);
      bucket.docs.push(doc);
      collectAdminTokens(doc, bucket.tokens);
    }

    let sent = 0;
    let failed = 0;
    for (const [locale, bucket] of byLocale.entries()) {
      const tokens = Array.from(bucket.tokens);
      if (!tokens.length) continue;
      const copy = localize(copyKey, locale);
      const result = await sendMulticast({
        tokens,
        title: copy.title,
        body: copy.body,
        channelId: 'admin_driver_reviews',
        data: {
          type,
          driverId,
          registrationStatus: registrationStatus || 'pending_review',
          target: 'driver_review',
          initialPageName: 'DriverActivation',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
      sent += result.successCount;
      failed += result.failureCount;
      if (result.invalidTokens.length) {
        await cleanupInvalidAdminTokens(bucket.docs, result.invalidTokens);
      }
    }

    await persist.ref.set(
      {
        deliveryStatus: sent > 0 ? 'sent' : failed > 0 ? 'failed' : 'queued',
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
        pushSuccessCount: sent,
        pushFailureCount: failed,
      },
      {merge: true},
    );
    await auditNotification(sent > 0 ? 'NOTIFICATION_SENT' : 'NOTIFICATION_FAILED', {
      eventId,
      type,
      sent,
      failed,
    });
    return {ok: true, sent, failed};
  } catch (e) {
    await persist.ref.set(
      {
        deliveryStatus: 'failed',
        pushError: String(e && e.message).slice(0, 300),
      },
      {merge: true},
    );
    await auditNotification('NOTIFICATION_FAILED', {
      eventId,
      error: String(e && e.message),
    });
    return {ok: false, stage: 'push'};
  }
}

/**
 * After successful review → notify driver.
 */
async function notifyDriverReviewResult({
  driverId,
  action,
  reviewVersion,
  registrationStatus,
  reason,
}) {
  const eventId = `drv_rev_${driverId}_v${reviewVersion}_${action}`;
  const notifRef = db.doc(`driver_registration_notifications/${eventId}`);
  const existing = await notifRef.get();
  if (existing.exists) {
    await auditNotification('NOTIFICATION_QUEUED', {
      eventId,
      idempotent: true,
      action,
    });
    return {ok: true, idempotent: true};
  }

  let copyKey = 'driver_approved';
  let type = 'driver_application_approved';
  let target = 'driver_home';
  let initialPageName = 'home';
  if (action === 'reject') {
    copyKey = 'driver_rejected';
    type = 'driver_application_rejected';
    target = 'driver_application_status';
    initialPageName = 'DriverPendingApproval';
  } else if (action === 'request_changes') {
    copyKey = 'driver_needs_changes';
    type = 'driver_application_needs_changes';
    target = 'driver_application_status';
    initialPageName = 'DriverPendingApproval';
  }

  await notifRef.set({
    driverId,
    action,
    type,
    registrationStatus,
    reviewVersion: Number(reviewVersion || 0),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    deliveryStatus: 'queued',
  });
  await auditNotification('NOTIFICATION_QUEUED', {eventId, type, driverId});

  try {
    const {tokens, userSnap} = await loadDriverTokens(driverId);
    const preferred =
      (userSnap.exists && userSnap.data().preferred_locale) || 'en';
    const locale = normalizeLocale(preferred);
    const copy = localize(copyKey, locale, {
      reason: shortReason(reason),
    });

    if (!tokens.length) {
      await notifRef.set(
        {deliveryStatus: 'failed', pushError: 'NO_TOKENS'},
        {merge: true},
      );
      await auditNotification('NOTIFICATION_FAILED', {
        eventId,
        error: 'NO_TOKENS',
      });
      return {ok: false, stage: 'no_tokens'};
    }

    const result = await sendMulticast({
      tokens,
      title: copy.title,
      body: copy.body,
      channelId: 'driver_registration',
      data: {
        type,
        driverId,
        registrationStatus: registrationStatus || '',
        target,
        initialPageName,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
    if (result.invalidTokens.length) {
      await cleanupInvalidDriverTokens(driverId, result.invalidTokens);
    }
    await notifRef.set(
      {
        deliveryStatus: result.successCount > 0 ? 'sent' : 'failed',
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
        pushSuccessCount: result.successCount,
        pushFailureCount: result.failureCount,
      },
      {merge: true},
    );
    await auditNotification(
      result.successCount > 0 ? 'NOTIFICATION_SENT' : 'NOTIFICATION_FAILED',
      {
        eventId,
        type,
        sent: result.successCount,
        failed: result.failureCount,
      },
    );
    return {ok: true, sent: result.successCount};
  } catch (e) {
    await notifRef.set(
      {
        deliveryStatus: 'failed',
        pushError: String(e && e.message).slice(0, 300),
      },
      {merge: true},
    );
    await auditNotification('NOTIFICATION_FAILED', {
      eventId,
      error: String(e && e.message),
    });
    return {ok: false, stage: 'push'};
  }
}

/** Unified operational approval gate for trip acceptance / availability. */
function driverIsOperationallyApproved(driver) {
  if (!driver || typeof driver !== 'object') return false;
  const suspended =
    driver.suspended === true ||
    driver.is_suspended === true ||
    driver.blocked === true ||
    ['suspended', 'blocked'].includes(
      String(driver.registration_status || '').toLowerCase(),
    );
  if (suspended) return false;

  const flow = Number(driver.registration_flow_version || 0);
  if (flow === 2) {
    return (
      String(driver.registration_status || '') === 'approved' &&
      (driver.actev_mndob === true || driver.actevMndob === true)
    );
  }
  // Legacy: preserve existing accept gate (actev or ismndob).
  return (
    driver.actev_mndob === true ||
    driver.actevMndob === true ||
    driver.ismndob === true
  );
}

exports.notifyAdminsDriverApplication = notifyAdminsDriverApplication;
exports.notifyDriverReviewResult = notifyDriverReviewResult;
exports.driverIsOperationallyApproved = driverIsOperationallyApproved;
exports.localize = localize;
exports.normalizeLocale = normalizeLocale;
exports.shortReason = shortReason;
