import { GOLD, HAIRLINE, MUTED, PAPER } from "../lib/theme";

interface BrandBarProps {
  day: number;
}

export default function BrandBar({ day }: BrandBarProps) {
  return (
    <div className="flex items-center justify-between relative">
      <div className="flex items-center gap-2.5">
        <div
          style={{
            width: 9,
            height: 9,
            borderRadius: "50%",
            background: GOLD,
            boxShadow: `0 0 14px ${GOLD}`,
          }}
        />
        <span style={{ color: PAPER, fontSize: 13, fontWeight: 600, letterSpacing: "0.02em" }}>
          Society Of <span style={{ color: GOLD }}>homo</span>Sapiens
        </span>
      </div>
      <span
        className="px-2.5 py-1 rounded-full"
        style={{ fontSize: 10, letterSpacing: "0.14em", color: MUTED, border: `1px solid ${HAIRLINE}` }}
      >
        DAY {day}
      </span>
    </div>
  );
}
