import { useEffect, useMemo, useState } from "react";
import { Preferences } from "@capacitor/preferences";
import { tapHaptic } from "../lib/haptics";
import type { DailyQuestion } from "../lib/questions";
import { buildDailyWordPuzzle, shuffleWithSeed, type WordPuzzleTerm } from "../lib/wordPuzzle";
import { FAINT, FONT_SERIF, GOLD, GOLD_DEEP, HAIRLINE, INK_2, MUTED, PAPER, RAISED, TEAL } from "../lib/theme";

interface DailyWordPuzzleProps {
  question: DailyQuestion & { id?: string };
}

function storageKey(puzzleId: string): string {
  return `sohs.word_puzzle.matches.${puzzleId}`;
}

function parseStoredMatches(value: string | null, validIds: ReadonlySet<string>): Set<string> {
  if (!value) return new Set();

  try {
    const parsed = JSON.parse(value);
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.filter((id): id is string => typeof id === "string" && validIds.has(id)));
  } catch {
    return new Set();
  }
}

export default function DailyWordPuzzle({ question }: DailyWordPuzzleProps) {
  const puzzle = useMemo(() => buildDailyWordPuzzle(question), [question]);
  const meaningOrder = useMemo(
    () => shuffleWithSeed(puzzle.terms, `${puzzle.id}:meanings`),
    [puzzle.id, puzzle.terms],
  );
  const validIds = useMemo(() => new Set(puzzle.terms.map((term) => term.id)), [puzzle.terms]);

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [matchedIds, setMatchedIds] = useState<Set<string>>(() => new Set());
  const [notice, setNotice] = useState("Tap a word, then its meaning.");
  const [reflection, setReflection] = useState<string | null>(null);

  const completed = matchedIds.size === puzzle.terms.length;
  const selectedTerm = selectedId ? puzzle.terms.find((term) => term.id === selectedId) : null;

  useEffect(() => {
    let cancelled = false;

    async function loadProgress(): Promise<void> {
      const { value } = await Preferences.get({ key: storageKey(puzzle.id) });
      if (cancelled) return;

      const storedMatches = parseStoredMatches(value, validIds);
      setMatchedIds(storedMatches);
      setSelectedId(null);
      setReflection(null);
      setNotice(
        storedMatches.size === puzzle.terms.length
          ? "Today's words completed."
          : "Tap a word, then its meaning.",
      );
    }

    void loadProgress();
    return () => {
      cancelled = true;
    };
  }, [puzzle.id, puzzle.terms.length, validIds]);

  async function persistMatches(nextMatches: Set<string>): Promise<void> {
    await Preferences.set({
      key: storageKey(puzzle.id),
      value: JSON.stringify([...nextMatches]),
    });
  }

  function selectWord(term: WordPuzzleTerm): void {
    if (matchedIds.has(term.id)) return;
    void tapHaptic();
    setSelectedId(term.id);
    setNotice(`Find the meaning of "${term.word}".`);
    setReflection(null);
  }

  function chooseMeaning(term: WordPuzzleTerm): void {
    if (!selectedId || matchedIds.has(term.id)) return;
    void tapHaptic();

    if (selectedId !== term.id) {
      setNotice("Close, but not this meaning. Try another pair.");
      return;
    }

    const nextMatches = new Set(matchedIds);
    nextMatches.add(term.id);
    setMatchedIds(nextMatches);
    setSelectedId(null);
    setReflection(term.reflection);
    setNotice(nextMatches.size === puzzle.terms.length ? "Today's words completed." : "Matched. Keep going.");
    void persistMatches(nextMatches);
  }

  return (
    <section
      className="mt-5 overflow-hidden rounded-3xl"
      style={{
        background: `linear-gradient(160deg, ${INK_2}, rgba(255,255,255,0.045))`,
        border: `1px solid ${GOLD}35`,
        boxShadow: "0 18px 70px rgba(0,0,0,0.22)",
        animation: "riseIn .6s ease both",
      }}
      aria-label="Daily word puzzle"
    >
      <div className="px-5 pt-5 pb-4" style={{ borderBottom: `1px solid ${HAIRLINE}` }}>
        <div className="flex items-start justify-between gap-4">
          <div>
            <p style={{ fontSize: 10.5, letterSpacing: "0.26em", color: GOLD, fontWeight: 700 }}>
              HUMAN WORDS
            </p>
            <h2 className="mt-2" style={{ fontFamily: FONT_SERIF, color: PAPER, fontSize: 23, lineHeight: 1.15 }}>
              Play with today's ideas
            </h2>
          </div>
          <div
            className="shrink-0 rounded-full px-3 py-1.5"
            style={{
              color: completed ? "#11140D" : GOLD,
              background: completed ? `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})` : `${GOLD}12`,
              border: `1px solid ${completed ? GOLD : `${GOLD}45`}`,
              fontSize: 11,
              fontWeight: 800,
            }}
          >
            {matchedIds.size}/{puzzle.terms.length}
          </div>
        </div>

        <div className="mt-4 h-2 overflow-hidden rounded-full" style={{ background: "rgba(255,255,255,0.07)" }}>
          <div
            className="h-full rounded-full"
            style={{
              width: `${(matchedIds.size / puzzle.terms.length) * 100}%`,
              background: completed ? `linear-gradient(90deg, ${TEAL}, ${GOLD})` : GOLD,
              transition: "width .35s ease",
            }}
          />
        </div>

        <p className="mt-3" style={{ color: completed ? GOLD : MUTED, fontSize: 12.5, lineHeight: 1.45 }}>
          {notice}
        </p>
      </div>

      <div className="px-5 py-5">
        <div className="flex flex-wrap gap-2">
          {puzzle.terms.map((term) => {
            const matched = matchedIds.has(term.id);
            const selected = selectedId === term.id;
            return (
              <button
                key={term.id}
                type="button"
                onClick={() => selectWord(term)}
                disabled={matched}
                className="rounded-full px-3.5 py-2"
                style={{
                  color: matched ? TEAL : selected ? "#11140D" : PAPER,
                  background: matched
                    ? `${TEAL}16`
                    : selected
                      ? `linear-gradient(135deg, ${GOLD}, ${GOLD_DEEP})`
                      : RAISED,
                  border: `1px solid ${matched ? `${TEAL}55` : selected ? GOLD : HAIRLINE}`,
                  fontSize: 12.5,
                  fontWeight: 750,
                  opacity: matched ? 0.78 : 1,
                }}
              >
                {term.word}
              </button>
            );
          })}
        </div>

        <div className="mt-4 grid gap-2.5">
          {meaningOrder.map((term) => {
            const matched = matchedIds.has(term.id);
            return (
              <button
                key={term.id}
                type="button"
                onClick={() => chooseMeaning(term)}
                disabled={!selectedId || matched}
                className="rounded-2xl px-4 py-3 text-left"
                style={{
                  color: matched ? TEAL : PAPER,
                  background: "rgba(255,255,255,0.035)",
                  border: `1px solid ${matched ? `${TEAL}55` : selectedTerm ? `${GOLD}35` : HAIRLINE}`,
                  opacity: matched ? 0.72 : selectedId ? 1 : 0.9,
                  transition: "border-color .2s ease, background .2s ease, opacity .2s ease",
                }}
              >
                <span style={{ display: "block", fontSize: 13.5, lineHeight: 1.4 }}>{term.meaning}</span>
                {matched && (
                  <span className="mt-1 block" style={{ color: FAINT, fontSize: 11.5, fontWeight: 700 }}>
                    Matched
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {(reflection || completed) && (
          <div
            className="mt-4 rounded-2xl px-4 py-3"
            style={{
              border: `1px solid ${completed ? `${TEAL}55` : `${GOLD}40`}`,
              background: completed ? `${TEAL}10` : `${GOLD}10`,
            }}
          >
            <p style={{ color: completed ? TEAL : GOLD, fontSize: 10.5, letterSpacing: "0.22em", fontWeight: 800 }}>
              {completed ? "TODAY'S WORDS COMPLETED" : "REFLECTION"}
            </p>
            <p className="mt-2" style={{ color: PAPER, fontSize: 13.5, lineHeight: 1.45 }}>
              {completed ? "You have completed today's knowledge exercise. Come back tomorrow for a new set." : reflection}
            </p>
          </div>
        )}
      </div>
    </section>
  );
}
