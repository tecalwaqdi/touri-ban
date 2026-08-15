import { getSiteUrl, siteConfig } from "@/config/site";
import type { Locale } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";

type Props = {
  locale: Locale;
  dict: Dictionary;
};

export function JsonLd({ locale, dict }: Props) {
  const url = getSiteUrl();
  const data = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        name: siteConfig.legalName,
        url,
        logo: `${url}/images/logo.png`,
        sameAs: Object.values(siteConfig.social).filter(Boolean),
      },
      {
        "@type": "SoftwareApplication",
        name: siteConfig.customerApp,
        applicationCategory: "TravelApplication",
        operatingSystem: "iOS, Android",
        offers: { "@type": "Offer", price: "0", priceCurrency: "SAR" },
        description: dict.meta.homeDescription,
      },
      {
        "@type": "SoftwareApplication",
        name: siteConfig.driverApp,
        applicationCategory: "BusinessApplication",
        operatingSystem: "iOS, Android",
        offers: { "@type": "Offer", price: "0", priceCurrency: "SAR" },
        description: dict.driver.subtitle,
      },
      {
        "@type": "FAQPage",
        inLanguage: locale,
        mainEntity: dict.faq.items.map((item) => ({
          "@type": "Question",
          name: item.q,
          acceptedAnswer: { "@type": "Answer", text: item.a },
        })),
      },
    ],
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}
