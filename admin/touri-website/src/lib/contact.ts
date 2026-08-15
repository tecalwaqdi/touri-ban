import { siteConfig } from "@/config/site";

/** Digits only (country code included), for WhatsApp / tel links. */
export function phoneDigits(phone: string) {
  return phone.replace(/\D/g, "");
}

export function telHref(phone: string) {
  const digits = phoneDigits(phone);
  return digits ? `tel:+${digits}` : "";
}

/** Always builds a clean https://wa.me/<digits> URL from phone or existing wa URL. */
export function whatsappHref(phoneOrUrl: string) {
  const fromUrl = phoneOrUrl.match(/(?:wa\.me\/|phone=)(\d{10,15})/i)?.[1];
  const digits = fromUrl || phoneDigits(phoneOrUrl);
  return digits ? `https://wa.me/${digits}` : "";
}

/** Display phone in a stable LTR order (avoids RTL mirroring of +966…). */
export function phoneDisplay(phone: string) {
  const trimmed = phone.trim();
  if (!trimmed) return "";
  const digits = phoneDigits(trimmed);
  if (digits.startsWith("966") && digits.length >= 12) {
    const local = digits.slice(3);
    const a = local.slice(0, 2);
    const b = local.slice(2, 5);
    const c = local.slice(5);
    return `+966 ${a} ${b} ${c}`.trim();
  }
  if (trimmed.startsWith("+")) return trimmed;
  return digits ? `+${digits}` : trimmed;
}

export function contactChannels() {
  const phone = siteConfig.contact.phone.trim();
  const email = siteConfig.contact.email.trim();
  const whatsappSource =
    siteConfig.contact.whatsapp.trim() || phone;

  return {
    phone: phone
      ? {
          display: phoneDisplay(phone),
          tel: telHref(phone),
          digits: phoneDigits(phone),
        }
      : null,
    whatsapp: whatsappSource
      ? {
          display: phoneDisplay(phone || whatsappSource),
          href: whatsappHref(whatsappSource),
        }
      : null,
    email: email
      ? {
          display: email,
          href: `mailto:${email}`,
        }
      : null,
  };
}
