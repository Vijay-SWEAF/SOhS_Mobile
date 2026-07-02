import { GOLD, HAIRLINE, MUTED, PAPER, TEAL } from "../lib/theme";
import type { ThinkContent } from "../lib/questions";

/* Signature panel: "How to think about this" — fact / opinion / watch-for. */

interface RowProps {
  tag: string;
  tagColor: string;
  text: string;
}

function Row({ tag, tagColor, text }: RowProps) {
  return (
    <div className="flex gap-3">
      <span
        className="shrink-0 mt-0.5"
        style={{ fontSize: 9.5, letterSpacing: "0.12em", fontWeight: 700, color: tagColor, minWidth: 62 }}
      >
        {tag}
      </span>
      <span style={{ fontSize: 13.5, lineHeight: 1.5, color: "#C7CFE2" }}>{text}</span>
    </div>
  );
}

interface ThinkPanelProps {
  think: ThinkContent;
}

export default function ThinkPanel({ think }: ThinkPanelProps) {
  return (
    <div
      className="mt-5 rounded-2xl overflow-hidden"
      style={{
        background: "linear-gradient(180deg, rgba(228,185,104,0.06), rgba(255,255,255,0.025))",
        border: `1px solid ${HAIRLINE}`,
        backdropFilter: "blur(14px)",
        animation: "riseIn .6s cubic-bezier(.2,.8,.2,1) both",
      }}
    >
      <div className="px-5 pt-5 pb-2 flex items-center gap-2">
        <div style={{ width: 6, height: 6, borderRadius: "50%", background: GOLD }} />
        <p style={{ fontSize: 10.5, letterSpacing: "0.26em", color: GOLD, fontWeight: 600 }}>
          HOW TO THINK ABOUT THIS
        </p>
      </div>
      <div className="px-5 pb-5 flex flex-col gap-3.5">
        <Row tag="FACT" tagColor={PAPER} text={think.fact} />
        <Row tag="OPINION" tagColor={TEAL} text={think.opinion} />
        <Row tag="WATCH FOR" tagColor={GOLD} text={think.watch} />
      </div>
      <div
        className="px-5 py-3.5"
        style={{ borderTop: `1px solid ${HAIRLINE}`, background: "rgba(255,255,255,0.02)" }}
      >
        <span style={{ fontSize: 12, color: MUTED }}>
          Read the full discussion on <span style={{ color: GOLD, fontWeight: 500 }}>SOhS →</span>
        </span>
      </div>
    </div>
  );
}
