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
    <article className="mx-auto max-w-3xl px-4 py-16 sm:px-6">
      <Link href={localePath(locale, "/")} className="text-sm font-semibold text-primary">
        {dict.legal.back}
      </Link>
      {badge ? (
        <p className="mt-6 inline-flex rounded-full bg-accent-soft px-3 py-1 text-xs font-bold text-secondary">
          {badge}
        </p>
      ) : null}
      <h1 className="font-display mt-4 text-4xl leading-[1.3] font-bold tracking-normal">
        {title}
      </h1>
      {updated ? <p className="mt-2 text-sm leading-6 text-muted">{updated}</p> : null}
      <p className="mt-6 text-lg leading-8 text-muted">{intro}</p>
      <div className="mt-10 space-y-8">
        {sections.map((section) => (
          <section key={section.title} className="premium-card p-6">
            <h2 className="text-xl font-bold">{section.title}</h2>
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
