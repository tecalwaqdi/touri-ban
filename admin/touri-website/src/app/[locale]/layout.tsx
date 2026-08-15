import type { Metadata, Viewport } from "next";
import { Cairo, Plus_Jakarta_Sans } from "next/font/google";
import { notFound } from "next/navigation";
import { Footer } from "@/components/layout/Footer";
import { Navbar } from "@/components/layout/Navbar";
import { ThemeScript } from "@/components/theme/ThemeScript";
import { HomeScrollScript } from "@/components/theme/HomeScrollScript";
import { DownloadChooserHost } from "@/components/ui/DownloadChooser";
import { siteConfig } from "@/config/site";
import { isLocale, localeDir, locales, type Locale } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";
import { buildMetadata } from "@/lib/metadata";

const cairo = Cairo({
  subsets: ["arabic", "latin"],
  variable: "--font-cairo",
  display: "swap",
});

const display = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-display",
  display: "swap",
});

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f6f3ec" },
    { media: "(prefers-color-scheme: dark)", color: "#071512" },
  ],
  width: "device-width",
  initialScale: 1,
};

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale: raw } = await params;
  if (!isLocale(raw)) return {};
  const dict = getDictionary(raw);
  return buildMetadata({
    locale: raw,
    dict,
    title: dict.meta.homeTitle,
    description: dict.meta.homeDescription,
  });
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  const locale = raw as Locale;
  const dict = getDictionary(locale);
  const dir = localeDir(locale);

  return (
    <html
      lang={locale}
      dir={dir}
      data-scroll-behavior="smooth"
      className={`${cairo.variable} ${display.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full bg-background font-sans text-foreground">
        <ThemeScript />
        <HomeScrollScript />
        <a href="#content" className="skip-link">
          {dict.a11y.skip}
        </a>
        <Navbar locale={locale} dict={dict} />
        <main id="content" className="flex-1">
          {children}
        </main>
        <Footer locale={locale} dict={dict} />
        <DownloadChooserHost dict={dict} />
        <p className="sr-only">{siteConfig.name}</p>
      </body>
    </html>
  );
}
