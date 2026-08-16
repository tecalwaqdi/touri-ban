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
    <article className="premium-card flex h-full min-w-0 flex-col p-4 sm:p-6 lg:p-7">
      <div
        className={cn(
          "mb-3.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl sm:mb-5 sm:h-12 sm:w-12 sm:rounded-2xl",
          tone === "driver"
            ? "bg-[color-mix(in_srgb,var(--accent-red)_12%,white)] text-accent-red dark:bg-[color-mix(in_srgb,var(--accent-red)_18%,transparent)]"
            : "bg-[color-mix(in_srgb,var(--primary)_12%,white)] text-primary dark:bg-[color-mix(in_srgb,var(--primary)_18%,transparent)]",
        )}
      >
        <Icon size={22} />
      </div>
      <h3 className="text-base leading-snug font-bold tracking-normal sm:text-lg">
        {title}
      </h3>
      <p className="mt-1.5 flex-1 text-sm leading-6 text-muted sm:mt-2 sm:leading-7">
        {text}
      </p>
    </article>
  );
}
