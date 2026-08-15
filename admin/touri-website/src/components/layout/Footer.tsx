import Image from "next/image";
import Link from "next/link";
import { siteConfig } from "@/config/site";
import type { Locale } from "@/i18n/config";
import { localePath } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";
import { phoneDisplay, telHref, whatsappHref } from "@/lib/contact";

type Props = {
  locale: Locale;
  dict: Dictionary;
};

export function Footer({ locale, dict }: Props) {
  const social = [
    { href: siteConfig.social.instagram, label: "Instagram" },
    { href: siteConfig.social.twitter, label: "X" },
    { href: siteConfig.social.linkedin, label: "LinkedIn" },
    { href: siteConfig.social.snapchat, label: "Snapchat" },
  ].filter((item) => item.href);

  const links = [
    { href: localePath(locale, "/"), label: dict.nav.home },
    { href: localePath(locale, "/about"), label: dict.footer.about },
    { href: `${localePath(locale, "/")}#customer`, label: dict.footer.customer },
    { href: `${localePath(locale, "/")}#driver`, label: dict.footer.driver },
    { href: localePath(locale, "/privacy"), label: dict.footer.privacy },
    { href: localePath(locale, "/terms"), label: dict.footer.terms },
    { href: localePath(locale, "/support"), label: dict.footer.support },
  ];

  const phone = siteConfig.contact.phone.trim();
  const email = siteConfig.contact.email.trim();
  const wa = whatsappHref(siteConfig.contact.whatsapp.trim() || phone);

  return (
    <footer className="mt-0 border-t border-white/10 bg-footer text-white">
      <div className="mx-auto grid max-w-7xl gap-10 px-4 pt-12 pb-14 sm:px-6 lg:grid-cols-[1.3fr_1fr_1fr]">
        <div>
          <Image
            src="/images/logo.png"
            alt={dict.a11y.logo}
            width={160}
            height={56}
            className="h-12 w-auto"
            style={{ width: "auto" }}
          />
          <p className="mt-4 max-w-sm text-sm leading-7 text-pretty text-white/70">
            {dict.footer.tagline}
          </p>
        </div>
        <div>
          <p className="mb-4 text-sm font-bold tracking-wide uppercase text-accent">
            Touri
          </p>
          <ul className="grid gap-2 text-sm text-white/80">
            {links.map((item) => (
              <li key={item.href}>
                <Link className="hover:text-white" href={item.href}>
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <p className="mb-4 text-sm font-bold tracking-wide uppercase text-accent">
            {dict.nav.contact}
          </p>
          <ul className="grid gap-2.5 text-sm leading-6 text-white/80">
            {phone ? (
              <li>
                <a
                  href={telHref(phone)}
                  className="hover:text-white"
                  dir="ltr"
                  style={{ unicodeBidi: "isolate" }}
                >
                  {phoneDisplay(phone)}
                </a>
              </li>
            ) : null}
            {email ? (
              <li>
                <a
                  href={`mailto:${email}`}
                  className="hover:text-white"
                  dir="ltr"
                  style={{ unicodeBidi: "isolate" }}
                >
                  {email}
                </a>
              </li>
            ) : null}
            {wa ? (
              <li>
                <a
                  href={wa}
                  className="hover:text-white"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  WhatsApp
                </a>
              </li>
            ) : null}
          </ul>
          {social.length > 0 ? (
            <ul className="mt-4 flex gap-3">
              {social.map((item) => (
                <li key={item.label}>
                  <a
                    href={item.href}
                    className="text-sm font-semibold text-white/80 hover:text-white"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {item.label}
                  </a>
                </li>
              ))}
            </ul>
          ) : null}
        </div>
      </div>
      <div className="border-t border-white/10 px-4 py-5 text-center text-sm text-white/55">
        {dict.footer.copyright} · {dict.footer.rights}
      </div>
    </footer>
  );
}
