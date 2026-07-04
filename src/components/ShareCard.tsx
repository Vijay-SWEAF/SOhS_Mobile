import { forwardRef } from "react";
import { FAINT, FONT_SERIF, GOLD, HAIRLINE, INK, INK_2, MUTED, PAPER } from "../lib/theme";
import type { DailyQuestion, OptionIndex } from "../lib/questions";
import { getShareBadge } from "../lib/shareBadge";
import sohsAppIconUrl from "../assets/sohs-app-icon.png";

/* The story-ready 4:5 result card shown before exporting a generated PNG. */

export interface ShareCardProps {
  question: DailyQuestion;
  choice: OptionIndex;
  accent: string;
  isMajority: boolean;
}

const ShareCard = forwardRef<HTMLDivElement, ShareCardProps>(function ShareCard(
  { question, choice, accent, isMajority },
  ref,
) {
  const chosen = question.options[choice];
  const badge = getShareBadge(chosen.pct, isMajority);
  return (
    <div
      ref={ref}
      className="w-full rounded-2xl p-7 flex flex-col"
      style={{
        maxWidth: 340,
        aspectRatio: "4 / 5",
        background: `linear-gradient(165deg, ${INK_2}, ${INK} 62%)`,
        border: `1px solid ${GOLD}55`,
        boxShadow: "0 0 80px rgba(228,185,104,0.08)",
        animation: "riseIn .4s cubic-bezier(.2,.8,.2,1) both",
      }}
      onClick={(e) => e.stopPropagation()}
    >
      <p style={{ fontSize: 9, letterSpacing: "0.28em", color: GOLD, fontWeight: 600 }}>
        SOhS · {question.kind} · DAY {question.day}
      </p>
      <p className="mt-5" style={{ fontFamily: FONT_SERIF, fontSize: 21, lineHeight: 1.32, color: PAPER }}>
        {question.text}
      </p>
      <div
        className="mt-7 px-4 py-3"
        style={{
          borderRadius: 10,
          border: `1px solid ${HAIRLINE}`,
          background: "rgba(255,255,255,0.035)",
          boxShadow: `inset 0 0 0 1px ${accent}12`,
        }}
      >
        <div className="flex items-center justify-between gap-3">
          <span style={{ fontSize: 8.5, letterSpacing: "0.22em", color: accent, fontWeight: 700 }}>
            {badge.eyebrow}
          </span>
          <span style={{ fontSize: 9.5, color: MUTED, fontWeight: 700 }}>{chosen.label.toUpperCase()}</span>
        </div>
        <p className="mt-2" style={{ fontFamily: FONT_SERIF, color: PAPER, fontSize: 18, lineHeight: 1.2 }}>
          {badge.title}
        </p>
        <p className="mt-1.5" style={{ color: MUTED, fontSize: 10.5, lineHeight: 1.35 }}>
          {badge.detail}
        </p>
      </div>
      <p
        className="mt-auto"
        style={{ fontFamily: FONT_SERIF, fontSize: 34, lineHeight: 1.1, color: accent, fontWeight: 500 }}
      >
        {isMajority ? `With the ${chosen.pct}%.` : `The rarer ${chosen.pct}%.`}
      </p>
      <div
        className="w-full mt-4 rounded-full overflow-hidden flex"
        style={{ height: 8, background: "rgba(255,255,255,0.06)" }}
      >
        <div style={{ width: `${question.options[0].pct}%`, background: choice === 0 ? accent : "#2C3550" }} />
        <div style={{ flex: 1, background: choice === 1 ? accent : "#2C3550" }} />
      </div>
      <div className="flex items-center justify-between gap-3 mt-4">
        <span className="flex min-w-0 items-center gap-2" style={{ fontSize: 10.5, color: FAINT, fontWeight: 700 }}>
          <img
            src={sohsAppIconUrl}
            alt=""
            className="shrink-0 rounded-full"
            style={{ width: 26, height: 26, border: `1px solid ${GOLD}55` }}
          />
          <span>SOhS</span>
        </span>
        <span style={{ fontSize: 10.5, color: MUTED, fontWeight: 600 }}>societyofhomosapiens.org</span>
      </div>
    </div>
  );
});

export default ShareCard;
