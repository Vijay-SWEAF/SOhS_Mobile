import { useEffect, useState } from "react";
import { getAppVersionInfo } from "../lib/appInfo";
import { GOLD, HAIRLINE, MUTED, PAPER } from "../lib/theme";

interface BrandBarProps {
  day: number;
}

export default function BrandBar({ day }: BrandBarProps) {
  const [versionLabel, setVersionLabel] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    void getAppVersionInfo().then((info) => {
      if (!cancelled) {
        setVersionLabel(info?.label ?? null);
      }
    });

    return () => {
      cancelled = true;
    };
  }, []);

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
      <div className="flex flex-col items-end gap-1">
        <span
          className="px-2.5 py-1 rounded-full"
          style={{ fontSize: 10, letterSpacing: "0.14em", color: MUTED, border: `1px solid ${HAIRLINE}` }}
        >
          DAY {day}
        </span>
        {versionLabel && (
          <span
            className="px-2 py-0.5 rounded-full"
            style={{ fontSize: 9, letterSpacing: "0.08em", color: MUTED, border: `1px solid ${HAIRLINE}` }}
          >
            {versionLabel}
          </span>
        )}
      </div>
    </div>
  );
}
