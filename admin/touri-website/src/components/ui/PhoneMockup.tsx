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

const sizeClass = {
  md: "w-[clamp(12rem,42vw,15rem)]",
  sm: "w-[clamp(10.75rem,36vw,13.25rem)]",
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
        "phone-frame relative",
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
          sizes="(max-width: 640px) 42vw, (max-width: 1024px) 220px, 240px"
        />
      </div>
    </div>
  );
}
