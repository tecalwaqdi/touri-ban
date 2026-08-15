import type { Locale } from "@/i18n/config";
import { ar, type Dictionary } from "@/i18n/ar";
import { en } from "@/i18n/en";

export type { Dictionary };

export function getDictionary(locale: Locale): Dictionary {
  return locale === "en" ? en : ar;
}
