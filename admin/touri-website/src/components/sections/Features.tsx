import type { Dictionary } from "@/i18n/get-dictionary";
import { featureIcons } from "@/components/icons";
import { FeatureCard } from "@/components/ui/FeatureCard";
import { SectionTitle } from "@/components/ui/SectionTitle";

type Props = {
  dict: Dictionary;
};

export function Features({ dict }: Props) {
  return (
    <section id="features" className="px-4 py-12 sm:px-6 sm:py-16">
      <div className="mx-auto max-w-7xl">
        <SectionTitle
          eyebrow={dict.features.eyebrow}
          title={dict.features.title}
          subtitle={dict.features.subtitle}
        />
        <div className="mt-8 grid gap-3 sm:mt-10 sm:grid-cols-2 sm:gap-4 lg:grid-cols-3 xl:grid-cols-5">
          {dict.features.items.map((item, index) => {
            const Icon = featureIcons[index] ?? featureIcons[0];
            return (
              <FeatureCard
                key={item.title}
                icon={Icon}
                title={item.title}
                text={item.text}
              />
            );
          })}
        </div>
      </div>
    </section>
  );
}
