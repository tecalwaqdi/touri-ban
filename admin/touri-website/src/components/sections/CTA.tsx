"use client";

import type { Dictionary } from "@/i18n/get-dictionary";
import { DownloadOpenButton, DownloadStoreGrid } from "@/components/ui/DownloadChooser";
import { Reveal } from "@/components/ui/Reveal";

type Props = {
  dict: Dictionary;
};

export function CTA({ dict }: Props) {
  return (
    <section className="px-4 py-5 sm:px-6 sm:py-7">
      <Reveal>
        <div className="relative mx-auto max-w-6xl overflow-hidden rounded-2xl bg-gradient-to-br from-[#0a2b24] via-[#1f6f5f] to-[#c4a35a] px-4 py-6 text-white shadow-[0_12px_40px_rgba(10,43,36,0.18)] sm:rounded-[1.35rem] sm:px-7 sm:py-7 lg:px-8">
          <div className="pointer-events-none absolute -end-8 -top-8 h-36 w-36 rounded-full bg-white/10 blur-3xl" />
          <div className="pointer-events-none absolute -start-6 bottom-0 h-28 w-28 rounded-full bg-accent/20 blur-3xl" />

          <div className="relative grid items-center gap-4 lg:grid-cols-[0.9fr_1.1fr] lg:gap-6">
            <div className="min-w-0 max-w-md">
              <h2 className="font-display text-xl leading-[1.35] font-bold tracking-normal sm:text-2xl sm:leading-[1.3] lg:text-[1.75rem]">
                {dict.cta.title}
              </h2>
              <p className="mt-2 text-sm leading-6 text-white/80 sm:text-[15px] sm:leading-7">
                {dict.cta.subtitle}
              </p>
              <DownloadOpenButton
                dict={dict}
                className="btn-primary mt-4 w-full border border-white/20 bg-white px-4 py-2.5 text-sm text-[#0a2b24] shadow-none transition hover:-translate-y-0.5 hover:bg-accent-soft sm:mt-5 sm:w-auto"
              >
                {dict.nav.download}
              </DownloadOpenButton>
            </div>

            <div className="min-w-0 rounded-xl border border-white/12 bg-[#071512]/30 p-2.5 backdrop-blur-md transition duration-300 sm:rounded-2xl sm:p-3">
              <DownloadStoreGrid dict={dict} density="compact" />
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
