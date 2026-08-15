import { siteConfig, hasStoreLink } from "@/config/site";
import type { Dictionary } from "@/i18n/get-dictionary";
import { cn } from "@/lib/utils";

type AppKind = "customer" | "driver";

type Props = {
  dict: Dictionary;
  app?: AppKind;
  compact?: boolean;
  tone?: "default" | "onDark";
};

function badgeCaption(label: string, storeName: "App Store" | "Google Play") {
  const trimmed = label.replace(new RegExp(`\\s*${storeName}\\s*$`, "i"), "").trim();
  return trimmed || label;
}

function AppleBadge({ label }: { label: string }) {
  return (
    <span className="inline-flex max-w-full items-center gap-2.5">
      <svg width="18" height="22" viewBox="0 0 18 22" aria-hidden="true" className="shrink-0">
        <path
          fill="currentColor"
          d="M14.7 11.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.2-2.8.9-3.5.9s-1.8-0.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.3 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2.1-1.1 2.8-2.2c.9-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.4-3.9ZM12.2 4.7c.6-.8 1.1-1.8.9-2.9-0.9.1-2 .6-2.6 1.4-.6.7-1.1 1.8-.9 2.8 1 .1 2-.5 2.6-1.3Z"
        />
      </svg>
      <span className="flex min-w-0 flex-col leading-snug">
        <span className="text-[10px] leading-4 opacity-80">
          {badgeCaption(label, "App Store")}
        </span>
        <span className="text-sm leading-5 font-semibold">App Store</span>
      </span>
    </span>
  );
}

function PlayBadge({ label }: { label: string }) {
  return (
    <span className="inline-flex max-w-full items-center gap-2.5">
      <svg width="18" height="20" viewBox="0 0 18 20" aria-hidden="true" className="shrink-0">
        <path fill="currentColor" d="M1 1.6v16.8l9.4-8.4L1 1.6Zm10.3 9.3 2.2 1.2L4.2 18.8l7.1-6Zm2.2-3.4-2.2 1.2-7.1-6 9.3 4.8ZM16.4 9.1c.5.3.8.7.8 1.2s-.3.9-.8 1.2l-2.6 1.5-2.4-1.4 2.4-1.3 2.6-1.2Z" />
      </svg>
      <span className="flex min-w-0 flex-col leading-snug">
        <span className="text-[10px] leading-4 opacity-80">
          {badgeCaption(label, "Google Play")}
        </span>
        <span className="text-sm leading-5 font-semibold">Google Play</span>
      </span>
    </span>
  );
}

export function DownloadButtons({
  dict,
  app = "customer",
  compact = false,
  tone = "default",
}: Props) {
  const links = siteConfig.store[app];
  const appStore = hasStoreLink(links.appStore);
  const playStore = hasStoreLink(links.playStore);

  if (!appStore && !playStore) {
    return null;
  }

  const className = cn(
    "inline-flex max-w-full items-center rounded-xl border border-white/10 bg-[#111] px-3.5 py-2.5 text-white transition hover:bg-[#222]",
    compact ? "text-xs" : "text-sm",
  );

  return (
    <div className="flex flex-wrap gap-3">
      {appStore ? (
        <a className={className} href={links.appStore} target="_blank" rel="noopener noreferrer">
          <AppleBadge label={dict.download.appStore} />
        </a>
      ) : null}
      {playStore ? (
        <a className={className} href={links.playStore} target="_blank" rel="noopener noreferrer">
          <PlayBadge label={dict.download.playStore} />
        </a>
      ) : null}
    </div>
  );
}
