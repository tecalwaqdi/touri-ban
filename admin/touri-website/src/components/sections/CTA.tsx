"use client";

import type { Dictionary } from "@/i18n/get-dictionary";
import { DownloadOpenButton, DownloadStoreGrid } from "@/components/ui/DownloadChooser";
import { Reveal } from "@/components/ui/Reveal";

type Props = {
  dict: Dictionary;
};

export function CTA({ dict }: Props) {
  return (
    <section className="px-4 py-8 sm:px-6 sm:py-10">
      <Reveal>
        <div className="relative mx-auto max-w-7xl overflow-hidden rounded-[1.5rem] bg-gradient-to-br from-[#0a2b24] via-[#1f6f5f] to-[#c4a35a] px-4 py-10 text-white sm:rounded-[2rem] sm:px-12 sm:py-16">
          <div className="pointer-events-none absolute -end-10 -top-10 h-56 w-56 rounded-full bg-white/10 blur-3xl" />
          <div className="relative grid gap-6 lg:grid-cols-[0.95fr_1.05fr] lg:items-end lg:gap-8">
            <div className="max-w-xl min-w-0">
              <h2 className="font-display text-[1.65rem] leading-[1.35] font-bold tracking-normal sm:text-4xl sm:leading-[1.25] md:text-5xl">
                {dict.cta.title}
              </h2>
              <p className="mt-3 text-base leading-7 text-white/80 sm:mt-4 sm:text-lg sm:leading-8">
                {dict.cta.subtitle}
              </p>
              <DownloadOpenButton
                dict={dict}
                className="btn-primary mt-6 w-full border border-white/20 bg-white text-[#0a2b24] hover:bg-accent-soft sm:mt-8 sm:w-auto"
              >
                {dict.nav.download}
              </DownloadOpenButton>
            </div>
            <div className="min-w-0 rounded-[1.25rem] border border-white/15 bg-[#071512]/35 p-3 backdrop-blur-md sm:rounded-[1.5rem] sm:p-5">
              <DownloadStoreGrid dict={dict} />
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
