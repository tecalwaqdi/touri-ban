import Link from "next/link";
import type { Locale } from "@/i18n/config";
import { localePath } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";

type Section = {
  title: string;
  paragraphs?: readonly string[];
  bullets?: readonly string[];
};

type Props = {
  locale: Locale;
  dict: Dictionary;
  title: string;
  intro: string;
  updated?: string;
  badge?: string;
  sections: readonly Section[] | ReadonlyArray<Section>;
};

export function LegalPage({
  locale,
  dict,
  title,
  intro,
  updated,
  badge,
  sections,
}: Props) {
  return (
    <article className="mx-auto max-w-3xl px-4 py-10 sm:px-6 sm:py-16">
      <Link href={localePath(locale, "/")} className="text-sm font-semibold text-primary">
        {dict.legal.back}
      </Link>
      {badge ? (
        <p className="mt-5 inline-flex rounded-full bg-accent-soft px-3 py-1 text-xs font-bold text-secondary sm:mt-6">
          {badge}
        </p>
      ) : null}
      <h1 className="font-display mt-3 text-[1.85rem] leading-[1.3] font-bold tracking-normal sm:mt-4 sm:text-4xl">
        {title}
      </h1>
      {updated ? <p className="mt-2 text-sm leading-6 text-muted">{updated}</p> : null}
      <p className="mt-4 text-base leading-7 text-muted sm:mt-6 sm:text-lg sm:leading-8">{intro}</p>
      <div className="mt-8 space-y-5 sm:mt-10 sm:space-y-8">
        {sections.map((section) => (
          <section key={section.title} className="premium-card p-4 sm:p-6">
            <h2 className="text-lg font-bold sm:text-xl">{section.title}</h2>
            {section.paragraphs?.map((p) => (
              <p key={p} className="mt-3 text-sm leading-7 text-muted">
                {p}
              </p>
            ))}
            {section.bullets ? (
              <ul className="mt-3 list-disc space-y-2 ps-5 text-sm leading-7 text-muted">
                {section.bullets.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            ) : null}
          </section>
        ))}
      </div>
    </article>
  );
}
