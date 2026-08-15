"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import type { Locale } from "@/i18n/config";
import { localePath } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";
import {
  IconClose,
  IconMenu,
  IconMoon,
  IconSun,
} from "@/components/icons";
import { openDownloadChooser } from "@/lib/download";
import { cn, swapLocalePath } from "@/lib/utils";

type Props = {
  locale: Locale;
  dict: Dictionary;
};

const SECTION_IDS = [
  "customer",
  "driver",
  "features",
  "how",
  "safety",
  "faq",
  "contact",
  "download",
] as const;

type SectionId = (typeof SECTION_IDS)[number];

function scrollToSection(id: string) {
  const el = document.getElementById(id);
  if (!el) return false;
  el.scrollIntoView({ behavior: "smooth", block: "start" });
  window.history.pushState(null, "", `#${id}`);
  return true;
}

function scrollToSectionWhenReady(id: string, attempt = 0) {
  if (scrollToSection(id) || attempt >= 30) return;
  window.setTimeout(() => scrollToSectionWhenReady(id, attempt + 1), 50);
}

export function Navbar({ locale, dict }: Props) {
  const pathname = usePathname();
  const router = useRouter();
  const headerRef = useRef<HTMLElement>(null);
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const [activeId, setActiveId] = useState<SectionId | "">("");
  const other = locale === "ar" ? "en" : "ar";
  const home = localePath(locale, "/");
  const isHome = pathname === home;

  const sectionLinks = useMemo(
    () => [
      { id: "customer" as const, label: dict.nav.customer },
      { id: "driver" as const, label: dict.nav.driver },
      { id: "features" as const, label: dict.nav.features },
      { id: "how" as const, label: dict.nav.how },
      { id: "safety" as const, label: dict.nav.safety },
      { id: "faq" as const, label: dict.nav.faq },
      { id: "contact" as const, label: dict.nav.contact },
    ],
    [dict],
  );

  useEffect(() => {
    const header = headerRef.current;
    if (!header) return;

    const syncNavHeight = () => {
      document.documentElement.style.setProperty(
        "--nav-height",
        `${header.offsetHeight}px`,
      );
    };

    syncNavHeight();
    const observer = new ResizeObserver(syncNavHeight);
    observer.observe(header);
    return () => observer.disconnect();
  }, [open]);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    if (!isHome) return;

    if ("scrollRestoration" in window.history) {
      window.history.scrollRestoration = "manual";
    }

    const pending = sessionStorage.getItem("touri-scroll-to");
    if (pending) {
      sessionStorage.removeItem("touri-scroll-to");
      scrollToSectionWhenReady(pending);
    } else {
      // Open / refresh home at the hero — ignore leftover hashes from earlier browsing.
      if (window.location.hash) {
        window.history.replaceState(
          null,
          "",
          `${window.location.pathname}${window.location.search}`,
        );
      }
      window.scrollTo({ top: 0, left: 0, behavior: "instant" });
    }

    const onScroll = () => {
      const offset =
        Number.parseFloat(
          getComputedStyle(document.documentElement).getPropertyValue("--nav-height"),
        ) || headerRef.current?.offsetHeight || 76;

      let current: SectionId | "" = "";
      for (const id of SECTION_IDS) {
        if (id === "download") continue;
        const el = document.getElementById(id);
        if (!el) continue;
        if (el.getBoundingClientRect().top - offset <= 12) {
          current = id;
        }
      }
      setActiveId(current);
    };

    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }, [isHome]);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  function toggleTheme() {
    const next = !document.documentElement.classList.contains("dark");
    document.documentElement.classList.toggle("dark", next);
    localStorage.setItem("touri-theme", next ? "dark" : "light");
  }

  function goToSection(id: SectionId) {
    setOpen(false);
    if (isHome) {
      scrollToSection(id);
      return;
    }
    sessionStorage.setItem("touri-scroll-to", id);
    router.push(home);
  }

  const currentId = isHome ? activeId : "";

  const linkClass = (id: SectionId) =>
    cn(
      "shrink-0 whitespace-nowrap rounded-full px-2.5 py-2 text-[13px] leading-snug font-semibold transition xl:px-3 xl:text-sm",
      currentId === id
        ? "bg-primary/10 text-primary"
        : "text-foreground/80 hover:bg-surface-muted hover:text-foreground",
    );

  return (
    <header
      ref={headerRef}
      className={cn(
        "sticky top-0 z-50 border-b transition-shadow duration-300",
        "border-border/70 bg-[color-mix(in_srgb,var(--background)_88%,transparent)] backdrop-blur-xl",
        scrolled || open
          ? "shadow-[0_8px_30px_rgba(10,43,36,0.08)]"
          : "shadow-none",
      )}
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-3 lg:px-6">
        <Link href={home} className="shrink-0" aria-label={dict.a11y.logo}>
          <Image
            src="/images/logo.png"
            alt={dict.a11y.logo}
            width={148}
            height={52}
            className="h-10 w-auto"
            style={{ width: "auto" }}
            priority
          />
        </Link>

        <nav className="hidden max-w-[min(100%,42rem)] flex-wrap items-center justify-center gap-0.5 xl:max-w-none lg:flex" aria-label={dict.a11y.nav}>
          {sectionLinks.map((item) => (
            <a
              key={item.id}
              href={`${home}#${item.id}`}
              className={linkClass(item.id)}
              aria-current={currentId === item.id ? "true" : undefined}
              onClick={(event) => {
                event.preventDefault();
                goToSection(item.id);
              }}
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <Link
            href={swapLocalePath(pathname, other)}
            className="rounded-full border border-border px-3 py-1.5 text-xs font-bold tracking-wide text-foreground transition hover:bg-surface-muted"
            hrefLang={other}
            aria-label={dict.nav.language}
            onClick={() => {
              document.cookie = `TOURI_LOCALE=${other}; path=/; max-age=31536000; samesite=lax`;
            }}
          >
            {other === "ar" ? "AR" : "EN"}
          </Link>
          <button
            type="button"
            onClick={toggleTheme}
            className="inline-flex items-center justify-center rounded-full border border-border p-2.5 text-foreground transition hover:bg-surface-muted"
            aria-label={`${dict.nav.themeLight} / ${dict.nav.themeDark}`}
          >
            <IconSun size={16} className="hidden dark:block" />
            <IconMoon size={16} className="dark:hidden" />
          </button>
          <button
            type="button"
            className="btn-primary hidden px-4 py-2 text-sm sm:inline-flex"
            onClick={() => openDownloadChooser()}
          >
            {dict.nav.download}
          </button>
          <button
            type="button"
            className="inline-flex items-center justify-center rounded-full border border-border p-2.5 text-foreground transition hover:bg-surface-muted lg:hidden"
            aria-expanded={open}
            aria-controls="mobile-nav"
            aria-label={open ? dict.nav.close : dict.nav.menu}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <IconClose size={18} /> : <IconMenu size={18} />}
          </button>
        </div>
      </div>

      {open ? (
        <div
          id="mobile-nav"
          className="border-t border-border bg-background/95 px-4 py-4 backdrop-blur-xl lg:hidden"
        >
          <nav className="grid gap-1" aria-label={dict.a11y.nav}>
            <Link
              href={home}
              className="rounded-2xl px-3 py-3 text-base font-semibold text-foreground hover:bg-surface-muted"
              onClick={() => setOpen(false)}
            >
              {dict.nav.home}
            </Link>
            {sectionLinks.map((item) => (
              <a
                key={item.id}
                href={`${home}#${item.id}`}
                className={cn(
                  "rounded-2xl px-3 py-3 text-base font-semibold transition",
                  currentId === item.id
                    ? "bg-primary/10 text-primary"
                    : "text-foreground hover:bg-surface-muted",
                )}
                aria-current={currentId === item.id ? "true" : undefined}
                onClick={(event) => {
                  event.preventDefault();
                  goToSection(item.id);
                }}
              >
                {item.label}
              </a>
            ))}
            <button
              type="button"
              className="btn-primary mt-2 w-full"
              onClick={() => {
                setOpen(false);
                openDownloadChooser();
              }}
            >
              {dict.nav.download}
            </button>
          </nav>
        </div>
      ) : null}
    </header>
  );
}
