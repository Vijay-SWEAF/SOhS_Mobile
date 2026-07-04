import type { DailyQuestion } from "./questions";

export interface WordPuzzleTerm {
  id: string;
  word: string;
  meaning: string;
  reflection: string;
  keywords: readonly string[];
}

export interface DailyWordPuzzle {
  id: string;
  terms: readonly WordPuzzleTerm[];
}

const TERMS: readonly WordPuzzleTerm[] = [
  {
    id: "accountability",
    word: "Accountability",
    meaning: "Taking responsibility for an action and its consequences.",
    reflection: "A society becomes fairer when power can be questioned.",
    keywords: ["accountable", "responsibility", "responsible", "blame", "consequence", "answer", "public"],
  },
  {
    id: "bias",
    word: "Bias",
    meaning: "A leaning that can shape judgment before evidence is fully seen.",
    reflection: "Bias is not always loud; sometimes it feels like certainty.",
    keywords: ["bias", "judge", "judgment", "favourite", "favorite", "impression", "search", "assume"],
  },
  {
    id: "compassion",
    word: "Compassion",
    meaning: "Noticing suffering and wanting to reduce it.",
    reflection: "Compassion asks what pain is present before it asks who is right.",
    keywords: ["kindness", "suffering", "harm", "feelings", "care", "necessities", "hurt", "money"],
  },
  {
    id: "consent",
    word: "Consent",
    meaning: "Clear permission given freely, with enough understanding.",
    reflection: "Consent protects dignity where pressure can hide as choice.",
    keywords: ["consent", "privacy", "messages", "photos", "post", "permission", "child", "partner"],
  },
  {
    id: "courage",
    word: "Courage",
    meaning: "Choosing a hard truth or action despite fear or cost.",
    reflection: "Courage is often quiet; it appears when comfort is easier.",
    keywords: ["courage", "truth", "lie", "honest", "employee", "oath", "cover", "protect"],
  },
  {
    id: "dignity",
    word: "Dignity",
    meaning: "The worth a person has before status, money, approval, or usefulness.",
    reflection: "Dignity is the line a humane society should not cross.",
    keywords: ["dignity", "worth", "rights", "human", "person", "unsafe", "aging", "belong"],
  },
  {
    id: "empathy",
    word: "Empathy",
    meaning: "Trying to understand another person's experience from the inside.",
    reflection: "Empathy does not erase disagreement; it makes disagreement more human.",
    keywords: ["empathy", "feelings", "friend", "partner", "parents", "child", "kind", "lonely"],
  },
  {
    id: "evidence",
    word: "Evidence",
    meaning: "Information that helps test whether a belief is true.",
    reflection: "Evidence slows the mind down before opinion takes over.",
    keywords: ["evidence", "fact", "search", "history", "internet", "proof", "saw", "study"],
  },
  {
    id: "fairness",
    word: "Fairness",
    meaning: "Treating people by a standard that is not secretly tilted.",
    reflection: "Fairness is tested when the rule affects someone we dislike.",
    keywords: ["fair", "fairness", "salary", "parents", "child", "punishment", "justice", "legal"],
  },
  {
    id: "forgiveness",
    word: "Forgiveness",
    meaning: "Releasing a debt of resentment without pretending harm was harmless.",
    reflection: "Forgiveness and accountability can stand in the same room.",
    keywords: ["forgive", "forgiveness", "second", "chance", "dead", "privacy", "past", "forget"],
  },
  {
    id: "harm",
    word: "Harm",
    meaning: "Damage done to someone's safety, dignity, freedom, or trust.",
    reflection: "A moral debate changes when hidden harm becomes visible.",
    keywords: ["harm", "hurt", "unsafe", "damage", "river", "necessities", "lie", "protect"],
  },
  {
    id: "honesty",
    word: "Honesty",
    meaning: "Telling the truth without using truth as a weapon.",
    reflection: "Honesty needs courage, but also care.",
    keywords: ["honest", "honesty", "truth", "lie", "viral", "wallet", "oath", "employee"],
  },
  {
    id: "integrity",
    word: "Integrity",
    meaning: "Keeping your values intact when nobody is watching.",
    reflection: "Integrity is easiest to admire and hardest to practice alone.",
    keywords: ["integrity", "wallet", "cash", "nobody", "saw", "right", "wrong", "hide"],
  },
  {
    id: "intent",
    word: "Intent",
    meaning: "The purpose behind an action, not only the action itself.",
    reflection: "Good intent can explain a choice, but it does not erase impact.",
    keywords: ["intent", "intentions", "outcome", "lie", "protect", "kindly", "wrong", "reason"],
  },
  {
    id: "justice",
    word: "Justice",
    meaning: "A fair response to wrong, power, need, and repair.",
    reflection: "Justice asks more than who won; it asks what should be restored.",
    keywords: ["justice", "punishment", "law", "legal", "rights", "wrong", "hurt", "court"],
  },
  {
    id: "morality",
    word: "Morality",
    meaning: "The question of what is right, wrong, harmful, or humane.",
    reflection: "Morality begins where convenience stops answering.",
    keywords: ["moral", "morality", "legally", "right", "wrong", "ethic", "question", "dilemma"],
  },
  {
    id: "privacy",
    word: "Privacy",
    meaning: "Control over what parts of life, identity, or history are exposed.",
    reflection: "Privacy protects both safety and the chance to remain whole.",
    keywords: ["privacy", "internet", "forget", "search", "messages", "photos", "dead", "history"],
  },
  {
    id: "responsibility",
    word: "Responsibility",
    meaning: "The duty to consider what your choices do to others.",
    reflection: "Responsibility is what remains after excuses run out.",
    keywords: ["responsibility", "parents", "child", "river", "legal", "money", "safe", "duty"],
  },
  {
    id: "self-interest",
    word: "Self-interest",
    meaning: "Choosing what benefits oneself, sometimes fairly and sometimes at another's cost.",
    reflection: "Self-interest is not always wrong; the question is what it ignores.",
    keywords: ["selfish", "happiness", "money", "salary", "famous", "comfort", "lack", "necessities"],
  },
  {
    id: "trust",
    word: "Trust",
    meaning: "Confidence that someone or something will not betray what matters.",
    reflection: "Trust is slow to build and quick to spend.",
    keywords: ["trust", "friend", "partner", "lie", "honest", "public", "salary", "belong"],
  },
];

const FALLBACK_IDS = ["morality", "dignity", "honesty", "justice", "empathy", "responsibility"];

function hashString(value: string): number {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function seededRandom(seed: number): () => number {
  let state = seed || 1;
  return () => {
    state = Math.imul(1664525, state) + 1013904223;
    return ((state >>> 0) / 4294967296);
  };
}

export function shuffleWithSeed<T>(items: readonly T[], seedInput: string): T[] {
  const random = seededRandom(hashString(seedInput));
  const shuffled = [...items];
  for (let i = shuffled.length - 1; i > 0; i -= 1) {
    const j = Math.floor(random() * (i + 1));
    const current = shuffled[i];
    const target = shuffled[j];
    if (current === undefined || target === undefined) continue;
    shuffled[i] = target;
    shuffled[j] = current;
  }
  return shuffled;
}

function scoreTerm(term: WordPuzzleTerm, corpus: string): number {
  return term.keywords.reduce((score, keyword) => {
    const normalized = keyword.toLowerCase();
    return corpus.includes(normalized) ? score + 3 + Math.min(normalized.length, 8) / 8 : score;
  }, 0);
}

export function buildDailyWordPuzzle(question: DailyQuestion & { id?: string }): DailyWordPuzzle {
  const puzzleId = question.id ?? `${question.day}-${question.text}`;
  const corpus = [
    question.kind,
    question.text,
    question.context,
    question.twist,
    question.options.map((option) => option.label).join(" "),
    question.think.fact,
    question.think.opinion,
    question.think.watch,
  ]
    .join(" ")
    .toLowerCase();

  const ranked = TERMS.map((term) => ({
    term,
    score: scoreTerm(term, corpus),
  })).sort((a, b) => b.score - a.score || a.term.word.localeCompare(b.term.word));

  const selected = ranked
    .filter(({ score }) => score > 0)
    .map(({ term }) => term)
    .slice(0, 7);

  const selectedIds = new Set(selected.map((term) => term.id));
  for (const id of FALLBACK_IDS) {
    if (selected.length >= 6) break;
    const fallback = TERMS.find((term) => term.id === id);
    if (fallback && !selectedIds.has(fallback.id)) {
      selected.push(fallback);
      selectedIds.add(fallback.id);
    }
  }

  return {
    id: puzzleId,
    terms: shuffleWithSeed(selected.slice(0, 6), `${puzzleId}:terms`),
  };
}
