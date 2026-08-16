"use client";

import { motion } from "framer-motion";
import type { JourneyKind } from "@/config/journey";
import { cn } from "@/lib/utils";

type Props = {
  kind: JourneyKind;
  customerLabel: string;
  driverLabel: string;
  ariaLabel: string;
  onChange: (kind: JourneyKind) => void;
};

export function JourneySwitcher({
  kind,
  customerLabel,
  driverLabel,
  ariaLabel,
  onChange,
}: Props) {
  return (
    <div
      className="mx-auto flex w-full max-w-sm rounded-full border border-border bg-surface p-1 shadow-sm"
      role="tablist"
      aria-label={ariaLabel}
    >
      {(
        [
          { id: "customer", label: customerLabel },
          { id: "driver", label: driverLabel },
        ] as const
      ).map((item) => {
        const active = kind === item.id;
        return (
          <button
            key={item.id}
            type="button"
            role="tab"
            aria-selected={active}
            className={cn(
              "relative z-0 flex-1 rounded-full px-2 py-2 text-xs leading-snug font-bold transition-colors sm:px-3 sm:py-2.5 sm:text-sm",
              active ? "text-white" : "text-muted hover:text-foreground",
            )}
            onClick={() => onChange(item.id)}
          >
            {active ? (
              <motion.span
                layoutId="how-switcher"
                className={cn(
                  "absolute inset-0 -z-10 rounded-full",
                  item.id === "driver" ? "bg-[#c94b45]" : "bg-primary",
                )}
                transition={{ type: "spring", stiffness: 420, damping: 34 }}
              />
            ) : null}
            <span className="relative block whitespace-normal">{item.label}</span>
          </button>
        );
      })}
    </div>
  );
}
