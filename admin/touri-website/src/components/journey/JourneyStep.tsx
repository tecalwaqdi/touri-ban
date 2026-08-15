"use client";

import { motion } from "framer-motion";
import type { JourneyKind, JourneyVisual } from "@/config/journey";
import { cn } from "@/lib/utils";

type Props = {
  index: number;
  title: string;
  hint: string;
  visual: JourneyVisual;
  active: boolean;
  kind: JourneyKind;
  reduce: boolean;
  onSelect: () => void;
};

export function JourneyStep({
  index,
  title,
  hint,
  visual,
  active,
  kind,
  reduce,
  onSelect,
}: Props) {
  const Icon = visual.icon;
  const driver = kind === "driver";

  return (
    <motion.button
      type="button"
      onClick={onSelect}
      aria-current={active ? "step" : undefined}
      whileHover={reduce ? undefined : { y: -2 }}
      transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
      className={cn(
        "flex w-full items-start gap-3 rounded-2xl border px-4 py-3.5 text-start transition-[border-color,box-shadow,background-color] duration-300",
        active
          ? driver
            ? "border-[#c94b45]/40 bg-surface shadow-[0_10px_28px_rgba(201,75,69,0.12)]"
            : "border-primary/40 bg-surface shadow-[0_10px_28px_rgba(31,111,95,0.12)]"
          : "border-border bg-surface hover:border-primary/25",
      )}
    >
      <span className="relative mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center">
        <span
          className={cn(
            "absolute inset-0 rounded-full",
            active
              ? driver
                ? "bg-[#c94b45]"
                : "bg-primary"
              : "bg-[color-mix(in_srgb,var(--primary)_10%,var(--surface-muted))]",
          )}
        />
        {active && !reduce ? (
          <motion.span
            className={cn(
              "absolute -inset-1 rounded-full",
              driver ? "bg-[#c94b45]/25" : "bg-primary/25",
            )}
            animate={{ scale: [1, 1.12, 1], opacity: [0.45, 0.12, 0.45] }}
            transition={{ duration: 2.4, repeat: Infinity, ease: "easeInOut" }}
          />
        ) : null}
        <span
          className={cn(
            "relative text-xs font-bold",
            active ? "text-white" : "text-foreground/70",
          )}
        >
          {index + 1}
        </span>
      </span>

      <span className="min-w-0 flex-1 overflow-visible">
        <span className="flex items-start gap-2">
          <span
            className={cn(
              "mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg",
              active
                ? driver
                  ? "bg-[color-mix(in_srgb,#c94b45_14%,white)] text-[#c94b45] dark:bg-[color-mix(in_srgb,#c94b45_22%,transparent)]"
                  : "bg-[color-mix(in_srgb,var(--primary)_14%,white)] text-primary dark:bg-[color-mix(in_srgb,var(--primary)_22%,transparent)]"
                : "bg-surface-muted text-muted",
            )}
          >
            <Icon size={15} />
          </span>
          <span className="min-w-0 text-sm leading-snug font-bold tracking-normal text-foreground sm:text-[15px] sm:leading-snug">
            {title}
          </span>
        </span>
        <span className="mt-1.5 block text-[13px] leading-6 text-muted">{hint}</span>
      </span>
    </motion.button>
  );
}
