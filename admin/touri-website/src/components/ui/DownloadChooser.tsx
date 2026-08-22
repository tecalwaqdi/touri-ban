"use client";

import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { siteConfig, hasStoreLink } from "@/config/site";
import type { Dictionary } from "@/i18n/get-dictionary";
import { DOWNLOAD_OPEN_EVENT, openDownloadChooser } from "@/lib/download";
import { cn } from "@/lib/utils";

type AppKind = "customer" | "driver";

function AppleGlyph({ className }: { className?: string }) {
  return (
    <svg
      width="18"
      height="22"
      viewBox="0 0 18 22"
      aria-hidden="true"
      className={className}
    >
      <path
        fill="currentColor"
        d="M14.7 11.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.2-2.8.9-3.5.9s-1.8-0.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.3 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2.1-1.1 2.8-2.2c.9-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.4-3.9ZM12.2 4.7c.6-.8 1.1-1.8.9-2.9-0.9.1-2 .6-2.6 1.4-.6.7-1.1 1.8-.9 2.8 1 .1 2-.5 2.6-1.3Z"
      />
    </svg>
  );
}

function PlayGlyph({ className }: { className?: string }) {
  return (
    <svg
      width="18"
      height="20"
      viewBox="0 0 18 20"
      aria-hidden="true"
      className={className}
    >
      <path
        fill="currentColor"
        d="M1 1.6v16.8l9.4-8.4L1 1.6Zm10.3 9.3 2.2 1.2L4.2 18.8l7.1-6Zm2.2-3.4-2.2 1.2-7.1-6 9.3 4.8ZM16.4 9.1c.5.3.8.7.8 1.2s-.3.9-.8 1.2l-2.6 1.5-2.4-1.4 2.4-1.3 2.6-1.2Z"
      />
    </svg>
  );
}

function StoreBadge({
  href,
  store,
  caption,
  available,
  soonLabel,
  compact = false,
}: {
  href: string;
  store: "apple" | "play";
  caption: string;
  available: boolean;
  soonLabel: string;
  compact?: boolean;
}) {
  const isApple = store === "apple";
  const label = isApple ? "App Store" : "Google Play";
  const content = (
    <>
      <span
        className={cn(
          "flex shrink-0 items-center justify-center rounded-lg transition-transform duration-300 group-hover:scale-[1.03]",
          compact ? "h-8 w-8" : "h-11 w-11 rounded-xl",
          isApple ? "bg-white text-black" : "bg-[#01875f] text-white",
        )}
      >
        {isApple ? (
          <AppleGlyph className={compact ? "h-4 w-3.5" : undefined} />
        ) : (
          <PlayGlyph className={compact ? "h-4 w-3.5" : undefined} />
        )}
      </span>
      <span className="min-w-0 flex-1 text-start">
        <span
          className={cn(
            "block tracking-wide text-white/65",
            compact ? "text-[9px] leading-3" : "text-[10px] leading-4",
          )}
        >
          {available ? caption : soonLabel}
        </span>
        <span
          className={cn(
            "block font-semibold tracking-tight text-white",
            compact ? "text-[13px] leading-4" : "text-[15px] leading-5",
          )}
        >
          {label}
        </span>
      </span>
    </>
  );

  const className = cn(
    "group relative flex w-full items-center overflow-hidden border transition duration-300",
    "border-white/12 bg-[#0c1210]",
    compact
      ? "gap-2 rounded-xl px-2.5 py-2 shadow-[0_6px_18px_rgba(0,0,0,0.22)]"
      : "gap-3 rounded-2xl px-3.5 py-3 shadow-[0_10px_30px_rgba(0,0,0,0.28)]",
    available
      ? "hover:-translate-y-0.5 hover:border-accent/45 hover:bg-[#151c19] hover:shadow-[0_10px_24px_rgba(0,0,0,0.28)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
      : "cursor-not-allowed opacity-55",
  );

  if (!available) {
    return (
      <span className={className} aria-disabled="true">
        {content}
      </span>
    );
  }

  return (
    <a
      className={className}
      href={href}
      target="_blank"
      rel="noopener noreferrer"
    >
      <span
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-accent/70 to-transparent opacity-80"
        aria-hidden
      />
      {content}
    </a>
  );
}

function AppStoreRow({
  dict,
  app,
  compact = false,
}: {
  dict: Dictionary;
  app: AppKind;
  compact?: boolean;
}) {
  const links = siteConfig.store[app];
  const appleOk = hasStoreLink(links.appStore);
  const playOk = hasStoreLink(links.playStore);
  const title =
    app === "customer" ? dict.download.customerApp : dict.download.driverApp;
  const blurb =
    app === "customer"
      ? dict.download.customerBlurb
      : dict.download.driverBlurb;

  return (
    <section
      className={cn(
        "group/card relative overflow-hidden border transition duration-300",
        compact
          ? "rounded-xl p-3 hover:-translate-y-0.5 hover:shadow-[0_10px_28px_rgba(10,43,36,0.12)]"
          : "rounded-[1.25rem] p-3.5 sm:rounded-[1.5rem] sm:p-5",
        app === "customer"
          ? "border-primary/25 bg-gradient-to-br from-primary/15 via-surface to-surface hover:border-primary/40"
          : "border-accent/30 bg-gradient-to-br from-accent/15 via-surface to-surface hover:border-accent/45",
      )}
    >
      <div
        className={cn(
          "pointer-events-none absolute -end-8 -top-10 rounded-full blur-2xl transition-opacity duration-300 group-hover/card:opacity-90",
          compact ? "h-20 w-20" : "h-28 w-28",
          app === "customer" ? "bg-primary/25" : "bg-accent/30",
        )}
        aria-hidden
      />
      <div className="relative min-w-0">
        <p
          className={cn(
            "font-bold tracking-[0.14em] text-muted uppercase",
            compact ? "text-[10px]" : "text-[11px] sm:text-xs",
          )}
        >
          {app === "customer" ? "01" : "02"} · {title}
        </p>
        <h3
          className={cn(
            "font-display font-bold text-foreground",
            compact ? "mt-0.5 text-sm sm:text-[15px]" : "mt-1 text-base sm:text-xl",
          )}
        >
          {app === "customer" ? siteConfig.customerApp : siteConfig.driverApp}
        </h3>
        <p
          className={cn(
            "max-w-md text-muted",
            compact
              ? "mt-0.5 text-[11px] leading-4 sm:text-xs sm:leading-5"
              : "mt-1 text-xs leading-5 sm:mt-1.5 sm:text-sm sm:leading-6",
          )}
        >
          {blurb}
        </p>
        <div
          className={cn(
            "grid gap-2",
            compact ? "mt-2.5 sm:grid-cols-2" : "mt-3 sm:mt-4 sm:grid-cols-2 sm:gap-2.5",
          )}
        >
          <StoreBadge
            store="apple"
            href={links.appStore}
            caption={dict.download.onApple}
            available={appleOk}
            soonLabel={dict.download.soon}
            compact={compact}
          />
          <StoreBadge
            store="play"
            href={links.playStore}
            caption={dict.download.onGoogle}
            available={playOk}
            soonLabel={dict.download.soon}
            compact={compact}
          />
        </div>
      </div>
    </section>
  );
}

/** Inline grid used in Hero / CTA sections. */
export function DownloadStoreGrid({
  dict,
  className,
  density = "default",
}: {
  dict: Dictionary;
  className?: string;
  density?: "default" | "compact";
}) {
  const compact = density === "compact";
  return (
    <div className={cn("grid", compact ? "gap-2.5" : "gap-4", className)}>
      <AppStoreRow dict={dict} app="customer" compact={compact} />
      <AppStoreRow dict={dict} app="driver" compact={compact} />
    </div>
  );
}

/** Global modal opened by Navbar / Hero download CTAs. */
export function DownloadChooserHost({ dict }: { dict: Dictionary }) {
  const [open, setOpen] = useState(false);
  const titleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const onOpen = () => setOpen(true);
    window.addEventListener(DOWNLOAD_OPEN_EVENT, onOpen);
    return () => window.removeEventListener(DOWNLOAD_OPEN_EVENT, onOpen);
  }, []);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[80] flex items-end justify-center p-0 sm:items-center sm:p-6">
      <button
        type="button"
        className="absolute inset-0 bg-[#071512]/72 backdrop-blur-md"
        aria-label={dict.download.close}
        onClick={() => setOpen(false)}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative z-[81] flex max-h-[92vh] w-full max-w-xl flex-col overflow-hidden rounded-t-[1.5rem] border border-border bg-background shadow-soft sm:rounded-[1.75rem]"
      >
        <div className="relative overflow-hidden border-b border-border px-4 pt-4 pb-3.5 sm:px-6 sm:pt-5 sm:pb-4">
          <div
            className="pointer-events-none absolute inset-0 bg-gradient-to-br from-primary/20 via-transparent to-accent/15"
            aria-hidden
          />
          <div className="relative flex items-start justify-between gap-3 sm:gap-4">
            <div className="min-w-0">
              <p className="text-xs font-bold tracking-[0.16em] text-accent uppercase">
                Touri
              </p>
              <h2
                id={titleId}
                className="font-display mt-1 text-xl font-black tracking-normal text-foreground sm:text-2xl"
              >
                {dict.download.chooserTitle}
              </h2>
              <p className="mt-1 max-w-sm text-sm leading-6 text-muted sm:mt-1.5">
                {dict.download.chooserSubtitle}
              </p>
            </div>
            <button
              ref={closeRef}
              type="button"
              onClick={() => setOpen(false)}
              className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border text-foreground transition hover:bg-surface-muted sm:h-10 sm:w-10"
              aria-label={dict.download.close}
            >
              <span aria-hidden className="text-lg leading-none">
                ×
              </span>
            </button>
          </div>
        </div>
        <div className="overflow-y-auto px-4 py-4 sm:px-6 sm:py-5">
          <DownloadStoreGrid dict={dict} />
        </div>
      </div>
    </div>
  );
}

export function DownloadOpenButton({
  dict,
  className,
  children,
}: {
  dict: Dictionary;
  className?: string;
  children?: ReactNode;
}) {
  return (
    <button type="button" className={className} onClick={openDownloadChooser}>
      {children ?? dict.nav.download}
    </button>
  );
}
