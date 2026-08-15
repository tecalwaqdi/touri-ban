import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, localePath } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";
import { buildMetadata } from "@/lib/metadata";

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
    title: dict.meta.aboutTitle,
    description: dict.about.intro,
    path: "/about",
  });
}

export default async function AboutPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  const dict = getDictionary(locale);

  return (
    <article className="mx-auto max-w-3xl px-4 py-16 sm:px-6">
      <Link href={localePath(locale, "/")} className="text-sm font-semibold text-primary">
        {dict.legal.back}
      </Link>
      <h1 className="font-display mt-6 text-4xl leading-[1.3] font-bold tracking-normal">
        {dict.about.title}
      </h1>
      <p className="mt-5 text-lg leading-8 text-muted">{dict.about.intro}</p>
      <div className="mt-8 space-y-5">
        {dict.about.body.map((p) => (
          <p key={p} className="text-base leading-8 text-muted">
            {p}
          </p>
        ))}
      </div>
    </article>
  );
}
