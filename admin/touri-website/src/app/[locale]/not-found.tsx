"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { isLocale, localePath } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";

export default function LocaleNotFound() {
  const params = useParams();
  const raw = typeof params.locale === "string" ? params.locale : "ar";
  const locale = isLocale(raw) ? raw : "ar";
  const dict = getDictionary(locale);

  return (
    <div className="mx-auto max-w-md px-4 py-24 text-center">
      <p className="text-sm font-bold tracking-[0.2em] text-primary uppercase">Touri</p>
      <h1 className="mt-3 text-4xl font-bold">{dict.notFound.title}</h1>
      <p className="mt-3 text-muted">{dict.notFound.body}</p>
      <Link href={localePath(locale, "/")} className="btn-primary mt-6">
        {dict.legal.back}
      </Link>
    </div>
  );
}
