'use strict';

/**
 * Resend email adapter — single entry point for transactional email.
 * Never logs OTP or API keys.
 */

const RESEND_API_URL = 'https://api.resend.com/emails';

const TEMPLATES = {
  en: {
    subject: 'Your email verification code — Touri Taxi',
    heading: 'Verify your email',
    body: 'Use this code to verify your Touri Taxi driver account:',
    expiry: 'This code expires in 10 minutes.',
    security: 'If you did not request this code, you can ignore this email.',
  },
  ar: {
    subject: 'رمز التحقق من بريدك — Touri Taxi',
    heading: 'تحقق من بريدك الإلكتروني',
    body: 'استخدم هذا الرمز للتحقق من حسابك كسائق في Touri Taxi:',
    expiry: 'تنتهي صلاحية الرمز خلال 10 دقائق.',
    security: 'إذا لم تطلب هذا الرمز، تجاهل هذه الرسالة.',
  },
  ru: {
    subject: 'Код подтверждения email — Touri Taxi',
    heading: 'Подтвердите email',
    body: 'Используйте этот код для подтверждения аккаунта водителя Touri Taxi:',
    expiry: 'Код действителен 10 минут.',
    security: 'Если вы не запрашивали код, проигнорируйте это письмо.',
  },
  ky: {
    subject: 'Email ырастоо коду — Touri Taxi',
    heading: 'Email ырастаңыз',
    body: 'Touri Taxi айдоочу аккаунтуңузду ырастоо үчүн бул кодду колдонуңуз:',
    expiry: 'Код 10 мүнөт ичинде жарамсыз болот.',
    security: 'Эгер сиз бул кодду сураган эмес болсоңуз, бул катты эск албаңыз.',
  },
  fr: {
    subject: 'Votre code de vérification — Touri Taxi',
    heading: 'Vérifiez votre e-mail',
    body: 'Utilisez ce code pour vérifier votre compte chauffeur Touri Taxi :',
    expiry: 'Ce code expire dans 10 minutes.',
    security: 'Si vous n\'avez pas demandé ce code, ignorez cet e-mail.',
  },
  ur: {
    subject: 'آپ کا تصدیقی کوڈ — Touri Taxi',
    heading: 'اپنا ای میل تصدیق کریں',
    body: 'Touri Taxi ڈرائیور اکاؤنٹ کی تصدیق کے لیے یہ کوڈ استعمال کریں:',
    expiry: 'یہ کوڈ 10 منٹ میں ختم ہو جائے گا۔',
    security: 'اگر آپ نے یہ کوڈ نہیں مانگا تو اس ای میل کو نظرانداز کریں۔',
  },
  pt: {
    subject: 'Seu código de verificação — Touri Taxi',
    heading: 'Verifique seu e-mail',
    body: 'Use este código para verificar sua conta de motorista Touri Taxi:',
    expiry: 'Este código expira em 10 minutos.',
    security: 'Se você não solicitou este código, ignore este e-mail.',
  },
};

function resolveLocale(locale) {
  const code = String(locale || 'en').slice(0, 2).toLowerCase();
  return TEMPLATES[code] ? code : 'en';
}

function getResendApiKey() {
  return String(process.env.RESEND_API_KEY || '').trim();
}

function getFromAddress() {
  const email =
    String(process.env.RESEND_FROM_EMAIL || 'no-reply@touri-taxi.com').trim();
  const name = String(process.env.RESEND_FROM_NAME || 'Touri Taxi').trim();
  return {email, name};
}

function buildHtml(tpl, otp) {
  return `<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px">
  <p style="font-size:18px;font-weight:700;margin:0 0 12px">${tpl.heading}</p>
  <p style="color:#444;margin:0 0 16px">${tpl.body}</p>
  <p style="font-size:32px;letter-spacing:8px;font-weight:700;margin:16px 0">${otp}</p>
  <p style="color:#666;font-size:14px;margin:0 0 8px">${tpl.expiry}</p>
  <p style="color:#888;font-size:13px;margin:0">${tpl.security}</p>
</div>`;
}

function buildText(tpl, otp) {
  return `${tpl.heading}\n\n${tpl.body}\n\n${otp}\n\n${tpl.expiry}\n\n${tpl.security}`;
}

/**
 * @param {{toEmail:string, otp:string, locale?:string}} params
 * @returns {Promise<{ok:true, id?:string}>}
 */
async function sendVerificationOtpEmail({toEmail, otp, locale}) {
  const apiKey = getResendApiKey();
  if (!apiKey) {
    const err = new Error('RESEND_PROVIDER_ERROR');
    err.code = 'RESEND_PROVIDER_ERROR';
    throw err;
  }
  const from = getFromAddress();
  const loc = resolveLocale(locale);
  const tpl = TEMPLATES[loc];

  const res = await fetch(RESEND_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: `${from.name} <${from.email}>`,
      to: [toEmail],
      subject: tpl.subject,
      html: buildHtml(tpl, otp),
      text: buildText(tpl, otp),
      tags: [{name: 'purpose', value: 'email_verification_otp'}],
    }),
  });

  const rawText = await res.text().catch(() => '');
  let parsed = {};
  try {
    parsed = rawText ? JSON.parse(rawText) : {};
  } catch (_) {
    parsed = {};
  }

  if (!res.ok) {
    console.error('resend_otp_send_failed', res.status, rawText.slice(0, 200));
    const err = new Error('RESEND_PROVIDER_ERROR');
    err.code = 'RESEND_PROVIDER_ERROR';
    throw err;
  }

  console.info(
    'resend_otp_send_ok',
    JSON.stringify({
      httpStatus: res.status,
      id: parsed.id ? String(parsed.id).slice(0, 80) : null,
      toMasked: maskEmail(toEmail),
    }),
  );

  return {ok: true, id: parsed.id ? String(parsed.id) : undefined};
}

function maskEmail(email) {
  const e = String(email || '')
    .trim()
    .toLowerCase();
  const at = e.indexOf('@');
  if (at < 1) return '***';
  const local = e.slice(0, at);
  const domain = e.slice(at + 1);
  const shown = local.slice(0, Math.min(2, local.length));
  return `${shown}***@${domain}`;
}

module.exports = {
  sendVerificationOtpEmail,
  resolveLocale,
  maskEmail,
  TEMPLATES,
};
