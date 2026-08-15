"use client";

import {
  motion,
  useMotionValueEvent,
  useReducedMotion,
  useScroll,
  useSpring,
} from "framer-motion";
import { useRef, useState } from "react";
import type { JourneyKind, JourneyVisual } from "@/config/journey";
import { JourneyStep } from "@/components/journey/JourneyStep";
import { cn } from "@/lib/utils";

type Props = {
  kind: JourneyKind;
  steps: readonly string[];
  hints: readonly string[];
  visuals: readonly JourneyVisual[];
  labelledBy: string;
};

export function JourneyTimeline({
  kind,
  steps,
  hints,
  visuals,
  labelledBy,
}: Props) {
  const reduce = Boolean(useReducedMotion());
  const trackRef = useRef<HTMLOListElement>(null);
  const [active, setActive] = useState(0);
  const driver = kind === "driver";
  const count = steps.length;
  const accent = driver ? "#c94b45" : "var(--primary)";

  const { scrollYProgress } = useScroll({
    target: trackRef,
    offset: ["start 0.75", "end 0.5"],
  });
  const progress = useSpring(scrollYProgress, {
    stiffness: 90,
    damping: 30,
    restDelta: 0.001,
  });

  useMotionValueEvent(scrollYProgress, "change", (value) => {
    if (count < 2) return;
    const next = Math.round(Math.min(1, Math.max(0, value)) * (count - 1));
    setActive(next);
  });

  return (
    <div className="relative">
      <div className="pointer-events-none absolute top-4 bottom-4 w-px bg-border md:hidden inset-inline-start-[1.125rem]" />
      <motion.div
        className="pointer-events-none absolute top-4 bottom-4 w-px origin-top md:hidden inset-inline-start-[1.125rem]"
        style={{ background: accent, scaleY: reduce ? 1 : progress }}
      />

      <div className="pointer-events-none absolute top-5 bottom-5 left-1/2 hidden w-px -translate-x-1/2 bg-border md:block" />
      <motion.div
        className="pointer-events-none absolute top-5 bottom-5 left-1/2 hidden w-px origin-top -translate-x-1/2 md:block"
        style={{ background: accent, scaleY: reduce ? 1 : progress }}
      />

      <ol
        ref={trackRef}
        className="relative space-y-3 md:space-y-1"
        aria-labelledby={labelledBy}
      >
        {steps.map((title, index) => {
          const onStart = index % 2 === 0;
          const reached = active >= index;
          const isActive = active === index;
          const step = (
            <JourneyStep
              index={index}
              title={title}
              hint={hints[index] ?? ""}
              visual={visuals[index] ?? visuals[0]}
              active={isActive}
              kind={kind}
              reduce={reduce}
              onSelect={() => setActive(index)}
            />
          );

          return (
            <motion.li
              key={`${kind}-${title}`}
              className="relative grid grid-cols-1 items-center ps-10 md:min-h-[6.5rem] md:grid-cols-[1fr_2.5rem_1fr] md:ps-0"
              initial={reduce ? false : { opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.4 }}
              transition={{
                duration: 0.38,
                delay: reduce ? 0 : index * 0.03,
                ease: [0.22, 1, 0.36, 1],
              }}
            >
              <span
                aria-hidden="true"
                className={cn(
                  "absolute top-5 size-2.5 rounded-full border-2 md:hidden inset-inline-start-[0.9rem]",
                  !reached && "border-border bg-background",
                )}
                style={
                  reached
                    ? { background: accent, borderColor: accent }
                    : undefined
                }
              />

              <div className={cn("hidden md:block", onStart && "md:pe-4")}>
                {onStart ? step : null}
              </div>

              <div className="relative z-10 hidden items-center justify-center md:flex">
                <span
                  aria-hidden="true"
                  className={cn(
                    "absolute top-1/2 h-px w-3 -translate-y-1/2",
                    onStart ? "end-full" : "start-full",
                  )}
                  style={{ background: reached ? accent : "var(--border)" }}
                />
                <span
                  aria-hidden="true"
                  className={cn(
                    "relative z-10 size-3 rounded-full border-2 bg-background",
                    !reached && "border-border",
                  )}
                  style={
                    reached
                      ? { background: accent, borderColor: accent }
                      : undefined
                  }
                />
              </div>

              <div className={cn("hidden md:block", !onStart && "md:ps-4")}>
                {!onStart ? step : null}
              </div>

              <div className="md:hidden">{step}</div>
            </motion.li>
          );
        })}
      </ol>
    </div>
  );
}
