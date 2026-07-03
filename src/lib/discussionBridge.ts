import { Browser } from "@capacitor/browser";

const SOHS_WEBSITE_ORIGIN = (
  (import.meta.env.VITE_SOHS_WEBSITE_ORIGIN as string | undefined) ?? "https://www.societyofhomosapiens.org"
).replace(/\/+$/, "");

export function questionDiscussionUrl(slug: string): string {
  return `${SOHS_WEBSITE_ORIGIN}/questions/${encodeURIComponent(slug)}/`;
}

export function discussionPathUrl(path: string): string | null {
  if (!/^\/(questions|dilemmas)\/[a-z0-9-]+\/$/.test(path)) return null;
  return `${SOHS_WEBSITE_ORIGIN}${path}`;
}

export async function openDiscussion(url: string): Promise<void> {
  try {
    await Browser.open({ url });
  } catch {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}
