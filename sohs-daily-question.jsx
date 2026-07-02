import { useState, useEffect, useRef, useCallback } from "react";
import * as THREE from "three";

/* ────────────────────────────────────────────────────────────
   SOhS — One Human Question a Day
   Reskinned to societyofhomosapiens.org (#0B1020 navy)
   Civic register · majority/minority reveal · world heatmap
   Signature: "How to think about this" — fact/opinion panel
   that carries the SOhS mission into the reveal moment.
   ──────────────────────────────────────────────────────────── */

/* palette pulled from the live site */
const INK = "#0B1020";        // site theme-color
const INK_2 = "#0E1428";      // raised navy
const RAISED = "rgba(255,255,255,0.05)";
const HAIRLINE = "rgba(255,255,255,0.10)";
const PAPER = "#EEF1F8";
const MUTED = "#93A0BF";
const FAINT = "#5A6486";
const GOLD = "#E4B968";        // warm civic accent
const GOLD_DEEP = "#A9823A";
const TEAL = "#5FD0C8";        // "minority / rare" voice
const TEAL_DEEP = "#2C8B86";

const QUESTIONS = [
  {
    day: 1,
    kind: "HUMAN QUESTION",
    text: "Is being legally right always morally right?",
    context: "Laws create order, but history shows legality and morality do not always move together.",
    options: [
      { label: "Yes", pct: 23 },
      { label: "No", pct: 77 },
    ],
    chips: [
      { flag: "🇮🇳", name: "India", line: "81% No" },
      { flag: "🇺🇸", name: "USA", line: "74% No" },
      { flag: "🇯🇵", name: "Japan", line: "69% No" },
      { flag: "🇧🇷", name: "Brazil", line: "79% No" },
      { flag: "🇩🇪", name: "Germany", line: "72% No" },
    ],
    twist: "Under-25s were the most likely to say Yes — trust in law falls sharply with age.",
    think: {
      fact: "Legality and morality are separate systems — laws have permitted slavery, and banned dissent.",
      opinion: "Whether one should ever override the other is a genuine moral argument, not a settled fact.",
      watch: "Beware anyone who treats “it’s legal” as the end of a moral question. It’s the start of one.",
    },
  },
  {
    day: 2,
    kind: "MORAL DILEMMA",
    text: "You find a wallet with cash and ID. Nobody saw you. Return it?",
    context: "A note inside suggests the owner urgently needs the money too.",
    options: [
      { label: "Return it", pct: 88 },
      { label: "Keep it", pct: 12 },
    ],
    chips: [
      { flag: "🇮🇳", name: "India", line: "90% Return" },
      { flag: "🇺🇸", name: "USA", line: "85% Return" },
      { flag: "🇳🇬", name: "Nigeria", line: "82% Return" },
      { flag: "🇬🇧", name: "UK", line: "87% Return" },
      { flag: "🇯🇵", name: "Japan", line: "94% Return" },
    ],
    twist: "Stated intentions run far higher than what field studies actually observe.",
    think: {
      fact: "“Lost letter” and dropped-wallet field experiments consistently show return rates below what people predict.",
      opinion: "Whether hardship could justify keeping it is where sincere people genuinely disagree.",
      watch: "Notice the gap between what we say we'd do and what we do. That gap is the real subject.",
    },
  },
  {
    day: 3,
    kind: "HUMAN QUESTION",
    text: "Should a lie ever be told to protect someone's feelings?",
    context: "Honesty and kindness are both values — and they don't always agree.",
    options: [
      { label: "Yes", pct: 61 },
      { label: "No", pct: 39 },
    ],
    chips: [
      { flag: "🇮🇳", name: "India", line: "58% Yes" },
      { flag: "🇺🇸", name: "USA", line: "64% Yes" },
      { flag: "🇩🇪", name: "Germany", line: "44% Yes" },
      { flag: "🇧🇷", name: "Brazil", line: "70% Yes" },
      { flag: "🇰🇷", name: "S. Korea", line: "66% Yes" },
    ],
    twist: "Cultures that prize directness (e.g. Germany) leaned most toward No.",
    think: {
      fact: "Ethical traditions split here: strict Kantians say never; care-ethicists allow it to prevent harm.",
      opinion: "Where you land depends on which value you rank higher — a real choice, not an error.",
      watch: "“White lies” can hide both kindness and cowardice. Ask which one is doing the work.",
    },
  },
];

const fmt = (n) => n.toLocaleString("en-US");

/* ── geometry helpers ─────────────────────────────────────── */
function fibonacciSphere(n, radius) {
  const pts = [];
  const g = Math.PI * (3 - Math.sqrt(5));
  for (let i = 0; i < n; i++) {
    const y = 1 - (i / (n - 1)) * 2;
    const r = Math.sqrt(1 - y * y);
    const t = g * i;
    pts.push([Math.cos(t) * r * radius, y * radius, Math.sin(t) * r * radius]);
  }
  return pts;
}
function latLngToVec(lat, lng, radius) {
  const phi = ((90 - lat) * Math.PI) / 180;
  const theta = ((lng + 180) * Math.PI) / 180;
  return [
    -radius * Math.sin(phi) * Math.cos(theta),
    radius * Math.cos(phi),
    radius * Math.sin(phi) * Math.sin(theta),
  ];
}
const HOTSPOTS = [
  [28.6, 77.2], [19.1, 72.9], [13.1, 80.3],
  [35.7, 139.7], [37.5, 127.0], [31.2, 121.5],
  [51.5, -0.1], [48.9, 2.3], [52.5, 13.4],
  [40.7, -74.0], [34.0, -118.2], [19.4, -99.1],
  [-23.5, -46.6], [-34.6, -58.4],
  [6.5, 3.4], [-1.3, 36.8], [30.0, 31.2],
  [-33.9, 151.2], [25.2, 55.3], [41.0, 28.9],
];

/* ── Globe ─────────────────────────────────────────────────── */
function Globe({ reduceMotion }) {
  const hostRef = useRef(null);
  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    const w = host.clientWidth, h = host.clientHeight;
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(42, w / h, 0.1, 100);
    camera.position.z = 2.85;
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(w, h);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    host.appendChild(renderer.domElement);

    const group = new THREE.Group();
    group.rotation.x = 0.34;
    scene.add(group);

    const base = fibonacciSphere(1150, 1);
    const bp = new Float32Array(base.length * 3);
    base.forEach((p, i) => bp.set(p, i * 3));
    const baseGeo = new THREE.BufferGeometry();
    baseGeo.setAttribute("position", new THREE.BufferAttribute(bp, 3));
    const baseMat = new THREE.PointsMaterial({ color: new THREE.Color("#2A3352"), size: 0.013, transparent: true, opacity: 0, sizeAttenuation: true });
    group.add(new THREE.Points(baseGeo, baseMat));

    const gp = new Float32Array(HOTSPOTS.length * 3);
    HOTSPOTS.forEach((ll, i) => gp.set(latLngToVec(ll[0], ll[1], 1.005), i * 3));
    const goldGeo = new THREE.BufferGeometry();
    goldGeo.setAttribute("position", new THREE.BufferAttribute(gp, 3));
    const goldMat = new THREE.PointsMaterial({ color: new THREE.Color(GOLD), size: 0.045, transparent: true, opacity: 0, sizeAttenuation: true });
    group.add(new THREE.Points(goldGeo, goldMat));

    const emb = fibonacciSphere(46, 1.004).filter((_, i) => i % 3 === 0);
    const ep = new Float32Array(emb.length * 3);
    emb.forEach((p, i) => ep.set(p, i * 3));
    const embGeo = new THREE.BufferGeometry();
    embGeo.setAttribute("position", new THREE.BufferAttribute(ep, 3));
    const embMat = new THREE.PointsMaterial({ color: new THREE.Color(TEAL), size: 0.03, transparent: true, opacity: 0, sizeAttenuation: true });
    group.add(new THREE.Points(embGeo, embMat));

    let raf, t = 0;
    const spin = reduceMotion ? 0.0004 : 0.0015;
    const animate = () => {
      t += 1;
      group.rotation.y += spin;
      const ramp = Math.min(t / 70, 1);
      baseMat.opacity = 0.8 * ramp;
      goldMat.opacity = (0.8 + 0.2 * Math.sin(t * 0.06)) * ramp;
      embMat.opacity = (0.45 + 0.25 * Math.sin(t * 0.045 + 2)) * ramp;
      renderer.render(scene, camera);
      raf = requestAnimationFrame(animate);
    };
    animate();
    return () => {
      cancelAnimationFrame(raf);
      renderer.dispose();
      [baseGeo, goldGeo, embGeo, baseMat, goldMat, embMat].forEach((o) => o.dispose());
      if (renderer.domElement.parentNode === host) host.removeChild(renderer.domElement);
    };
  }, [reduceMotion]);

  return (
    <div className="relative w-full" style={{ height: 240 }}>
      <div className="absolute inset-0 pointer-events-none" style={{
        background: "radial-gradient(ellipse 60% 55% at 50% 52%, rgba(228,185,104,0.12), rgba(95,208,200,0.05) 55%, transparent 75%)",
      }} />
      <div ref={hostRef} className="absolute inset-0" />
    </div>
  );
}

export default function SOhSDailyQuestion() {
  const [qIndex, setQIndex] = useState(0);
  const [stage, setStage] = useState("question");
  const [choice, setChoice] = useState(null);
  const [counter, setCounter] = useState(2841902);
  const [rollA, setRollA] = useState(0);
  const [rollB, setRollB] = useState(0);
  const [barOn, setBarOn] = useState(false);
  const [showGlobe, setShowGlobe] = useState(false);
  const [showThink, setShowThink] = useState(false);
  const [showFooter, setShowFooter] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);

  const timers = useRef([]);
  const rafRef = useRef(null);
  const reduceMotion = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const q = QUESTIONS[qIndex % QUESTIONS.length];
  const chosen = choice !== null ? q.options[choice] : null;
  const other = choice !== null ? q.options[1 - choice] : null;
  const isMajority = chosen && chosen.pct >= other.pct;
  const accent = isMajority ? GOLD : TEAL;
  const accentDeep = isMajority ? GOLD_DEEP : TEAL_DEEP;

  const later = useCallback((fn, ms) => {
    const id = setTimeout(fn, ms);
    timers.current.push(id);
  }, []);

  useEffect(() => {
    if (stage !== "question") return;
    const id = setInterval(() => setCounter((c) => c + 1 + Math.floor(Math.random() * 12)), 190);
    return () => clearInterval(id);
  }, [stage]);

  useEffect(() => () => {
    timers.current.forEach(clearTimeout);
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
  }, []);

  useEffect(() => {
    if (stage !== "reveal" || choice === null) return;
    const dur = reduceMotion ? 350 : 1300;
    const start = performance.now();
    const a = q.options[0].pct, b = q.options[1].pct;
    const tick = (now) => {
      const p = Math.min((now - start) / dur, 1);
      const e = 1 - Math.pow(1 - p, 3);
      setRollA(Math.round(a * e));
      setRollB(Math.round(b * e));
      if (p < 1) rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => rafRef.current && cancelAnimationFrame(rafRef.current);
  }, [stage, choice, q, reduceMotion]);

  const speed = reduceMotion ? 0.35 : 1;

  const answer = (idx) => {
    if (stage !== "question") return;
    setChoice(idx);
    setStage("tapped");
    if (navigator.vibrate) navigator.vibrate(26);
    later(() => setStage("unlocking"), 680 * speed);
    later(() => { setStage("reveal"); if (navigator.vibrate) navigator.vibrate([12, 40, 12]); }, (680 + 1150) * speed);
    later(() => setBarOn(true), (680 + 1150 + 250) * speed);
    later(() => setShowGlobe(true), (680 + 1150 + 700) * speed);
    later(() => setShowThink(true), (680 + 1150 + 1500) * speed);
    later(() => setShowFooter(true), (680 + 1150 + 2300) * speed);
  };

  const nextQuestion = () => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
    setQIndex((i) => (i + 1) % QUESTIONS.length);
    setChoice(null); setRollA(0); setRollB(0);
    setBarOn(false); setShowGlobe(false); setShowThink(false); setShowFooter(false); setShareOpen(false);
    setCounter(1500000 + Math.floor(Math.random() * 2000000));
    setStage("question");
  };

  return (
    <div className="min-h-screen w-full flex justify-center" style={{ background: INK, fontFamily: "'Inter', system-ui, sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,500;9..144,600&family=Inter:wght@400;500;600&display=swap');
        @keyframes heartbeat { 0%,100% { opacity:.35; transform:scale(1);} 50% { opacity:1; transform:scale(1.28);} }
        @keyframes riseIn { from { opacity:0; transform:translateY(18px);} to { opacity:1; transform:translateY(0);} }
        @keyframes fadeIn { from { opacity:0;} to { opacity:1;} }
        @keyframes ringPulse { 0% { box-shadow:0 0 0 0 rgba(228,185,104,.4);} 100% { box-shadow:0 0 0 24px rgba(228,185,104,0);} }
        @keyframes driftGlow { 0%,100% { opacity:.5; transform:translate(-50%,0);} 50% { opacity:.85; transform:translate(-50%,-8px);} }
        button:focus-visible { outline:2px solid rgba(228,185,104,.85); outline-offset:3px; border-radius:999px; }
        .owq-chips::-webkit-scrollbar { display:none; }
      `}</style>

      <div className="w-full relative flex flex-col px-6 pt-7 pb-10" style={{ maxWidth: 430 }}>
        {/* ambient top glow */}
        <div className="absolute pointer-events-none" style={{
          top: -80, left: "50%", width: 460, height: 300,
          background: "radial-gradient(ellipse 50% 50% at 50% 50%, rgba(228,185,104,0.10), transparent 70%)",
          animation: reduceMotion ? "none" : "driftGlow 7s ease-in-out infinite",
        }} />

        {/* brand bar */}
        <div className="flex items-center justify-between relative">
          <div className="flex items-center gap-2.5">
            <div style={{ width: 9, height: 9, borderRadius: "50%", background: GOLD, boxShadow: `0 0 14px ${GOLD}` }} />
            <span style={{ color: PAPER, fontSize: 13, fontWeight: 600, letterSpacing: "0.02em" }}>
              Society Of <span style={{ color: GOLD }}>homo</span>Sapiens
            </span>
          </div>
          <span className="px-2.5 py-1 rounded-full" style={{ fontSize: 10, letterSpacing: "0.14em", color: MUTED, border: `1px solid ${HAIRLINE}` }}>
            DAY {q.day}
          </span>
        </div>

        {/* ── question / tapped ── */}
        {(stage === "question" || stage === "tapped") && (
          <div className="flex-1 flex flex-col justify-center relative" style={{ minHeight: "80vh" }}>
            <p style={{ color: GOLD, fontSize: 10.5, letterSpacing: "0.32em", fontWeight: 600, textAlign: "center" }}>
              {q.kind}
            </p>
            <p style={{
              fontFamily: "'Fraunces', Georgia, serif", fontSize: 33, lineHeight: 1.24, fontWeight: 400,
              color: PAPER, textAlign: "center", marginTop: 20, animation: "fadeIn .6s ease both",
            }}>
              {q.text}
            </p>
            <p style={{ color: MUTED, fontSize: 14, lineHeight: 1.55, textAlign: "center", marginTop: 18, maxWidth: 330, marginLeft: "auto", marginRight: "auto" }}>
              {q.context}
            </p>

            <div className="flex flex-col gap-3.5 mt-11">
              {q.options.map((opt, i) => {
                const picked = stage === "tapped" && choice === i;
                const ashed = stage === "tapped" && choice !== i;
                return (
                  <button key={opt.label} onClick={() => answer(i)} className="w-full py-4 rounded-2xl" style={{
                    fontSize: 16.5, fontWeight: 600, letterSpacing: "0.02em",
                    color: picked ? "#12100A" : PAPER,
                    background: picked ? `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})` : RAISED,
                    border: `1px solid ${picked ? GOLD : HAIRLINE}`,
                    backdropFilter: "blur(10px)",
                    opacity: ashed ? 0.16 : 1, filter: ashed ? "grayscale(1)" : "none",
                    transform: picked ? "scale(1.03)" : "scale(1)",
                    transition: "all .5s cubic-bezier(.2,.8,.2,1)",
                    animation: picked ? "ringPulse .7s ease-out" : "none",
                    cursor: stage === "question" ? "pointer" : "default",
                  }}>
                    {opt.label}
                  </button>
                );
              })}
            </div>

            <p className="text-center mt-11" style={{ color: FAINT, fontSize: 12.5 }}>
              <span style={{ color: MUTED, fontVariantNumeric: "tabular-nums", fontWeight: 500 }}>{fmt(counter)}</span> people have answered
            </p>
            <p className="text-center mt-1.5" style={{ color: FAINT, fontSize: 11 }}>Answer to see how the world thinks.</p>
          </div>
        )}

        {/* ── unlocking ── */}
        {stage === "unlocking" && (
          <div className="flex-1 flex flex-col items-center justify-center gap-6" style={{ minHeight: "80vh", animation: "fadeIn .3s ease both" }}>
            <div style={{ width: 10, height: 10, borderRadius: "50%", background: GOLD, animation: reduceMotion ? "none" : "heartbeat .62s ease-in-out infinite" }} />
            <p style={{ color: MUTED, fontSize: 12.5, letterSpacing: "0.22em" }}>LISTENING TO THE WORLD…</p>
          </div>
        )}

        {/* ── reveal ── */}
        {stage === "reveal" && chosen && (
          <div className="flex flex-col mt-6" style={{ animation: "fadeIn .4s ease both" }}>
            <p className="text-center mx-auto" style={{ fontFamily: "'Fraunces', Georgia, serif", fontSize: 15, color: MUTED, maxWidth: 300, lineHeight: 1.4 }}>
              {q.text}
            </p>

            <div className="flex items-end justify-center gap-10 mt-7">
              {q.options.map((opt, i) => {
                const mine = i === choice;
                const val = i === 0 ? rollA : rollB;
                const majSide = opt.pct >= q.options[1 - i].pct;
                return (
                  <div key={opt.label} className="flex flex-col items-center">
                    <span style={{
                      fontVariantNumeric: "tabular-nums", fontFamily: "'Fraunces', Georgia, serif",
                      fontSize: mine ? 60 : 42, lineHeight: 1, fontWeight: 500,
                      color: mine ? accent : majSide ? PAPER : FAINT,
                      textShadow: mine ? `0 0 30px ${accent}55` : "none", transition: "color .4s ease",
                    }}>
                      {val}<span style={{ fontSize: mine ? 28 : 20 }}>%</span>
                    </span>
                    <span className="mt-2 text-center" style={{ fontSize: 11.5, letterSpacing: "0.14em", color: mine ? accent : FAINT, fontWeight: 600, maxWidth: 120 }}>
                      {opt.label.toUpperCase()}{mine ? " · YOU" : ""}
                    </span>
                  </div>
                );
              })}
            </div>

            <div className="w-full mt-6 rounded-full overflow-hidden flex" style={{ height: 13, background: "rgba(255,255,255,0.05)", border: `1px solid ${HAIRLINE}` }}>
              <div style={{ width: barOn ? `${q.options[0].pct}%` : "50%", background: choice === 0 ? `linear-gradient(90deg, ${accentDeep}, ${accent})` : "linear-gradient(90deg,#232B44,#2C3550)", transition: "width 1.05s cubic-bezier(.3,.9,.3,1)" }} />
              <div style={{ flex: 1, background: choice === 1 ? `linear-gradient(90deg, ${accent}, ${accentDeep})` : "linear-gradient(90deg,#2C3550,#232B44)", transition: "width 1.05s cubic-bezier(.3,.9,.3,1)" }} />
            </div>

            <div className="flex justify-center mt-5" style={{ animation: "riseIn .6s ease both .3s" }}>
              <span className="px-4 py-2 rounded-full" style={{ fontSize: 12.5, fontWeight: 600, letterSpacing: "0.03em", color: accent, background: `${accent}14`, border: `1px solid ${accent}45` }}>
                {isMajority ? `You're with ${chosen.pct}% of humanity` : `A rarer view — ${chosen.pct}% of humanity`}
              </span>
            </div>

            {showGlobe && (
              <div className="mt-3" style={{ animation: "fadeIn .8s ease both" }}>
                <Globe reduceMotion={reduceMotion} />
                <div className="owq-chips flex gap-2 overflow-x-auto -mx-6 px-6 pb-1" style={{ scrollbarWidth: "none" }}>
                  {q.chips.map((c) => (
                    <span key={c.name} className="shrink-0 px-3 py-2 rounded-full" style={{ fontSize: 11.5, color: MUTED, background: RAISED, border: `1px solid ${HAIRLINE}`, whiteSpace: "nowrap" }}>
                      {c.flag} {c.name} · <span style={{ color: PAPER }}>{c.line}</span>
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* SIGNATURE: How to think about this */}
            {showThink && (
              <div className="mt-5 rounded-2xl overflow-hidden" style={{ background: "linear-gradient(180deg, rgba(228,185,104,0.06), rgba(255,255,255,0.025))", border: `1px solid ${HAIRLINE}`, backdropFilter: "blur(14px)", animation: "riseIn .6s cubic-bezier(.2,.8,.2,1) both" }}>
                <div className="px-5 pt-5 pb-2 flex items-center gap-2">
                  <div style={{ width: 6, height: 6, borderRadius: "50%", background: GOLD }} />
                  <p style={{ fontSize: 10.5, letterSpacing: "0.26em", color: GOLD, fontWeight: 600 }}>HOW TO THINK ABOUT THIS</p>
                </div>
                <div className="px-5 pb-5 flex flex-col gap-3.5">
                  <Row tag="FACT" tagColor={PAPER} text={q.think.fact} />
                  <Row tag="OPINION" tagColor={TEAL} text={q.think.opinion} />
                  <Row tag="WATCH FOR" tagColor={GOLD} text={q.think.watch} />
                </div>
                <div className="px-5 py-3.5" style={{ borderTop: `1px solid ${HAIRLINE}`, background: "rgba(255,255,255,0.02)" }}>
                  <span style={{ fontSize: 12, color: MUTED }}>
                    Read the full discussion on <span style={{ color: GOLD, fontWeight: 500 }}>SOhS →</span>
                  </span>
                </div>
              </div>
            )}

            {/* twist */}
            {showThink && (
              <div className="mt-4 px-5 py-4 rounded-2xl" style={{ background: RAISED, border: `1px solid ${HAIRLINE}`, animation: "riseIn .6s ease both .15s" }}>
                <p style={{ fontSize: 10.5, letterSpacing: "0.26em", color: TEAL, fontWeight: 600 }}>THE TWIST</p>
                <p className="mt-2" style={{ fontFamily: "'Fraunces', Georgia, serif", fontSize: 18, lineHeight: 1.4, color: PAPER }}>{q.twist}</p>
              </div>
            )}

            {showFooter && (
              <div className="mt-6" style={{ animation: "riseIn .6s ease both" }}>
                <div className="flex justify-center gap-2">
                  <span className="px-3 py-1.5 rounded-full" style={{ fontSize: 11.5, color: MUTED, border: `1px solid ${HAIRLINE}` }}>🔥 Day {q.day} streak</span>
                  <span className="px-3 py-1.5 rounded-full" style={{ fontSize: 11.5, color: MUTED, border: `1px solid ${HAIRLINE}` }}>🧭 {isMajority ? "With the majority" : "Independent thinker"}</span>
                </div>
                <div className="flex flex-col gap-3 mt-5">
                  <button onClick={() => setShareOpen(true)} className="w-full py-4 rounded-2xl" style={{ fontSize: 15.5, fontWeight: 600, color: "#12100A", background: `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})`, border: `1px solid ${GOLD}` }}>
                    Share your answer
                  </button>
                  <button onClick={nextQuestion} className="w-full py-3.5 rounded-2xl" style={{ fontSize: 14, fontWeight: 500, color: MUTED, background: "transparent", border: `1px solid ${HAIRLINE}` }}>
                    Next question ↺ &nbsp;<span style={{ color: FAINT, fontSize: 12 }}>demo</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* share card */}
        {shareOpen && chosen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center px-7" style={{ background: "rgba(6,9,18,0.88)", backdropFilter: "blur(6px)", animation: "fadeIn .25s ease both" }} onClick={() => setShareOpen(false)}>
            <div className="w-full rounded-2xl p-7 flex flex-col" style={{ maxWidth: 340, aspectRatio: "4 / 5", background: `linear-gradient(165deg, ${INK_2}, ${INK} 62%)`, border: `1px solid ${GOLD}55`, boxShadow: "0 0 80px rgba(228,185,104,0.08)", animation: "riseIn .4s cubic-bezier(.2,.8,.2,1) both" }} onClick={(e) => e.stopPropagation()}>
              <p style={{ fontSize: 9, letterSpacing: "0.28em", color: GOLD, fontWeight: 600 }}>SOhS · {q.kind} · DAY {q.day}</p>
              <p className="mt-5" style={{ fontFamily: "'Fraunces', Georgia, serif", fontSize: 21, lineHeight: 1.32, color: PAPER }}>{q.text}</p>
              <p className="mt-auto" style={{ fontFamily: "'Fraunces', Georgia, serif", fontSize: 34, lineHeight: 1.1, color: accent, fontWeight: 500 }}>
                {isMajority ? `With the ${chosen.pct}%.` : `The rarer ${chosen.pct}%.`}
              </p>
              <div className="w-full mt-4 rounded-full overflow-hidden flex" style={{ height: 8, background: "rgba(255,255,255,0.06)" }}>
                <div style={{ width: `${q.options[0].pct}%`, background: choice === 0 ? accent : "#2C3550" }} />
                <div style={{ flex: 1, background: choice === 1 ? accent : "#2C3550" }} />
              </div>
              <div className="flex items-center justify-between mt-4">
                <span style={{ fontSize: 10.5, color: FAINT }}>Think clearly. Discuss respectfully.</span>
                <span style={{ fontSize: 10.5, color: MUTED, fontWeight: 600 }}>societyofhomosapiens.org</span>
              </div>
            </div>
            <button onClick={() => setShareOpen(false)} className="absolute bottom-8 px-6 py-2.5 rounded-full" style={{ color: MUTED, fontSize: 13, border: `1px solid ${HAIRLINE}`, background: "rgba(255,255,255,0.03)" }}>
              Close · story-ready 4:5
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function Row({ tag, tagColor, text }) {
  return (
    <div className="flex gap-3">
      <span className="shrink-0 mt-0.5" style={{ fontSize: 9.5, letterSpacing: "0.12em", fontWeight: 700, color: tagColor, minWidth: 62 }}>{tag}</span>
      <span style={{ fontSize: 13.5, lineHeight: 1.5, color: "#C7CFE2" }}>{text}</span>
    </div>
  );
}
