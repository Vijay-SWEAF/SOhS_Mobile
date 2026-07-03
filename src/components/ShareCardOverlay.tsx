import { useState } from "react";
import { HAIRLINE, MUTED } from "../lib/theme";
import { shareResultPng } from "../lib/shareExport";
import ShareCard, { type ShareCardProps } from "./ShareCard";

interface ShareCardOverlayProps extends ShareCardProps {
  onClose: () => void;
}

export default function ShareCardOverlay({ onClose, ...cardProps }: ShareCardOverlayProps) {
  const [sharing, setSharing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const share = async (event: React.MouseEvent<HTMLButtonElement>): Promise<void> => {
    event.stopPropagation();
    try {
      setSharing(true);
      setError(null);
      await shareResultPng(cardProps);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to share right now.");
    } finally {
      setSharing(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center px-7"
      style={{ background: "rgba(6,9,18,0.88)", backdropFilter: "blur(6px)", animation: "fadeIn .25s ease both" }}
      onClick={onClose}
    >
      <ShareCard {...cardProps} />
      <div className="absolute bottom-8 flex flex-col items-center gap-3">
        {error && (
          <span style={{ color: MUTED, fontSize: 12.5, maxWidth: 280, textAlign: "center" }}>{error}</span>
        )}
        <div className="flex gap-2">
          <button
            onClick={share}
            disabled={sharing}
            className="px-6 py-2.5 rounded-full"
            style={{
              color: "#12100A",
              fontSize: 13,
              fontWeight: 700,
              border: "1px solid #E4B968",
              background: "linear-gradient(135deg,#E4B968,#A9823A)",
              opacity: sharing ? 0.7 : 1,
            }}
          >
            {sharing ? "Preparing…" : "Share PNG"}
          </button>
          <button
            onClick={(event) => {
              event.stopPropagation();
              onClose();
            }}
            className="px-6 py-2.5 rounded-full"
            style={{
              color: MUTED,
              fontSize: 13,
              border: `1px solid ${HAIRLINE}`,
              background: "rgba(255,255,255,0.03)",
            }}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
