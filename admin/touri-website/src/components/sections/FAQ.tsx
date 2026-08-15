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
    <section id="faq" className="scroll-mt-24 px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <SectionTitle
          eyebrow={dict.faq.eyebrow}
          title={dict.faq.title}
          subtitle={dict.faq.subtitle}
          align="center"
        />
        <div className="mt-10 divide-y divide-border overflow-hidden rounded-[1.6rem] border border-border bg-surface">
          {dict.faq.items.map((item, index) => {
            const expanded = open === index;
            return (
              <div key={item.q}>
                <h3>
                  <button
                    type="button"
                    className="flex w-full items-start justify-between gap-4 px-5 py-5 text-start text-base leading-snug font-bold"
                    aria-expanded={expanded}
                    onClick={() => setOpen(expanded ? null : index)}
                  >
                    <span className="min-w-0 flex-1">{item.q}</span>
                    <IconChevron
                      className={cn(
                        "mt-1 shrink-0 transition-transform",
                        expanded && "rotate-180",
                      )}
                    />
                  </button>
                </h3>
                <div
                  hidden={!expanded}
                  className="px-5 pb-5 text-sm leading-7 text-muted"
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
