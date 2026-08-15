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
    <section className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-7xl">
        <SectionTitle
          eyebrow={dict.stats.eyebrow}
          title={dict.stats.title}
          subtitle={dict.stats.subtitle}
        />
        <Reveal>
          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {dict.stats.items.map((item) => (
              <article key={item.title} className="premium-card min-w-0 p-6">
                <p className="text-lg leading-snug font-bold tracking-normal">{item.title}</p>
                <p className="mt-2 text-sm leading-7 text-muted">{item.text}</p>
              </article>
            ))}
          </div>
        </Reveal>

        <div className="mt-16 border-t border-border/70 pt-12">
          <ExploreDestinations dict={dict} />
          <div className="mt-8 flex items-center justify-center gap-3 text-sm text-muted sm:justify-start">
            <Image
              src="/images/brand/vision_2030.png"
              alt={dict.brands.vision}
              width={120}
              height={40}
              className="h-9 w-auto"
              style={{ width: "auto" }}
            />
            <span>{dict.brands.vision}</span>
          </div>
        </div>
      </div>
    </section>
  );
}
