export interface ShareBadge {
  eyebrow: string;
  title: string;
  detail: string;
}

export function getShareBadge(pct: number, isMajority: boolean): ShareBadge {
  if (pct >= 95) {
    return {
      eyebrow: "ALIGNMENT",
      title: "Near-unanimous signal",
      detail: `${pct}% chose this. A rare shared instinct.`,
    };
  }

  if (isMajority && pct >= 70) {
    return {
      eyebrow: "CONSENSUS",
      title: "Strong common ground",
      detail: `${pct}% stood on the same side.`,
    };
  }

  if (isMajority) {
    return {
      eyebrow: "COMMON GROUND",
      title: "With the larger room",
      detail: `${pct}% read the dilemma this way.`,
    };
  }

  if (pct <= 20) {
    return {
      eyebrow: "RARE VIEW",
      title: "A hard minority call",
      detail: `Only ${pct}% chose this side.`,
    };
  }

  return {
    eyebrow: "INDEPENDENT",
    title: "Outside the majority",
    detail: `${pct}% held this line.`,
  };
}
