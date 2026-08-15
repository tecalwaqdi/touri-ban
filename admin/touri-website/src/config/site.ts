/**
 * Public site configuration.
 * Fill store URLs, email, and social links before launch.
 * Empty strings are treated as unavailable — the UI hides those actions.
 */
export const siteConfig = {
  name: "Touri",
  legalName: "Touri Taxi",
  customerApp: "Touri Taxi",
  driverApp: "Touri Taxi Driver",
  url: process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") || "",
  defaultLocale: "ar" as const,
  locales: ["ar", "en"] as const,
  legalUpdated: "2026-08-01",
  store: {
    customer: {
      appStore: process.env.NEXT_PUBLIC_CUSTOMER_APPSTORE_URL || "",
      playStore: process.env.NEXT_PUBLIC_CUSTOMER_PLAY_URL || "",
    },
    driver: {
      appStore: process.env.NEXT_PUBLIC_DRIVER_APPSTORE_URL || "",
      playStore: process.env.NEXT_PUBLIC_DRIVER_PLAY_URL || "",
    },
  },
  contact: {
    email: process.env.NEXT_PUBLIC_CONTACT_EMAIL || "",
    phone: process.env.NEXT_PUBLIC_CONTACT_PHONE || "+966 53 335 6126",
    whatsapp: process.env.NEXT_PUBLIC_WHATSAPP_URL || "https://wa.me/966533356126",
  },
  social: {
    instagram: process.env.NEXT_PUBLIC_SOCIAL_INSTAGRAM || "",
    twitter: process.env.NEXT_PUBLIC_SOCIAL_TWITTER || "",
    linkedin: process.env.NEXT_PUBLIC_SOCIAL_LINKEDIN || "",
    snapchat: process.env.NEXT_PUBLIC_SOCIAL_SNAPCHAT || "",
  },
} as const;

export type Locale = (typeof siteConfig.locales)[number];

export function getSiteUrl() {
  if (siteConfig.url) return siteConfig.url;
  if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`;
  return "http://localhost:3000";
}

export function hasStoreLink(url: string) {
  return url.trim().length > 0;
}
