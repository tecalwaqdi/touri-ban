"use client";

import Image from "next/image";
import { motion, useReducedMotion } from "framer-motion";

type Props = {
  src: string;
  name: string;
  city: string;
  blurb: string;
  /** CSS object-position for best landmark framing inside 4/5 crop */
  objectPosition?: string;
  blurDataURL?: string;
  priority?: boolean;
};

export function DestinationCard({
  src,
  name,
  city,
  blurb,
  objectPosition = "center",
  blurDataURL,
  priority = false,
}: Props) {
  const reduce = useReducedMotion();

  return (
    <motion.article
      variants={{
        hidden: { opacity: 0, y: reduce ? 0 : 14 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={reduce ? undefined : { y: -5 }}
      transition={{ duration: 0.32, ease: [0.22, 1, 0.36, 1] }}
      className="group flex h-full flex-col overflow-hidden rounded-2xl border border-border/80 bg-surface shadow-[0_6px_20px_rgba(10,43,36,0.05)] ring-1 ring-black/[0.02] transition-[box-shadow,border-color] duration-300 hover:border-primary/25 hover:shadow-[0_14px_36px_rgba(10,43,36,0.12)]"
    >
      <div className="relative aspect-[4/5] shrink-0 overflow-hidden bg-surface-muted">
        <Image
          src={src}
          alt={`${name} — ${city}`}
          fill
          priority={priority}
          quality={90}
          placeholder={blurDataURL ? "blur" : "empty"}
          blurDataURL={blurDataURL}
          className="object-cover transition-transform duration-700 ease-out will-change-transform group-hover:scale-[1.04] motion-reduce:transition-none motion-reduce:group-hover:scale-100"
          style={{ objectPosition }}
          sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, (max-width: 1280px) 20vw, 240px"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/45 via-transparent to-transparent opacity-70"
        />
      </div>
      <div className="flex min-h-0 flex-1 flex-col gap-1 px-3 py-3 sm:px-3.5 sm:py-3.5">
        <p className="text-[10px] font-semibold tracking-[0.12em] text-muted uppercase rtl:tracking-normal">
          {city}
        </p>
        <h3 className="text-[13px] leading-snug font-bold tracking-normal text-foreground sm:text-sm sm:leading-snug">
          {name}
        </h3>
        <p className="mt-0.5 text-[11px] leading-5 text-muted sm:text-xs sm:leading-5">
          {blurb}
        </p>
      </div>
    </motion.article>
  );
}
