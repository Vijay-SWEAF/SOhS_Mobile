import { forwardRef } from "react";
import { FAINT, FONT_SERIF, GOLD, INK, INK_2, MUTED, PAPER } from "../lib/theme";
import type { DailyQuestion, OptionIndex } from "../lib/questions";

/* The story-ready 4:5 result card. Kept as its own component (with a
   forwarded ref) so Phase 5 can rasterize exactly this node to PNG. */

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
      <div className="flex items-center justify-between mt-4">
        <span style={{ fontSize: 10.5, color: FAINT }}>Think clearly. Discuss respectfully.</span>
        <span style={{ fontSize: 10.5, color: MUTED, fontWeight: 600 }}>societyofhomosapiens.org</span>
      </div>
    </div>
  );
});

export default ShareCard;
