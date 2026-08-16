import Image from "next/image";
import type { Dictionary } from "@/i18n/get-dictionary";
import { ExploreDestinations } from "@/components/sections/ExploreDestinations";
import { Reveal } from "@/components/ui/Reveal";
import { SectionTitle } from "@/components/ui/SectionTitle";

type Props = {
  dict: Dictionary;
};

export function Stats({ dict }: Props) {
  return (
    <section className="px-4 py-12 sm:px-6 sm:py-16">
      <div className="mx-auto max-w-7xl">
        <SectionTitle
          eyebrow={dict.stats.eyebrow}
          title={dict.stats.title}
          subtitle={dict.stats.subtitle}
        />
        <Reveal>
          <div className="mt-8 grid gap-3 sm:mt-10 sm:grid-cols-2 sm:gap-4 lg:grid-cols-4">
            {dict.stats.items.map((item) => (
              <article key={item.title} className="premium-card min-w-0 p-4 sm:p-6">
                <p className="text-base leading-snug font-bold tracking-normal sm:text-lg">
                  {item.title}
                </p>
                <p className="mt-1.5 text-sm leading-6 text-muted sm:mt-2 sm:leading-7">
                  {item.text}
                </p>
              </article>
            ))}
          </div>
        </Reveal>

        <div className="mt-12 border-t border-border/70 pt-10 sm:mt-16 sm:pt-12">
          <ExploreDestinations dict={dict} />
          <div className="mt-6 flex flex-col items-center justify-center gap-2 text-center text-sm text-muted sm:mt-8 sm:flex-row sm:gap-3 sm:justify-start sm:text-start">
            <Image
              src="/images/brand/vision_2030.png"
              alt={dict.brands.vision}
              width={120}
              height={40}
              className="h-8 w-auto sm:h-9"
              style={{ width: "auto" }}
            />
            <span className="max-w-xs leading-6 sm:max-w-none">{dict.brands.vision}</span>
          </div>
        </div>
      </div>
    </section>
  );
}
