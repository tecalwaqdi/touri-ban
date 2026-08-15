import { Reveal } from "@/components/ui/Reveal";
import { cn } from "@/lib/utils";

type Props = {
  eyebrow: string;
  title: string;
  subtitle?: string;
  align?: "start" | "center";
  light?: boolean;
};

export function SectionTitle({
  eyebrow,
  title,
  subtitle,
  align = "start",
  light = false,
}: Props) {
  return (
    <Reveal
      className={cn(
        "max-w-3xl overflow-visible",
        align === "center" && "mx-auto text-center",
      )}
    >
      <p
        className={cn(
          "mb-3 text-sm font-semibold tracking-[0.14em] uppercase rtl:tracking-normal",
          light ? "text-accent" : "text-primary",
        )}
      >
        {eyebrow}
      </p>
      <h2
        className={cn(
          "font-display text-3xl leading-[1.35] font-bold tracking-normal sm:text-4xl sm:leading-[1.3] lg:text-5xl lg:leading-[1.25]",
          light ? "text-white" : "text-foreground",
        )}
      >
        {title}
      </h2>
      {subtitle ? (
        <p
          className={cn(
            "mt-4 max-w-3xl text-base leading-8 sm:text-lg sm:leading-8",
            light ? "text-white/75" : "text-muted",
          )}
        >
          {subtitle}
        </p>
      ) : null}
    </Reveal>
  );
}
