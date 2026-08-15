import { notFound } from "next/navigation";
import { CustomerShowcase, DriverShowcase } from "@/components/sections/AppShowcase";
import { AppScreens } from "@/components/sections/AppScreens";
import { Contact } from "@/components/sections/Contact";
import { CTA } from "@/components/sections/CTA";
import { FAQ } from "@/components/sections/FAQ";
import { Features } from "@/components/sections/Features";
import { Hero } from "@/components/sections/Hero";
import { HowItWorks } from "@/components/sections/HowItWorks";
import { Stats } from "@/components/sections/Stats";
import { Trust } from "@/components/sections/Trust";
import { JsonLd } from "@/components/seo/JsonLd";
import { isLocale } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";

export default async function HomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  const dict = getDictionary(locale);

  return (
    <>
      <JsonLd locale={locale} dict={dict} />
      <Hero dict={dict} />
      <Stats dict={dict} />
      <CustomerShowcase dict={dict} />
      <DriverShowcase dict={dict} />
      <HowItWorks dict={dict} />
      <Features dict={dict} />
      <Trust dict={dict} />
      <AppScreens dict={dict} />
      <FAQ dict={dict} />
      <CTA dict={dict} />
      <Contact dict={dict} />
    </>
  );
}
