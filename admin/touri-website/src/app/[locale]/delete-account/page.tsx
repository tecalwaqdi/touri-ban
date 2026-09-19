import Link from "next/link";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { DeleteAccountForm } from "@/components/legal/DeleteAccountForm";
import { siteConfig } from "@/config/site";
import { isLocale, localePath } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";
import { buildMetadata } from "@/lib/metadata";
import { contactChannels } from "@/lib/contact";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  if (!isLocale(locale)) return {};
  const dict = getDictionary(locale);
  return buildMetadata({
    locale,
    dict,
    title: dict.meta.deleteAccountTitle,
    description: dict.meta.deleteAccountDescription,
    path: "/delete-account",
  });
}

export default async function DeleteAccountPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  const dict = getDictionary(locale);
  const d = dict.deleteAccount;
  const channels = contactChannels();

  return (
    <article className="mx-auto max-w-3xl px-4 py-10 sm:px-6 sm:py-16">
      <Link href={localePath(locale, "/")} className="text-sm font-semibold text-primary">
        {dict.legal.back}
      </Link>

      <p className="mt-6 text-sm font-semibold tracking-wide text-primary">{d.brandLine}</p>
      <p className="mt-1 text-sm text-muted">{d.legalEntity}</p>
      <p className="mt-1 text-sm text-muted">{d.apps}</p>

      <h1 className="font-display mt-4 text-[1.85rem] leading-[1.3] font-bold sm:text-4xl">
        {d.title}
      </h1>
      <p className="mt-4 text-base leading-7 text-muted sm:text-lg sm:leading-8">{d.intro}</p>

      <section className="premium-card mt-8 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.inAppTitle}</h2>
        <ol className="mt-3 list-decimal space-y-2 ps-5 text-sm leading-7 text-muted">
          {d.inAppSteps.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>

      <section className="premium-card mt-5 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.webTitle}</h2>
        <ol className="mt-3 list-decimal space-y-2 ps-5 text-sm leading-7 text-muted">
          {d.webSteps.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>

      <section className="premium-card mt-5 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.deletedTitle}</h2>
        <ul className="mt-3 list-disc space-y-2 ps-5 text-sm leading-7 text-muted">
          {d.deletedBullets.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>

      <section className="premium-card mt-5 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.retainedTitle}</h2>
        <ul className="mt-3 list-disc space-y-2 ps-5 text-sm leading-7 text-muted">
          {d.retainedBullets.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
        <h3 className="mt-5 text-base font-bold">{d.retainedPurposesTitle}</h3>
        <ul className="mt-3 list-disc space-y-2 ps-5 text-sm leading-7 text-muted">
          {d.retainedPurposes.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>

      <section className="premium-card mt-5 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.contactTitle}</h2>
        <ul className="mt-3 space-y-2 text-sm leading-7 text-muted">
          {channels.phone ? (
            <li>
              <a className="font-semibold text-primary" href={channels.phone.tel}>
                {channels.phone.display}
              </a>
            </li>
          ) : null}
          {channels.whatsapp ? (
            <li>
              <a className="font-semibold text-primary" href={channels.whatsapp.href}>
                WhatsApp
              </a>
            </li>
          ) : null}
          {channels.email ? (
            <li>
              <a className="font-semibold text-primary" href={channels.email.href}>
                {channels.email.display}
              </a>
            </li>
          ) : (
            <li>info@touri-taxi.com</li>
          )}
        </ul>
        <p className="mt-3 text-sm text-muted">
          <Link className="font-semibold text-primary" href={localePath(locale, "/privacy")}>
            {d.privacyLink}
          </Link>
          {" · "}
          <Link className="font-semibold text-primary" href={localePath(locale, "/support")}>
            {d.supportLink}
          </Link>
        </p>
        <p className="mt-2 text-xs text-muted">{siteConfig.legalName}</p>
      </section>

      <section className="premium-card mt-5 p-4 sm:p-6">
        <h2 className="text-lg font-bold sm:text-xl">{d.formTitle}</h2>
        <div className="mt-4">
          <DeleteAccountForm locale={locale} dict={dict} />
        </div>
      </section>
    </article>
  );
}
