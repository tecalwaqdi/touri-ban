"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { Dictionary } from "@/i18n/get-dictionary";
import { DestinationCard } from "@/components/ui/DestinationCard";
import { destinationBlurs } from "@/components/sections/destination-blurs";

type Props = {
  dict: Dictionary;
};

const gallery = [
  {
    src: "/images/landmarks/explore_makkah_haram.jpg",
    key: "makkah" as const,
    // Keep Kaaba / courtyard centered in the tall crop
    objectPosition: "52% 45%",
  },
  {
    src: "/images/landmarks/explore_riyadh.jpg",
    key: "riyadh" as const,
    // Prefer Kingdom Centre + Faisaliyah in frame
    objectPosition: "48% 35%",
  },
  {
    src: "/images/landmarks/explore_jeddah_v2.jpg",
    key: "jeddah" as const,
    // Aerial corniche: mosque + tower
    objectPosition: "45% 55%",
  },
  {
    src: "/images/landmarks/explore_taif_v2.jpg",
    key: "taif" as const,
    // Shubra Palace facade centered
    objectPosition: "50% 40%",
  },
  {
    src: "/images/landmarks/explore_abha_v2.jpg",
    key: "abha" as const,
    // Soudah sea of clouds
    objectPosition: "40% 45%",
  },
] as const;

export function ExploreDestinations({ dict }: Props) {
  const reduce = useReducedMotion();

  return (
    <div>
      <header className="mx-auto max-w-2xl overflow-visible text-center">
        <p className="text-sm font-semibold tracking-[0.14em] text-primary uppercase rtl:tracking-normal">
          {dict.destinations.eyebrow}
        </p>
        <h2 className="font-display mt-2 text-[1.65rem] leading-[1.35] font-bold tracking-normal text-foreground sm:text-3xl sm:leading-[1.3] md:text-[2.05rem]">
          {dict.destinations.title}
        </h2>
        <p className="mx-auto mt-3 max-w-xl text-[14.5px] leading-7 text-muted sm:text-[15px] sm:leading-8">
          {dict.destinations.subtitle}
        </p>
      </header>

      <motion.ul
        className="mx-auto mt-8 grid max-w-5xl grid-cols-2 gap-2.5 sm:gap-3 md:grid-cols-3 lg:grid-cols-5 lg:gap-3"
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, amount: 0.15 }}
        variants={{
          hidden: {},
          show: {
            transition: {
              staggerChildren: reduce ? 0 : 0.07,
            },
          },
        }}
      >
        {gallery.map((item, index) => {
          const copy = dict.destinations.items[item.key];
          return (
            <li key={item.key} className="min-w-0">
              <DestinationCard
                src={item.src}
                name={copy.name}
                city={copy.city}
                blurb={copy.blurb}
                objectPosition={item.objectPosition}
                blurDataURL={destinationBlurs[item.key]}
                priority={index < 2}
              />
            </li>
          );
        })}
      </motion.ul>
    </div>
  );
}
