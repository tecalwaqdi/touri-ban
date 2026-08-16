import type { Dictionary } from "@/i18n/get-dictionary";
import { paymentIcons, safetyIcons } from "@/components/icons";
import { FeatureCard } from "@/components/ui/FeatureCard";
import { SectionTitle } from "@/components/ui/SectionTitle";

type Props = {
  dict: Dictionary;
};

export function Trust({ dict }: Props) {
  return (
    <section id="safety" className="bg-surface-muted px-4 py-12 sm:px-6 sm:py-16">
      <div className="mx-auto max-w-7xl space-y-10 sm:space-y-16">
        <div>
          <SectionTitle
            eyebrow={dict.payment.eyebrow}
            title={dict.payment.title}
            subtitle={dict.payment.subtitle}
          />
          <div className="mt-8 grid gap-3 sm:mt-10 sm:grid-cols-2 sm:gap-4 lg:grid-cols-3 xl:grid-cols-5">
            {dict.payment.items.map((item, index) => {
              const Icon = paymentIcons[index] ?? paymentIcons[0];
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
        <div>
          <SectionTitle
            eyebrow={dict.safety.eyebrow}
            title={dict.safety.title}
            subtitle={dict.safety.subtitle}
          />
          <div className="mt-8 grid gap-3 sm:mt-10 sm:gap-4 md:grid-cols-2 xl:grid-cols-3">
            {dict.safety.items.map((item, index) => {
              const Icon = safetyIcons[index] ?? safetyIcons[0];
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
      </div>
    </section>
  );
}
