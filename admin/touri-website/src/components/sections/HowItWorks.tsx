"use client";

import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useId, useState } from "react";
import type { Dictionary } from "@/i18n/get-dictionary";
import type { JourneyKind } from "@/config/journey";
import { journeyVisuals } from "@/config/journey";
import { JourneySwitcher } from "@/components/journey/JourneySwitcher";
import { JourneyTimeline } from "@/components/journey/JourneyTimeline";

type Props = {
  dict: Dictionary;
};

export function HowItWorks({ dict }: Props) {
  const reduce = useReducedMotion();
  const headingId = useId();
  const [kind, setKind] = useState<JourneyKind>("customer");

  const copy =
    kind === "driver"
      ? {
          steps: dict.how.driverSteps,
          hints: dict.how.driverHints,
          subtitle: dict.how.driverSubtitle,
        }
      : {
          steps: dict.how.customerSteps,
          hints: dict.how.customerHints,
          subtitle: dict.how.customerSubtitle,
        };

  return (
    <section
      id="how"
      className="scroll-mt-24 overflow-x-clip border-y border-border/60 bg-[linear-gradient(180deg,color-mix(in_srgb,var(--surface-muted)_72%,transparent)_0%,var(--background)_28%,var(--background)_100%)] px-4 py-12 sm:px-6 sm:py-14"
    >
      <div className="mx-auto max-w-5xl">
        <header className="mx-auto max-w-2xl overflow-visible text-center">
          <p className="text-sm font-semibold tracking-[0.14em] text-primary uppercase rtl:tracking-normal">
            {dict.how.eyebrow}
          </p>
          <h2 className="font-display mt-2 text-3xl leading-[1.35] font-bold tracking-normal text-foreground sm:text-4xl sm:leading-[1.3]">
            {dict.how.title}
          </h2>

          <div className="mt-5">
            <JourneySwitcher
              kind={kind}
              customerLabel={dict.how.customerTitle}
              driverLabel={dict.how.driverTitle}
              ariaLabel={dict.how.eyebrow}
              onChange={setKind}
            />
          </div>
        </header>

        <AnimatePresence mode="wait">
          <motion.div
            key={kind}
            initial={reduce ? false : { opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={reduce ? undefined : { opacity: 0, y: -8 }}
            transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
            className="mt-4"
          >
            <p className="mx-auto max-w-xl text-center text-[15px] leading-8 text-muted">
              {copy.subtitle}
            </p>
            <h3 id={headingId} className="sr-only">
              {kind === "driver" ? dict.how.driverTitle : dict.how.customerTitle}
            </h3>
            <div className="mt-7">
              <JourneyTimeline
                kind={kind}
                steps={copy.steps}
                hints={copy.hints}
                visuals={journeyVisuals(kind)}
                labelledBy={headingId}
              />
            </div>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  );
}
