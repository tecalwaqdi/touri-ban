"use client";

import Image from "next/image";
import { useState } from "react";
import type { Dictionary } from "@/i18n/get-dictionary";
import { PhoneMockup } from "@/components/ui/PhoneMockup";
import { Reveal } from "@/components/ui/Reveal";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { cn } from "@/lib/utils";

type Props = {
  dict: Dictionary;
};

export function AppScreens({ dict }: Props) {
  const [active, setActive] = useState(0);
  const item = dict.screens.items[active];

  return (
    <section className="overflow-x-clip px-4 py-12 sm:px-6 sm:py-16">
      <div className="mx-auto max-w-7xl">
        <SectionTitle
          eyebrow={dict.screens.eyebrow}
          title={dict.screens.title}
          subtitle={dict.screens.subtitle}
          align="center"
        />
        <div className="mt-8 grid items-center gap-6 sm:mt-10 sm:gap-8 lg:grid-cols-[auto_1fr] lg:gap-12">
          <Reveal className="mx-auto w-full max-w-[14rem] sm:max-w-none">
            <PhoneMockup src={item.image} alt={item.alt} size="md" />
          </Reveal>
          <div className="min-w-0">
            <div className="grid gap-3 sm:grid-cols-2">
              {dict.screens.items.map((screen, index) => (
                <button
                  key={screen.title}
                  type="button"
                  onClick={() => setActive(index)}
                  className={cn(
                    "min-w-0 overflow-hidden rounded-2xl border text-start transition sm:rounded-3xl",
                    active === index
                      ? "border-primary shadow-soft"
                      : "border-border hover:border-primary/40",
                  )}
                  aria-pressed={active === index}
                >
                  <div className="relative h-28 bg-[#0d1412] sm:h-36">
                    <Image
                      src={screen.image}
                      alt={screen.alt}
                      fill
                      quality={85}
                      className="object-cover object-top"
                      sizes="(max-width: 640px) 100vw, 280px"
                    />
                  </div>
                  <div className="bg-surface p-3.5 sm:p-4">
                    <p className="text-sm leading-snug font-bold tracking-normal sm:text-base">
                      {screen.title}
                    </p>
                    <p className="mt-1 text-xs leading-5 text-muted sm:mt-1.5 sm:text-sm sm:leading-6">
                      {screen.text}
                    </p>
                  </div>
                </button>
              ))}
            </div>
            <p className="mt-3 text-xs leading-5 text-muted sm:mt-4">
              {dict.screens.note}
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
