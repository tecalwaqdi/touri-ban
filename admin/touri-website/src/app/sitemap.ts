import type { MetadataRoute } from "next";
import { getSiteUrl } from "@/config/site";
import { locales } from "@/i18n/config";

const pages = ["", "/about", "/privacy", "/terms", "/support"];

export default function sitemap(): MetadataRoute.Sitemap {
  const site = getSiteUrl();
  return locales.flatMap((locale) =>
    pages.map((page) => ({
      url: `${site}/${locale}${page}`,
      lastModified: new Date(),
      changeFrequency: page === "" ? "weekly" : "monthly",
      priority: page === "" ? 1 : 0.6,
      alternates: {
        languages: {
          ar: `${site}/ar${page}`,
          en: `${site}/en${page}`,
        },
      },
    })),
  );
}
