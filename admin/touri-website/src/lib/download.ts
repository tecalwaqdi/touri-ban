/** Opens the global download chooser modal (Navbar / Hero / CTA). */
export const DOWNLOAD_OPEN_EVENT = "touri:open-download";

export function openDownloadChooser() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(DOWNLOAD_OPEN_EVENT));
}
