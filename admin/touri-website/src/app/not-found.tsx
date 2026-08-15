import Link from "next/link";
import { defaultLocale, localeDir, localePath } from "@/i18n/config";
import { getDictionary } from "@/i18n/get-dictionary";

export default function NotFound() {
  const dict = getDictionary(defaultLocale);
  const dir = localeDir(defaultLocale);

  return (
    <html lang={defaultLocale} dir={dir}>
      <body className="flex min-h-screen items-center justify-center bg-[#f6f3ec] p-6 text-[#121a18]">
        <div className="max-w-md text-center">
          <p className="text-sm font-bold tracking-[0.2em] text-[#1f6f5f] uppercase">
            Touri
          </p>
          <h1 className="mt-3 text-4xl font-bold">{dict.notFound.title}</h1>
          <p className="mt-3 text-[#4a5854]">{dict.notFound.body}</p>
          <Link
            href={localePath(defaultLocale, "/")}
            className="mt-6 inline-flex rounded-full bg-[#1f6f5f] px-5 py-3 font-bold text-white"
          >
            {dict.legal.back}
          </Link>
        </div>
      </body>
    </html>
  );
}
