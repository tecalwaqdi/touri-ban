"use client";

import { FormEvent, useMemo, useState } from "react";
import type { Dictionary } from "@/i18n/get-dictionary";
import { IconMail, IconPhone, IconWhatsApp } from "@/components/icons";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { contactChannels, whatsappHref } from "@/lib/contact";
import { siteConfig } from "@/config/site";
import { cn } from "@/lib/utils";

type Props = {
  dict: Dictionary;
};

type ChannelCard = {
  key: string;
  icon: typeof IconPhone;
  label: string;
  value: string;
  href: string;
  external?: boolean;
  ltrValue?: boolean;
  tone?: "default" | "whatsapp";
};

export function Contact({ dict }: Props) {
  const [status, setStatus] = useState("");
  const channels = useMemo(() => contactChannels(), []);

  const cards = useMemo(() => {
    const list: ChannelCard[] = [];

    if (channels.phone) {
      list.push({
        key: "phone",
        icon: IconPhone,
        label: dict.contact.phone,
        value: channels.phone.display,
        href: channels.phone.tel,
        ltrValue: true,
      });
    }

    if (channels.whatsapp?.href) {
      list.push({
        key: "whatsapp",
        icon: IconWhatsApp,
        label: dict.contact.whatsapp,
        value: channels.whatsapp.display || "WhatsApp",
        href: channels.whatsapp.href,
        external: true,
        ltrValue: Boolean(channels.whatsapp.display),
        tone: "whatsapp",
      });
    }

    if (channels.email) {
      list.push({
        key: "email",
        icon: IconMail,
        label: dict.contact.email,
        value: channels.email.display,
        href: channels.email.href,
        ltrValue: true,
      });
    }

    return list;
  }, [channels, dict]);

  const hasChannel = cards.length > 0;

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const name = String(data.get("name") || "");
    const email = String(data.get("email") || "");
    const message = String(data.get("message") || "");
    const body = `${name} · ${email}\n\n${message}`;

    if (siteConfig.contact.email.trim()) {
      window.location.href = `mailto:${siteConfig.contact.email.trim()}?subject=${encodeURIComponent("Touri")}&body=${encodeURIComponent(body)}`;
      setStatus(dict.contact.sent);
      return;
    }

    const wa = whatsappHref(
      siteConfig.contact.whatsapp.trim() || siteConfig.contact.phone.trim(),
    );
    if (wa) {
      window.open(
        `${wa}?text=${encodeURIComponent(body)}`,
        "_blank",
        "noopener,noreferrer",
      );
      setStatus(dict.contact.sent);
      return;
    }

    setStatus(dict.contact.missing);
  }

  return (
    <section
      id="contact"
      className="px-4 pt-10 pb-8 sm:px-6 sm:pt-16 sm:pb-12"
    >
      <div className="mx-auto grid max-w-7xl items-start gap-7 lg:grid-cols-2 lg:gap-10">
        <div className="min-w-0">
          <SectionTitle
            eyebrow={dict.contact.eyebrow}
            title={dict.contact.title}
            subtitle={dict.contact.subtitle}
          />

          <ul className="mt-6 grid gap-2.5 sm:mt-7 sm:gap-3.5">
            {cards.map((item) => {
              const Icon = item.icon;
              return (
                <li key={item.key}>
                  <a
                    href={item.href}
                    className={cn(
                      "premium-card group flex min-h-[4.25rem] items-center gap-3 p-3.5 sm:min-h-[4.5rem] sm:gap-4 sm:px-5 sm:py-4",
                      "transition-colors hover:border-primary/30",
                    )}
                    target={item.external ? "_blank" : undefined}
                    rel={item.external ? "noopener noreferrer" : undefined}
                    aria-label={`${item.label}: ${item.value}`}
                  >
                    <span
                      className={cn(
                        "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition-transform duration-300 group-hover:-translate-y-0.5 sm:h-11 sm:w-11 sm:rounded-2xl",
                        item.tone === "whatsapp"
                          ? "bg-[color-mix(in_srgb,#25D366_16%,white)] text-[#128C7E] dark:bg-[color-mix(in_srgb,#25D366_22%,transparent)] dark:text-[#25D366]"
                          : "bg-[color-mix(in_srgb,var(--primary)_12%,white)] text-primary dark:bg-[color-mix(in_srgb,var(--primary)_18%,transparent)]",
                      )}
                    >
                      <Icon size={20} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-xs leading-5 font-medium text-muted">
                        {item.label}
                      </span>
                      <span
                        className="mt-0.5 block text-[15px] leading-snug font-semibold tracking-normal text-foreground sm:text-base"
                        dir={item.ltrValue ? "ltr" : undefined}
                        style={
                          item.ltrValue
                            ? { unicodeBidi: "isolate" }
                            : undefined
                        }
                      >
                        {item.value}
                      </span>
                    </span>
                  </a>
                </li>
              );
            })}
          </ul>

          <p className="mt-4 max-w-md text-sm leading-7 text-muted">
            {dict.contact.inApp}
          </p>
        </div>

        <form
          className="premium-card flex min-w-0 flex-col gap-4 p-4 sm:gap-5 sm:p-7"
          onSubmit={onSubmit}
          noValidate={false}
        >
          <div className="grid gap-4 sm:grid-cols-2 sm:gap-4">
            <label className="block min-w-0 text-sm font-semibold text-foreground">
              <span className="mb-2 block leading-5">{dict.contact.name}</span>
              <input
                required
                name="name"
                autoComplete="name"
                className="w-full rounded-2xl border border-border bg-background px-3.5 py-2.5 text-start text-[15px] leading-6 text-foreground outline-none transition placeholder:text-muted/70 focus:border-primary focus:ring-2 focus:ring-primary/20 sm:px-4 sm:py-3"
                placeholder={dict.contact.placeholderName}
              />
            </label>
            <label className="block min-w-0 text-sm font-semibold text-foreground">
              <span className="mb-2 block leading-5">{dict.contact.email}</span>
              <input
                required
                type="email"
                name="email"
                autoComplete="email"
                dir="ltr"
                className="w-full rounded-2xl border border-border bg-background px-3.5 py-2.5 text-start text-[15px] leading-6 text-foreground outline-none transition placeholder:text-muted/70 focus:border-primary focus:ring-2 focus:ring-primary/20 sm:px-4 sm:py-3"
                placeholder={dict.contact.placeholderEmail}
                style={{ unicodeBidi: "isolate" }}
              />
            </label>
          </div>

          <label className="block min-w-0 text-sm font-semibold text-foreground">
            <span className="mb-2 block leading-5">{dict.contact.message}</span>
            <textarea
              required
              name="message"
              rows={4}
              className="min-h-[7.5rem] w-full resize-y rounded-2xl border border-border bg-background px-3.5 py-2.5 text-start text-[15px] leading-7 text-foreground outline-none transition placeholder:text-muted/70 focus:border-primary focus:ring-2 focus:ring-primary/20 sm:min-h-[8.5rem] sm:px-4 sm:py-3"
              placeholder={dict.contact.placeholderMessage}
            />
          </label>

          <div className="mt-1 flex flex-col gap-3">
            <button
              type="submit"
              className="btn-primary w-full sm:w-auto sm:min-w-[10.5rem] sm:self-start"
              disabled={!hasChannel}
            >
              {dict.contact.send}
            </button>
            {status ? (
              <p className="text-sm leading-6 text-muted" role="status">
                {status}
              </p>
            ) : null}
          </div>
        </form>
      </div>
    </section>
  );
}
