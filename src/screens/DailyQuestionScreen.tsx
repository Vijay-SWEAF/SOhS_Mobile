import { GOLD, HAIRLINE, MUTED, PAPER } from "../lib/theme";

/* Phase 1 placeholder: proves the pipeline (Vite → Tailwind → bundled fonts
   → Capacitor WebView). The full question/reveal choreography lands in Phase 2. */
export default function DailyQuestionScreen() {
  return (
    <div className="min-h-screen w-full flex justify-center bg-ink font-sans">
      <div className="w-full relative flex flex-col px-6 pt-7 pb-10" style={{ maxWidth: 430 }}>
        {/* brand bar */}
        <div className="flex items-center justify-between">
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
            DAY 1
          </span>
        </div>

        <div className="flex-1 flex flex-col items-center justify-center gap-5">
          <p
            className="text-center"
            style={{ color: GOLD, fontSize: 10.5, letterSpacing: "0.32em", fontWeight: 600 }}
          >
            ONE HUMAN QUESTION A DAY
          </p>
          <p className="font-serif text-center" style={{ fontSize: 33, lineHeight: 1.24, color: PAPER }}>
            Think clearly.
            <br />
            Discuss respectfully.
            <br />
            Act humanly.
          </p>
          <p className="text-center" style={{ color: MUTED, fontSize: 14 }}>
            The first question arrives in Phase 2.
          </p>
        </div>
      </div>
    </div>
  );
}
