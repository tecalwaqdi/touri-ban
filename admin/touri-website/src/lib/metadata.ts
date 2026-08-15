import type { Metadata } from "next";
import { getSiteUrl, siteConfig } from "@/config/site";
import type { Locale } from "@/i18n/config";
import { localePath } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";

export function buildMetadata({
  locale,
  dict,
  title,
  description,
  path = "",
}: {
  locale: Locale;
  dict: Dictionary;
  title: string;
  description: string;
  path?: string;
}): Metadata {
  const site = getSiteUrl();
  const canonical = `${site}${localePath(locale, path)}`;
  const ogImage = `${site}/images/landmarks/jeddah_new_corniche.png`;

  return {
    title,
    description,
    metadataBase: new URL(site),
    alternates: {
      canonical,
      languages: {
        ar: `${site}${localePath("ar", path)}`,
        en: `${site}${localePath("en", path)}`,
        "x-default": `${site}${localePath(siteConfig.defaultLocale, path)}`,
      },
    },
    openGraph: {
      type: "website",
      locale: locale === "ar" ? "ar_SA" : "en_US",
      url: canonical,
      siteName: siteConfig.legalName,
      title,
      description,
      images: [{ url: ogImage, alt: dict.meta.ogAlt }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [ogImage],
    },
    robots: { index: true, follow: true },
    icons: {
      icon: "/icon.png",
      apple: "/apple-touch-icon.png",
    },
  };
}
