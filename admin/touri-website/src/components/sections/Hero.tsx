"use client";

import Image from "next/image";
import { motion, useReducedMotion } from "framer-motion";
import type { Dictionary } from "@/i18n/get-dictionary";
import { DownloadOpenButton } from "@/components/ui/DownloadChooser";
import { PhoneMockup } from "@/components/ui/PhoneMockup";

type Props = {
  dict: Dictionary;
};

export function Hero({ dict }: Props) {
  const reduce = useReducedMotion();

  return (
    <section className="relative overflow-hidden">
      <div className="absolute inset-0">
        <Image
          src="/images/landmarks/jeddah_new_corniche.png"
          alt=""
          fill
          priority
          loading="eager"
          className="object-cover opacity-25"
          sizes="100vw"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-[#071512]/80 via-[#0a2b24]/70 to-background" />
      </div>
      <div
        className="hero-orb"
        style={{
          width: 380,
          height: 380,
          background: "var(--hero-glow)",
          top: -40,
          insetInlineStart: -60,
        }}
      />
      <div
        className="hero-orb gold"
        style={{
          width: 280,
          height: 280,
          background: "var(--hero-gold)",
          top: 80,
          insetInlineEnd: 8,
        }}
      />
      <div
        className="hero-orb"
        style={{
          width: 220,
          height: 220,
          background: "var(--hero-red)",
          bottom: 40,
          insetInlineStart: "38%",
        }}
      />

      <div className="relative mx-auto grid max-w-7xl items-center gap-10 px-4 py-16 sm:gap-12 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
        >
          <p className="mb-5 max-w-xl text-lg font-semibold leading-relaxed tracking-normal text-accent sm:text-xl lg:text-2xl lg:leading-relaxed">
            {dict.hero.eyebrow}
          </p>
          <h1 className="font-display max-w-xl text-4xl leading-[1.3] font-black tracking-normal text-white sm:text-6xl sm:leading-[1.22]">
            {dict.hero.title}
          </h1>
          <p className="mt-5 max-w-xl text-lg leading-8 text-white/78 sm:leading-8">
            {dict.hero.subtitle}
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <a href="#customer" className="btn-primary">
              {dict.hero.discover}
            </a>
            <a
              href="#driver"
              className="btn-secondary border-white/20 text-white hover:bg-white/10"
            >
              {dict.hero.joinDriver}
            </a>
          </div>
          <div id="download" className="mt-8">
            <DownloadOpenButton
              dict={dict}
              className="btn-primary border border-white/15 bg-white text-[#0a2b24] hover:bg-accent-soft"
            >
              {dict.nav.download}
            </DownloadOpenButton>
          </div>
        </motion.div>

        <div className="relative mx-auto flex w-full max-w-md items-end justify-center pt-4 pb-2 sm:pt-6">
          <PhoneMockup
            className="absolute start-0 top-0 z-10 hidden translate-y-6 -rotate-6 sm:block lg:start-2"
            float={reduce ? "none" : "slower"}
            size="sm"
            src="/images/screenshots/customer/landmarks-jeddah-list.png"
            alt={dict.screens.items[1].alt}
          />
          <PhoneMockup
            className="relative z-20 translate-x-1 rotate-2 sm:translate-x-6 lg:translate-x-10"
            float={reduce ? "none" : "slow"}
            size="md"
            priority
            src="/images/screenshots/customer/booking-trip-type.png"
            alt={dict.hero.customerApp}
          />
        </div>
      </div>
    </section>
  );
}
