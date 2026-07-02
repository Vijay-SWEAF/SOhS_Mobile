import { HAIRLINE, MUTED } from "../lib/theme";
import ShareCard, { type ShareCardProps } from "./ShareCard";

interface ShareCardOverlayProps extends ShareCardProps {
  onClose: () => void;
}

export default function ShareCardOverlay({ onClose, ...cardProps }: ShareCardOverlayProps) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center px-7"
      style={{ background: "rgba(6,9,18,0.88)", backdropFilter: "blur(6px)", animation: "fadeIn .25s ease both" }}
      onClick={onClose}
    >
      <ShareCard {...cardProps} />
      <button
        onClick={onClose}
        className="absolute bottom-8 px-6 py-2.5 rounded-full"
        style={{
          color: MUTED,
          fontSize: 13,
          border: `1px solid ${HAIRLINE}`,
          background: "rgba(255,255,255,0.03)",
        }}
      >
        Close · story-ready 4:5
      </button>
    </div>
  );
}
