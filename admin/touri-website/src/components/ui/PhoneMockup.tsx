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

/** Medium balanced widths — same look as before, tuned size only. */
const sizeClass = {
  md: "w-[min(13.5rem,52vw)] sm:w-[13.75rem] lg:w-[14.25rem]",
  sm: "w-[min(11.75rem,44vw)] sm:w-[12rem] lg:w-[12.5rem]",
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
    >
      {/*
        Bezel = CSS padding on .phone-frame.
        Aspect lives on the screen so Next/Image fill always has a real box,
        and the screenshot cannot paint into the frame ring.
      */}
      <div
        className="phone-screen relative w-full overflow-hidden"
        style={{ aspectRatio: "1206 / 2622" }}
      >
        <Image
          src={src}
          alt={alt}
          fill
          priority={priority}
          quality={90}
          className="object-cover object-top"
          sizes="(max-width: 640px) 52vw, (max-width: 1024px) 220px, 228px"
        />
      </div>
    </div>
  );
}
