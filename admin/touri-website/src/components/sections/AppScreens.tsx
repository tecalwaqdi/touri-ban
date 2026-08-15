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
    <section className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-7xl">
        <SectionTitle
          eyebrow={dict.screens.eyebrow}
          title={dict.screens.title}
          subtitle={dict.screens.subtitle}
          align="center"
        />
        <div className="mt-10 grid items-center gap-8 lg:grid-cols-[auto_1fr] lg:gap-12">
          <Reveal className="mx-auto">
            <PhoneMockup src={item.image} alt={item.alt} size="md" />
          </Reveal>
          <div>
            <div className="grid gap-3 sm:grid-cols-2">
              {dict.screens.items.map((screen, index) => (
                <button
                  key={screen.title}
                  type="button"
                  onClick={() => setActive(index)}
                  className={cn(
                    "overflow-hidden rounded-3xl border text-start transition",
                    active === index
                      ? "border-primary shadow-soft"
                      : "border-border hover:border-primary/40",
                  )}
                  aria-pressed={active === index}
                >
                  <div className="relative h-36 bg-[#0d1412]">
                    <Image
                      src={screen.image}
                      alt={screen.alt}
                      fill
                      quality={85}
                      className="object-cover object-top"
                      sizes="(max-width: 768px) 100vw, 280px"
                    />
                  </div>
                  <div className="bg-surface p-4">
                    <p className="leading-snug font-bold tracking-normal">{screen.title}</p>
                    <p className="mt-1.5 text-sm leading-6 text-muted">{screen.text}</p>
                  </div>
                </button>
              ))}
            </div>
            <p className="mt-4 text-xs text-muted">{dict.screens.note}</p>
          </div>
        </div>
      </div>
    </section>
  );
}
