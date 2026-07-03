import { Suspense, lazy, useCallback, useEffect, useRef, useState } from "react";
import BrandBar from "../components/BrandBar";
import ThinkPanel from "../components/ThinkPanel";
import ShareCardOverlay from "../components/ShareCardOverlay";
import { fmt, type OptionIndex } from "../lib/questions";
import { revealHaptic, tapHaptic } from "../lib/haptics";
import { useReducedMotion } from "../lib/useReducedMotion";
import { getDeviceId, getStoredVote, storeVote } from "../lib/device";
import { castVote, detectCountryCode, loadActiveQuestion, type LiveDailyQuestion } from "../lib/appQuestions";
import {
  FAINT,
  FONT_SERIF,
  GOLD,
  GOLD_DEEP,
  HAIRLINE,
  MUTED,
  PAPER,
  RAISED,
  TEAL,
  TEAL_DEEP,
} from "../lib/theme";

/* three.js is only fetched when the reveal reaches the globe */
const Globe = lazy(() => import("../components/Globe"));

type Stage = "question" | "tapped" | "unlocking" | "reveal";

export default function DailyQuestionScreen() {
  const [question, setQuestion] = useState<LiveDailyQuestion | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [stage, setStage] = useState<Stage>("question");
  const [choice, setChoice] = useState<OptionIndex | null>(null);
  const [counter, setCounter] = useState(0);
  const [rollA, setRollA] = useState(0);
  const [rollB, setRollB] = useState(0);
  const [barOn, setBarOn] = useState(false);
  const [showGlobe, setShowGlobe] = useState(false);
  const [showThink, setShowThink] = useState(false);
  const [showFooter, setShowFooter] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  const [voteNotice, setVoteNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const timers = useRef<number[]>([]);
  const rafRef = useRef<number | null>(null);
  const reduceMotion = useReducedMotion();

  const q = question;
  const chosen = q && choice !== null ? q.options[choice] : null;
  const other = q && choice !== null ? q.options[choice === 0 ? 1 : 0] : null;
  const isMajority = chosen !== null && other !== null && chosen.pct >= other.pct;
  const accent = isMajority ? GOLD : TEAL;
  const accentDeep = isMajority ? GOLD_DEEP : TEAL_DEEP;

  const later = useCallback((fn: () => void, ms: number): void => {
    const id = window.setTimeout(fn, ms);
    timers.current.push(id);
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadQuestion(): Promise<void> {
      try {
        setLoading(true);
        setError(null);
        const activeQuestion = await loadActiveQuestion();
        const storedChoice = await getStoredVote(activeQuestion.id);
        if (cancelled) return;

        setQuestion(activeQuestion);
        setCounter(activeQuestion.totalVotes);
        if (storedChoice !== null) {
          setChoice(storedChoice);
          setStage("reveal");
          setRollA(activeQuestion.options[0].pct);
          setRollB(activeQuestion.options[1].pct);
          setBarOn(true);
          setShowGlobe(true);
          setShowThink(true);
          setShowFooter(true);
          setVoteNotice("Your vote is already counted.");
        }
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : "Unable to load today's question.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void loadQuestion();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!q) return;
    setCounter(q.totalVotes);
  }, [q]);

  useEffect(
    () => () => {
      timers.current.forEach((id) => window.clearTimeout(id));
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    },
    [],
  );

  /* count-up of both percentages on reveal */
  useEffect(() => {
    if (stage !== "reveal" || choice === null || !q) return;
    const dur = reduceMotion ? 350 : 1300;
    const start = performance.now();
    const a = q.options[0].pct;
    const b = q.options[1].pct;
    const tick = (now: number): void => {
      const p = Math.min((now - start) / dur, 1);
      const e = 1 - Math.pow(1 - p, 3);
      setRollA(Math.round(a * e));
      setRollB(Math.round(b * e));
      if (p < 1) rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
  }, [stage, choice, q, reduceMotion]);

  const speed = reduceMotion ? 0.35 : 1;

  const reveal = useCallback((): void => {
    later(() => setStage("unlocking"), 680 * speed);
    later(() => {
      setStage("reveal");
      revealHaptic();
    }, (680 + 1150) * speed);
    later(() => setBarOn(true), (680 + 1150 + 250) * speed);
    later(() => setShowGlobe(true), (680 + 1150 + 700) * speed);
    later(() => setShowThink(true), (680 + 1150 + 1500) * speed);
    later(() => setShowFooter(true), (680 + 1150 + 2300) * speed);
  }, [later, speed]);

  const answer = async (idx: OptionIndex): Promise<void> => {
    if (stage !== "question" || !q || submitting) return;

    setChoice(idx);
    setStage("tapped");
    setSubmitting(true);
    setVoteNotice(null);
    setError(null);
    tapHaptic();

    try {
      const deviceId = await getDeviceId();
      const result = await castVote(q, deviceId, idx, detectCountryCode());
      await storeVote(q.id, idx);
      setQuestion(result.question);
      setCounter(result.question.totalVotes);
      setVoteNotice(result.alreadyVoted ? "Your vote was already counted." : "Your vote is counted.");
      reveal();
    } catch (err) {
      setChoice(null);
      setStage("question");
      setError(err instanceof Error ? err.message : "Unable to submit your vote.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen w-full flex items-center justify-center bg-ink font-sans px-8">
        <p style={{ color: MUTED, fontSize: 12.5, letterSpacing: "0.22em" }}>LOADING TODAY'S QUESTION…</p>
      </div>
    );
  }

  if (!q) {
    return (
      <div className="min-h-screen w-full flex items-center justify-center bg-ink font-sans px-8 text-center">
        <p style={{ color: MUTED, fontSize: 14, lineHeight: 1.5 }}>
          {error ?? "Today's question is not available yet."}
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full flex justify-center bg-ink font-sans">
      <div className="w-full relative flex flex-col px-6 pt-7 pb-10" style={{ maxWidth: 430 }}>
        {/* ambient top glow */}
        <div
          className="absolute pointer-events-none"
          style={{
            top: -80,
            left: "50%",
            width: 460,
            height: 300,
            background:
              "radial-gradient(ellipse 50% 50% at 50% 50%, rgba(228,185,104,0.10), transparent 70%)",
            animation: reduceMotion ? "none" : "driftGlow 7s ease-in-out infinite",
          }}
        />

        <BrandBar day={q.day} />

        {/* ── question / tapped ── */}
        {(stage === "question" || stage === "tapped") && (
          <div className="flex-1 flex flex-col justify-center relative" style={{ minHeight: "80vh" }}>
            <p
              style={{
                color: GOLD,
                fontSize: 10.5,
                letterSpacing: "0.32em",
                fontWeight: 600,
                textAlign: "center",
              }}
            >
              {q.kind}
            </p>
            <p
              style={{
                fontFamily: FONT_SERIF,
                fontSize: 33,
                lineHeight: 1.24,
                fontWeight: 400,
                color: PAPER,
                textAlign: "center",
                marginTop: 20,
                animation: "fadeIn .6s ease both",
              }}
            >
              {q.text}
            </p>
            <p
              style={{
                color: MUTED,
                fontSize: 14,
                lineHeight: 1.55,
                textAlign: "center",
                marginTop: 18,
                maxWidth: 330,
                marginLeft: "auto",
                marginRight: "auto",
              }}
            >
              {q.context}
            </p>
            {error && (
              <p className="text-center mt-4" style={{ color: TEAL, fontSize: 12.5, lineHeight: 1.45 }}>
                {error}
              </p>
            )}

            <div className="flex flex-col gap-3.5 mt-11">
              {q.options.map((opt, i) => {
                const idx: OptionIndex = i === 0 ? 0 : 1;
                const picked = stage === "tapped" && choice === idx;
                const ashed = stage === "tapped" && choice !== idx;
                return (
                  <button
                    key={opt.label}
                    onClick={() => answer(idx)}
                    disabled={stage !== "question" || submitting}
                    className="w-full py-4 rounded-2xl"
                    style={{
                      fontSize: 16.5,
                      fontWeight: 600,
                      letterSpacing: "0.02em",
                      color: picked ? "#12100A" : PAPER,
                      background: picked ? `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})` : RAISED,
                      border: `1px solid ${picked ? GOLD : HAIRLINE}`,
                      backdropFilter: "blur(10px)",
                      opacity: ashed ? 0.16 : 1,
                      filter: ashed ? "grayscale(1)" : "none",
                      transform: picked ? "scale(1.03)" : "scale(1)",
                      transition: "all .5s cubic-bezier(.2,.8,.2,1)",
                      animation: picked ? "ringPulse .7s ease-out" : "none",
                      cursor: stage === "question" && !submitting ? "pointer" : "default",
                    }}
                  >
                    {picked && submitting ? "Counting…" : opt.label}
                  </button>
                );
              })}
            </div>

            <p className="text-center mt-11" style={{ color: FAINT, fontSize: 12.5 }}>
              <span style={{ color: MUTED, fontVariantNumeric: "tabular-nums", fontWeight: 500 }}>
                {fmt(counter)}
              </span>{" "}
              people have answered
            </p>
            <p className="text-center mt-1.5" style={{ color: FAINT, fontSize: 11 }}>
              Answer to see how the world thinks.
            </p>
          </div>
        )}

        {/* ── unlocking ── */}
        {stage === "unlocking" && (
          <div
            className="flex-1 flex flex-col items-center justify-center gap-6"
            style={{ minHeight: "80vh", animation: "fadeIn .3s ease both" }}
          >
            <div
              style={{
                width: 10,
                height: 10,
                borderRadius: "50%",
                background: GOLD,
                animation: reduceMotion ? "none" : "heartbeat .62s ease-in-out infinite",
              }}
            />
            <p style={{ color: MUTED, fontSize: 12.5, letterSpacing: "0.22em" }}>
              COUNTING YOUR VOTE…
            </p>
          </div>
        )}

        {/* ── reveal ── */}
        {stage === "reveal" && choice !== null && chosen !== null && (
          <div className="flex flex-col mt-6" style={{ animation: "fadeIn .4s ease both" }}>
            <p
              className="text-center mx-auto"
              style={{ fontFamily: FONT_SERIF, fontSize: 15, color: MUTED, maxWidth: 300, lineHeight: 1.4 }}
            >
              {q.text}
            </p>

            <div className="flex items-end justify-center gap-10 mt-7">
              {q.options.map((opt, i) => {
                const idx: OptionIndex = i === 0 ? 0 : 1;
                const mine = idx === choice;
                const val = idx === 0 ? rollA : rollB;
                const majSide = opt.pct >= q.options[idx === 0 ? 1 : 0].pct;
                return (
                  <div key={opt.label} className="flex flex-col items-center">
                    <span
                      style={{
                        fontVariantNumeric: "tabular-nums",
                        fontFamily: FONT_SERIF,
                        fontSize: mine ? 60 : 42,
                        lineHeight: 1,
                        fontWeight: 500,
                        color: mine ? accent : majSide ? PAPER : FAINT,
                        textShadow: mine ? `0 0 30px ${accent}55` : "none",
                        transition: "color .4s ease",
                      }}
                    >
                      {val}
                      <span style={{ fontSize: mine ? 28 : 20 }}>%</span>
                    </span>
                    <span
                      className="mt-2 text-center"
                      style={{
                        fontSize: 11.5,
                        letterSpacing: "0.14em",
                        color: mine ? accent : FAINT,
                        fontWeight: 600,
                        maxWidth: 120,
                      }}
                    >
                      {opt.label.toUpperCase()}
                      {mine ? " · YOU" : ""}
                    </span>
                  </div>
                );
              })}
            </div>

            <div
              className="w-full mt-6 rounded-full overflow-hidden flex"
              style={{ height: 13, background: "rgba(255,255,255,0.05)", border: `1px solid ${HAIRLINE}` }}
            >
              <div
                style={{
                  width: barOn ? `${q.options[0].pct}%` : "50%",
                  background:
                    choice === 0
                      ? `linear-gradient(90deg, ${accentDeep}, ${accent})`
                      : "linear-gradient(90deg,#232B44,#2C3550)",
                  transition: "width 1.05s cubic-bezier(.3,.9,.3,1)",
                }}
              />
              <div
                style={{
                  flex: 1,
                  background:
                    choice === 1
                      ? `linear-gradient(90deg, ${accent}, ${accentDeep})`
                      : "linear-gradient(90deg,#2C3550,#232B44)",
                  transition: "width 1.05s cubic-bezier(.3,.9,.3,1)",
                }}
              />
            </div>

            <div className="flex justify-center mt-5" style={{ animation: "riseIn .6s ease both .3s" }}>
              <span
                className="px-4 py-2 rounded-full"
                style={{
                  fontSize: 12.5,
                  fontWeight: 600,
                  letterSpacing: "0.03em",
                  color: accent,
                  background: `${accent}14`,
                  border: `1px solid ${accent}45`,
                }}
              >
                {isMajority
                  ? `You're with ${chosen.pct}% of humanity`
                  : `A rarer view — ${chosen.pct}% of humanity`}
              </span>
            </div>
            {voteNotice && (
              <p className="text-center mt-3" style={{ color: MUTED, fontSize: 12.5 }}>
                {voteNotice}
              </p>
            )}

            {showGlobe && q.chips.length > 0 && (
              <div className="mt-3" style={{ animation: "fadeIn .8s ease both" }}>
                <Suspense fallback={<div style={{ height: 240 }} />}>
                  <Globe reduceMotion={reduceMotion} />
                </Suspense>
                <div
                  className="owq-chips flex gap-2 overflow-x-auto -mx-6 px-6 pb-1"
                  style={{ scrollbarWidth: "none" }}
                >
                  {q.chips.map((c) => (
                    <span
                      key={c.name}
                      className="shrink-0 px-3 py-2 rounded-full"
                      style={{
                        fontSize: 11.5,
                        color: MUTED,
                        background: RAISED,
                        border: `1px solid ${HAIRLINE}`,
                        whiteSpace: "nowrap",
                      }}
                    >
                      {c.flag} {c.name} · <span style={{ color: PAPER }}>{c.line}</span>
                    </span>
                  ))}
                </div>
              </div>
            )}

            {showThink && <ThinkPanel think={q.think} discussionUrl={q.discussionUrl} />}

            {/* twist */}
            {showThink && (
              <div
                className="mt-4 px-5 py-4 rounded-2xl"
                style={{ background: RAISED, border: `1px solid ${HAIRLINE}`, animation: "riseIn .6s ease both .15s" }}
              >
                <p style={{ fontSize: 10.5, letterSpacing: "0.26em", color: TEAL, fontWeight: 600 }}>
                  THE TWIST
                </p>
                <p className="mt-2" style={{ fontFamily: FONT_SERIF, fontSize: 18, lineHeight: 1.4, color: PAPER }}>
                  {q.twist}
                </p>
              </div>
            )}

            {showFooter && (
              <div className="mt-6" style={{ animation: "riseIn .6s ease both" }}>
                <div className="flex justify-center gap-2">
                  <span
                    className="px-3 py-1.5 rounded-full"
                    style={{ fontSize: 11.5, color: MUTED, border: `1px solid ${HAIRLINE}` }}
                  >
                    🔥 Day {q.day} streak
                  </span>
                  <span
                    className="px-3 py-1.5 rounded-full"
                    style={{ fontSize: 11.5, color: MUTED, border: `1px solid ${HAIRLINE}` }}
                  >
                    🧭 {isMajority ? "With the majority" : "Independent thinker"}
                  </span>
                </div>
                <div className="flex flex-col gap-3 mt-5">
                  <button
                    onClick={() => setShareOpen(true)}
                    className="w-full py-4 rounded-2xl"
                    style={{
                      fontSize: 15.5,
                      fontWeight: 600,
                      color: "#12100A",
                      background: `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})`,
                      border: `1px solid ${GOLD}`,
                    }}
                  >
                    Share your answer
                  </button>
                  <div
                    className="w-full py-3.5 rounded-2xl text-center"
                    style={{
                      fontSize: 14,
                      fontWeight: 500,
                      color: MUTED,
                      background: "transparent",
                      border: `1px solid ${HAIRLINE}`,
                    }}
                  >
                    Next question unlocks tomorrow
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {shareOpen && choice !== null && (
          <ShareCardOverlay
            question={q}
            choice={choice}
            accent={accent}
            isMajority={isMajority}
            onClose={() => setShareOpen(false)}
          />
        )}
      </div>
    </div>
  );
}
