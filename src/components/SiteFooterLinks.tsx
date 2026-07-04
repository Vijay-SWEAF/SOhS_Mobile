import { openWebsiteUrl, websitePageUrl } from "../lib/discussionBridge";
import { GOLD, HAIRLINE, PAPER, RAISED } from "../lib/theme";

const SUPPORT_EMAIL = "sohs@societyofhomosapiens.org";

const links = [
  { label: "About", path: "/about/" },
  { label: "Privacy", path: "/privacy/" },
  { label: "Terms", path: "/terms/" },
  { label: "Support", path: "/support/" },
  { label: "Corrections", path: "/correction-policy/" },
] as const;

function openMail(): void {
  window.location.href = `mailto:${SUPPORT_EMAIL}?subject=SOhS%20Mobile%20feedback`;
}

export default function SiteFooterLinks() {
  return (
    <footer className="mt-8 pb-1 text-center" aria-label="SOhS app information">
      <div className="flex flex-wrap justify-center gap-2">
        {links.map((link) => {
          const url = websitePageUrl(link.path);
          return (
            <button
              key={link.path}
              type="button"
              onClick={() => {
                if (url) void openWebsiteUrl(url);
              }}
              className="px-3 py-2"
              style={{
                minHeight: 36,
                borderRadius: 8,
                border: `1px solid ${HAIRLINE}`,
                background: RAISED,
                color: PAPER,
                fontSize: 11.5,
                fontWeight: 650,
              }}
            >
              {link.label}
            </button>
          );
        })}
      </div>
      <button
        type="button"
        onClick={openMail}
        className="mt-3 px-3 py-2"
        style={{
          borderRadius: 8,
          border: `1px solid ${GOLD}45`,
          background: "transparent",
          color: GOLD,
          fontSize: 12,
          fontWeight: 650,
        }}
      >
        Bugs or suggestions: {SUPPORT_EMAIL}
      </button>
    </footer>
  );
}
