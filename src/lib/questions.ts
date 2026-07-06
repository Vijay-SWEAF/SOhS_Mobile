/* Mock daily questions — Phase 2 stand-in for Supabase (Phase 3).
   Content ported verbatim from the prototype (sohs-daily-question.jsx). */

export interface QuestionOption {
  label: string;
  pct: number;
}

export interface CountryChip {
  flag: string;
  name: string;
  line: string;
}

export interface ThinkContent {
  fact: string;
  opinion: string;
  watch: string;
}

export interface DailyQuestion {
  day: number;
  kind: string;
  text: string;
  context: string;
  options: readonly [QuestionOption, QuestionOption];
  chips: readonly CountryChip[];
  twist: string;
  think: ThinkContent;
}

export type OptionIndex = 0 | 1;

export const QUESTIONS: readonly DailyQuestion[] = [
  {
    day: 1,
    kind: "HUMAN QUESTION",
    text: "Is being legally right always morally right?",
    context:
      "Laws create order, but history shows legality and morality do not always move together.",
    options: [
      { label: "Yes", pct: 23 },
      { label: "No", pct: 77 },
    ],
    chips: [
      { flag: "🇮🇳", name: "India", line: "↑ 19 · ↓ 81" },
      { flag: "🇺🇸", name: "USA", line: "↑ 26 · ↓ 74" },
      { flag: "🇯🇵", name: "Japan", line: "↑ 31 · ↓ 69" },
      { flag: "🇧🇷", name: "Brazil", line: "↑ 21 · ↓ 79" },
      { flag: "🇩🇪", name: "Germany", line: "↑ 28 · ↓ 72" },
    ],
    twist: "Under-25s were the most likely to say Yes — trust in law falls sharply with age.",
    think: {
      fact: "Legality and morality are separate systems — laws have permitted slavery, and banned dissent.",
      opinion:
        "Whether one should ever override the other is a genuine moral argument, not a settled fact.",
      watch:
        "Beware anyone who treats “it’s legal” as the end of a moral question. It’s the start of one.",
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
      { flag: "🇮🇳", name: "India", line: "↑ 90 · ↓ 10" },
      { flag: "🇺🇸", name: "USA", line: "↑ 85 · ↓ 15" },
      { flag: "🇳🇬", name: "Nigeria", line: "↑ 82 · ↓ 18" },
      { flag: "🇬🇧", name: "UK", line: "↑ 87 · ↓ 13" },
      { flag: "🇯🇵", name: "Japan", line: "↑ 94 · ↓ 6" },
    ],
    twist: "Stated intentions run far higher than what field studies actually observe.",
    think: {
      fact: "“Lost letter” and dropped-wallet field experiments consistently show return rates below what people predict.",
      opinion:
        "Whether hardship could justify keeping it is where sincere people genuinely disagree.",
      watch:
        "Notice the gap between what we say we'd do and what we do. That gap is the real subject.",
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
      { flag: "🇮🇳", name: "India", line: "↑ 58 · ↓ 42" },
      { flag: "🇺🇸", name: "USA", line: "↑ 64 · ↓ 36" },
      { flag: "🇩🇪", name: "Germany", line: "↑ 44 · ↓ 56" },
      { flag: "🇧🇷", name: "Brazil", line: "↑ 70 · ↓ 30" },
      { flag: "🇰🇷", name: "S. Korea", line: "↑ 66 · ↓ 34" },
    ],
    twist: "Cultures that prize directness (e.g. Germany) leaned most toward No.",
    think: {
      fact: "Ethical traditions split here: strict Kantians say never; care-ethicists allow it to prevent harm.",
      opinion:
        "Where you land depends on which value you rank higher — a real choice, not an error.",
      watch: "“White lies” can hide both kindness and cowardice. Ask which one is doing the work.",
    },
  },
];

export const fmt = (n: number): string => n.toLocaleString("en-US");
