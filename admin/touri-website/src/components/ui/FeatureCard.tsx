import type { ComponentType, SVGProps } from "react";
import { cn } from "@/lib/utils";

type Props = {
  icon: ComponentType<SVGProps<SVGSVGElement> & { size?: number }>;
  title: string;
  text: string;
  tone?: "default" | "driver";
};

export function FeatureCard({
  icon: Icon,
  title,
  text,
  tone = "default",
}: Props) {
  return (
    <article className="premium-card flex h-full min-w-0 flex-col p-6 sm:p-7">
      <div
        className={cn(
          "mb-5 flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl",
          tone === "driver"
            ? "bg-[color-mix(in_srgb,var(--accent-red)_12%,white)] text-accent-red dark:bg-[color-mix(in_srgb,var(--accent-red)_18%,transparent)]"
            : "bg-[color-mix(in_srgb,var(--primary)_12%,white)] text-primary dark:bg-[color-mix(in_srgb,var(--primary)_18%,transparent)]",
        )}
      >
        <Icon size={22} />
      </div>
      <h3 className="text-lg leading-snug font-bold tracking-normal">{title}</h3>
      <p className="mt-2 flex-1 text-sm leading-7 text-muted">{text}</p>
    </article>
  );
}
