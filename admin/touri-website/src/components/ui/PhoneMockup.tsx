import Image from "next/image";
import { cn } from "@/lib/utils";

type Props = {
  src: string;
  alt: string;
  className?: string;
  float?: "slow" | "slower" | "none";
  /** Medium balanced phone: slightly smaller companion for depth. */
  size?: "md" | "sm";
  priority?: boolean;
};

/** Fluid widths: medium on phone, capped on desktop — never forces a huge floor. */
const sizeClass = {
  md: "w-[min(13.25rem,58vw)] sm:w-[min(14.5rem,42vw)] lg:w-[15rem]",
  sm: "w-[min(11.5rem,48vw)] sm:w-[min(12.75rem,36vw)] lg:w-[13.25rem]",
} as const;

export function PhoneMockup({
  src,
  alt,
  className,
  float = "none",
  size = "md",
  priority = false,
}: Props) {
  return (
    <div
      className={cn(
        "phone-frame relative mx-auto max-w-full",
        sizeClass[size],
        float === "slow" && "float-slow",
        float === "slower" && "float-slower",
        className,
      )}
      style={{ aspectRatio: "1206 / 2622" }}
    >
      <div className="phone-screen relative h-full w-full overflow-hidden">
        <Image
          src={src}
          alt={alt}
          fill
          priority={priority}
          quality={90}
          className="object-cover object-top"
          sizes="(max-width: 640px) 58vw, (max-width: 1024px) 220px, 240px"
        />
      </div>
    </div>
  );
}
