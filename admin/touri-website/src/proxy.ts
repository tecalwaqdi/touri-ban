import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { defaultLocale, locales } from "@/i18n/config";

function getLocale(request: NextRequest) {
  const cookie = request.cookies.get("TOURI_LOCALE")?.value;
  if (cookie && locales.includes(cookie as (typeof locales)[number])) {
    return cookie;
  }
  const header = request.headers.get("accept-language") || "";
  if (header.toLowerCase().includes("ar")) return "ar";
  if (header.toLowerCase().includes("en")) return "en";
  return defaultLocale;
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasLocale = locales.some(
    (locale) => pathname === `/${locale}` || pathname.startsWith(`/${locale}/`),
  );
  if (hasLocale) return;

  const locale = getLocale(request);
  request.nextUrl.pathname = `/${locale}${pathname}`;
  return NextResponse.redirect(request.nextUrl);
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|_next/data|favicon.ico|images|icons|apple-touch-icon.png|.*\\..*).*)"],
};
