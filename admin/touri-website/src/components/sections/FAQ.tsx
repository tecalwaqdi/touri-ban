"use client";

import { useState } from "react";
import type { Dictionary } from "@/i18n/get-dictionary";
import { IconChevron } from "@/components/icons";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { cn } from "@/lib/utils";

type Props = {
  dict: Dictionary;
};

export function FAQ({ dict }: Props) {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="px-4 py-12 sm:px-6 sm:py-16">
      <div className="mx-auto max-w-3xl">
        <SectionTitle
          eyebrow={dict.faq.eyebrow}
          title={dict.faq.title}
          subtitle={dict.faq.subtitle}
          align="center"
        />
        <div className="mt-8 divide-y divide-border overflow-hidden rounded-[1.25rem] border border-border bg-surface sm:mt-10 sm:rounded-[1.6rem]">
          {dict.faq.items.map((item, index) => {
            const expanded = open === index;
            return (
              <div key={item.q}>
                <h3>
                  <button
                    type="button"
                    className="flex w-full items-start justify-between gap-3 px-4 py-4 text-start text-[15px] leading-snug font-bold sm:gap-4 sm:px-5 sm:py-5 sm:text-base"
                    aria-expanded={expanded}
                    onClick={() => setOpen(expanded ? null : index)}
                  >
                    <span className="min-w-0 flex-1">{item.q}</span>
                    <IconChevron
                      className={cn(
                        "mt-0.5 shrink-0 transition-transform",
                        expanded && "rotate-180",
                      )}
                    />
                  </button>
                </h3>
                <div
                  hidden={!expanded}
                  className="px-4 pb-4 text-sm leading-7 text-muted sm:px-5 sm:pb-5"
                >
                  {item.a}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
