"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ComponentType, SVGProps } from "react";
import { cn } from "@/lib/utils";

type Props = {
  icon: ComponentType<SVGProps<SVGSVGElement> & { size?: number }>;
  title: string;
  text: string;
  tone?: "customer" | "driver";
};

export function AppFeatureTile({
  icon: Icon,
  title,
  text,
  tone = "customer",
}: Props) {
  const reduce = useReducedMotion();
  const driver = tone === "driver";

  return (
    <motion.article
      variants={{
        hidden: { opacity: 0, y: reduce ? 0 : 12 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={reduce ? undefined : { y: -3 }}
      transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
      className={cn(
        "group flex h-full items-start gap-3 rounded-2xl border bg-surface/90 px-3.5 py-3.5",
        driver
          ? "border-border hover:border-accent-red/30"
          : "border-border hover:border-primary/30",
      )}
    >
      <span
        className={cn(
          "mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-xl transition-transform duration-300 group-hover:-translate-y-0.5 motion-reduce:group-hover:translate-y-0",
          driver
            ? "bg-[color-mix(in_srgb,var(--accent-red)_12%,white)] text-accent-red dark:bg-[color-mix(in_srgb,var(--accent-red)_18%,transparent)]"
            : "bg-[color-mix(in_srgb,var(--primary)_12%,white)] text-primary dark:bg-[color-mix(in_srgb,var(--primary)_18%,transparent)]",
        )}
      >
        <Icon size={16} />
      </span>
      <span className="min-w-0 flex-1 overflow-visible">
        <h3 className="text-sm leading-snug font-bold tracking-normal">
          {title}
        </h3>
        <p className="mt-1 text-xs leading-6 text-muted">{text}</p>
      </span>
    </motion.article>
  );
}
