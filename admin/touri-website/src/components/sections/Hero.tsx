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
        className="hero-orb max-sm:opacity-70"
        style={{
          width: "min(380px, 70vw)",
          height: "min(380px, 70vw)",
          background: "var(--hero-glow)",
          top: -40,
          insetInlineStart: -60,
        }}
      />
      <div
        className="hero-orb gold max-sm:opacity-60"
        style={{
          width: "min(280px, 55vw)",
          height: "min(280px, 55vw)",
          background: "var(--hero-gold)",
          top: 80,
          insetInlineEnd: 8,
        }}
      />
      <div
        className="hero-orb max-sm:hidden"
        style={{
          width: 220,
          height: 220,
          background: "var(--hero-red)",
          bottom: 40,
          insetInlineStart: "38%",
        }}
      />

      <div className="relative mx-auto grid max-w-7xl items-center gap-8 px-4 py-10 sm:gap-12 sm:px-6 sm:py-16 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          className="min-w-0"
        >
          <p className="mb-3 max-w-xl text-base font-semibold leading-relaxed tracking-normal text-accent sm:mb-5 sm:text-xl lg:text-2xl lg:leading-relaxed">
            {dict.hero.eyebrow}
          </p>
          <h1 className="font-display max-w-xl text-[1.85rem] leading-[1.3] font-black tracking-normal text-white sm:text-5xl sm:leading-[1.22] md:text-6xl">
            {dict.hero.title}
          </h1>
          <p className="mt-3 max-w-xl text-base leading-7 text-white/78 sm:mt-5 sm:text-lg sm:leading-8">
            {dict.hero.subtitle}
          </p>
          <div className="mt-6 flex flex-col gap-2.5 sm:mt-8 sm:flex-row sm:flex-wrap sm:gap-3">
            <a href="#customer" className="btn-primary w-full sm:w-auto">
              {dict.hero.discover}
            </a>
            <a
              href="#driver"
              className="btn-secondary w-full border-white/20 text-white hover:bg-white/10 sm:w-auto"
            >
              {dict.hero.joinDriver}
            </a>
          </div>
          <div id="download" className="mt-4 sm:mt-6">
            <DownloadOpenButton
              dict={dict}
              className="btn-primary w-full border border-white/15 bg-white text-[#0a2b24] hover:bg-accent-soft sm:w-auto"
            >
              {dict.nav.download}
            </DownloadOpenButton>
          </div>
        </motion.div>

        <div className="relative mx-auto flex w-full max-w-[16rem] items-end justify-center overflow-visible pt-2 pb-1 sm:max-w-md sm:pt-6 sm:pb-2">
          <PhoneMockup
            className="absolute start-0 top-0 z-10 hidden translate-y-6 -rotate-6 sm:block lg:start-2"
            float={reduce ? "none" : "slower"}
            size="sm"
            src="/images/screenshots/customer/landmarks-jeddah-list.png"
            alt={dict.screens.items[1].alt}
          />
          <PhoneMockup
            className="relative z-20 sm:translate-x-6 sm:rotate-2 lg:translate-x-10"
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
