"use client";

import { useCallback, useEffect, useRef, useState } from "react";

function readNavOffset() {
  const raw = getComputedStyle(document.documentElement).getPropertyValue(
    "--nav-height",
  );
  const parsed = Number.parseFloat(raw);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 76;
}

/**
 * Scroll-spy for sticky navbar section links.
 * Uses IntersectionObserver + a top activation line (nav height) with click lock
 * so smooth scrolling never flickers between neighbors.
 */
export function useActiveSection(
  sectionIds: readonly string[],
  enabled: boolean,
) {
  const idsKey = sectionIds.join(",");
  const [activeId, setActiveId] = useState(() => {
    if (typeof window === "undefined" || !enabled) return "";
    const id = window.location.hash.replace(/^#/, "");
    return sectionIds.includes(id) ? id : "";
  });
  const lockRef = useRef<string | null>(null);
  const unlockTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const intersectingRef = useRef<Map<string, number>>(new Map());

  const resolveActive = useCallback(() => {
    if (lockRef.current) {
      setActiveId((prev) => (prev === lockRef.current ? prev : lockRef.current!));
      return;
    }

    const ids = idsKey.split(",").filter(Boolean);
    const navOffset = readNavOffset();
    const activationY = navOffset + 4;

    // Prefer the last section whose top has crossed just below the sticky nav.
    // This is stable at boundaries and works with RTL/LTR (geometry-only).
    let current = "";
    for (const id of ids) {
      const el = document.getElementById(id);
      if (!el) continue;
      if (el.getBoundingClientRect().top <= activationY) {
        current = id;
      }
    }

    // Before the first section (hero): no nav highlight.
    const first = document.getElementById(ids[0] ?? "");
    if (first && first.getBoundingClientRect().top > activationY + 24) {
      current = "";
    }

    // Bottom of page: keep the last section active.
    const doc = document.documentElement;
    if (window.scrollY + window.innerHeight >= doc.scrollHeight - 8) {
      for (let i = ids.length - 1; i >= 0; i -= 1) {
        if (document.getElementById(ids[i]!)) {
          current = ids[i]!;
          break;
        }
      }
    }

    // If geometry is ambiguous, fall back to the strongest IO hit in the top band.
    if (!current) {
      let bestId = "";
      let bestRatio = 0;
      for (const id of ids) {
        const ratio = intersectingRef.current.get(id) ?? 0;
        if (ratio > bestRatio) {
          bestRatio = ratio;
          bestId = id;
        }
      }
      if (bestRatio > 0) current = bestId;
    }

    setActiveId((prev) => (prev === current ? prev : current));
  }, [idsKey]);

  const lockTo = useCallback(
    (id: string, ms = 1200) => {
      if (!idsKey.split(",").includes(id)) return;
      lockRef.current = id;
      setActiveId(id);
      if (unlockTimerRef.current) clearTimeout(unlockTimerRef.current);
      unlockTimerRef.current = setTimeout(() => {
        lockRef.current = null;
        resolveActive();
      }, ms);
    },
    [idsKey, resolveActive],
  );

  useEffect(() => {
    if (!enabled) {
      lockRef.current = null;
      return;
    }

    const ids = idsKey.split(",").filter(Boolean);
    let observer: IntersectionObserver | null = null;
    let raf = 0;

    const elements = () =>
      ids
        .map((id) => document.getElementById(id))
        .filter((el): el is HTMLElement => Boolean(el));

    const connect = () => {
      observer?.disconnect();
      const nodes = elements();
      if (nodes.length === 0) return;

      const nav = readNavOffset();
      // Top band under the navbar (~45% of viewport): reduces neighbor flicker.
      observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            intersectingRef.current.set(
              entry.target.id,
              entry.isIntersecting ? entry.intersectionRatio : 0,
            );
          }
          if (!lockRef.current) resolveActive();
        },
        {
          root: null,
          rootMargin: `-${nav}px 0px -55% 0px`,
          threshold: [0, 0.1, 0.25, 0.5, 0.75, 1],
        },
      );

      for (const el of nodes) observer.observe(el);
      resolveActive();
    };

    connect();
    // Sections may mount a tick later on the home page.
    const boot = window.setTimeout(connect, 80);

    const onScroll = () => {
      if (raf) return;
      raf = window.requestAnimationFrame(() => {
        raf = 0;
        if (!lockRef.current) resolveActive();
      });
    };

    const onHashChange = () => {
      const id = window.location.hash.replace(/^#/, "");
      if (ids.includes(id)) lockTo(id);
      else resolveActive();
    };

    const onScrollEnd = () => {
      if (lockRef.current) {
        // Release early once the smooth scroll settles.
        lockRef.current = null;
        if (unlockTimerRef.current) clearTimeout(unlockTimerRef.current);
      }
      resolveActive();
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", connect);
    window.addEventListener("hashchange", onHashChange);
    window.addEventListener("popstate", onHashChange);
    window.addEventListener("scrollend", onScrollEnd);

    const navEl = document.querySelector("header.sticky");
    const resizeObserver =
      navEl instanceof HTMLElement
        ? new ResizeObserver(() => connect())
        : null;
    if (navEl instanceof HTMLElement) resizeObserver?.observe(navEl);

    return () => {
      window.clearTimeout(boot);
      if (raf) window.cancelAnimationFrame(raf);
      observer?.disconnect();
      resizeObserver?.disconnect();
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", connect);
      window.removeEventListener("hashchange", onHashChange);
      window.removeEventListener("popstate", onHashChange);
      window.removeEventListener("scrollend", onScrollEnd);
      if (unlockTimerRef.current) clearTimeout(unlockTimerRef.current);
    };
  }, [enabled, idsKey, lockTo, resolveActive]);

  return { activeId, lockTo };
}
