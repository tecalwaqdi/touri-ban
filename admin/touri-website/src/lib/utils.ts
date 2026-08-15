export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}

export function swapLocalePath(pathname: string, nextLocale: string) {
  const parts = pathname.split("/");
  if (parts.length > 1) {
    parts[1] = nextLocale;
    return parts.join("/") || `/${nextLocale}`;
  }
  return `/${nextLocale}`;
}
