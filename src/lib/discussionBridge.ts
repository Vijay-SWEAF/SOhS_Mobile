import { Browser } from "@capacitor/browser";

const SOHS_WEBSITE_ORIGIN = (
  (import.meta.env.VITE_SOHS_WEBSITE_ORIGIN as string | undefined) ?? "https://www.societyofhomosapiens.org"
).replace(/\/+$/, "");

export function questionDiscussionUrl(slug: string): string {
  return `${SOHS_WEBSITE_ORIGIN}/questions/${encodeURIComponent(slug)}/`;
}

export async function openDiscussion(url: string): Promise<void> {
  try {
    await Browser.open({ url });
  } catch {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}
