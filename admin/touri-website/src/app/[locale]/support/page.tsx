import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Contact } from "@/components/sections/Contact";
import { isLocale, localePath } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";
import { buildMetadata } from "@/lib/metadata";
import Link from "next/link";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  if (!isLocale(locale)) return {};
  const dict = getDictionary(locale);
  return buildMetadata({
    locale,
    dict,
    title: dict.meta.supportTitle,
    description: dict.supportPage.intro,
    path: "/support",
  });
}

export default async function SupportPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  const dict = getDictionary(locale);

  return (
    <div className="mx-auto max-w-7xl px-4 pt-12 sm:px-6">
      <Link href={localePath(locale, "/")} className="text-sm font-semibold text-primary">
        {dict.legal.back}
      </Link>
      <h1 className="font-display mt-4 text-4xl font-bold">{dict.supportPage.title}</h1>
      <p className="mt-4 max-w-2xl text-lg leading-8 text-muted">{dict.supportPage.intro}</p>
      <p className="mt-3 max-w-2xl text-sm text-muted">{dict.supportPage.hours}</p>
      <Contact dict={dict} />
    </div>
  );
}
