import { Browser } from "@capacitor/browser";

const SOHS_WEBSITE_ORIGIN = (
  (import.meta.env.VITE_SOHS_WEBSITE_ORIGIN as string | undefined) ?? "https://www.societyofhomosapiens.org"
).replace(/\/+$/, "");

const STATIC_SITE_PATHS = new Set([
  "/about/",
  "/privacy/",
  "/terms/",
  "/support/",
  "/correction-policy/",
  "/questions/",
]);

export function questionDiscussionUrl(slug: string): string {
  return `${SOHS_WEBSITE_ORIGIN}/questions/${encodeURIComponent(slug)}/`;
}

export function discussionPathUrl(path: string): string | null {
  if (!/^\/(questions|dilemmas)\/[a-z0-9-]+\/$/.test(path)) return null;
  return `${SOHS_WEBSITE_ORIGIN}${path}`;
}

export function websitePageUrl(path: string): string | null {
  const normalizedPath = path.endsWith("/") ? path : `${path}/`;
  if (!STATIC_SITE_PATHS.has(normalizedPath)) return null;
  return `${SOHS_WEBSITE_ORIGIN}${normalizedPath}`;
}

export async function openWebsiteUrl(url: string): Promise<void> {
  try {
    await Browser.open({ url });
  } catch {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}

export const openDiscussion = openWebsiteUrl;
