"use client";

import type { Dictionary } from "@/i18n/get-dictionary";
import { DownloadOpenButton, DownloadStoreGrid } from "@/components/ui/DownloadChooser";
import { Reveal } from "@/components/ui/Reveal";

type Props = {
  dict: Dictionary;
};

export function CTA({ dict }: Props) {
  return (
    <section className="px-4 py-10 sm:px-6">
      <Reveal>
        <div className="relative mx-auto max-w-7xl overflow-hidden rounded-[2rem] bg-gradient-to-br from-[#0a2b24] via-[#1f6f5f] to-[#c4a35a] px-6 py-16 text-white sm:px-12">
          <div className="pointer-events-none absolute -end-10 -top-10 h-56 w-56 rounded-full bg-white/10 blur-3xl" />
          <div className="relative grid gap-8 lg:grid-cols-[0.95fr_1.05fr] lg:items-end">
            <div className="max-w-xl">
              <h2 className="font-display text-3xl leading-[1.35] font-bold tracking-normal sm:text-5xl sm:leading-[1.25]">
                {dict.cta.title}
              </h2>
              <p className="mt-4 text-lg leading-8 text-white/80">{dict.cta.subtitle}</p>
              <DownloadOpenButton
                dict={dict}
                className="btn-primary mt-8 border border-white/20 bg-white text-[#0a2b24] hover:bg-accent-soft"
              >
                {dict.nav.download}
              </DownloadOpenButton>
            </div>
            <div className="rounded-[1.5rem] border border-white/15 bg-[#071512]/35 p-4 backdrop-blur-md sm:p-5">
              <DownloadStoreGrid dict={dict} />
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
