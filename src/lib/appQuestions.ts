import type { Database, Json } from "./database.types";
import { discussionPathUrl, questionDiscussionUrl } from "./discussionBridge";
import type { CountryChip, DailyQuestion, OptionIndex, QuestionOption, ThinkContent } from "./questions";
import { supabase } from "./supabase";

type AppDailyQuestionRow = Database["public"]["Tables"]["app_daily_questions"]["Row"];
type AppVoteCountsRow = Database["public"]["Tables"]["app_vote_counts"]["Row"];
type AppCountryCountsRow = Database["public"]["Tables"]["app_vote_country_counts"]["Row"];
type WebsiteQuestionRow = Pick<Database["public"]["Tables"]["human_questions"]["Row"], "id" | "slug" | "status">;

type AppDailyQuestionWithLink = AppDailyQuestionRow & {
  linked_question?: WebsiteQuestionRow | null;
  discussionUrl?: string | null;
};

export interface LiveDailyQuestion extends DailyQuestion {
  id: string;
  questionId: string | null;
  activeDate: string;
  discussionUrl: string | null;
  totalVotes: number;
}

export interface VoteResult {
  question: LiveDailyQuestion;
  alreadyVoted: boolean;
}

function utcDateString(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

function objectValue(value: Json, key: string): string {
  if (!value || typeof value !== "object" || Array.isArray(value)) return "";
  const item = value[key];
  return typeof item === "string" ? item : "";
}

function parseLabels(options: Json): readonly [string, string] {
  if (!Array.isArray(options) || options.length !== 2) return ["Yes", "No"];
  const labels = options.map((option) => objectValue(option, "label").trim());
  return [labels[0] || "Yes", labels[1] || "No"];
}

function parseThink(think: Json): ThinkContent {
  return {
    fact: objectValue(think, "fact"),
    opinion: objectValue(think, "opinion"),
    watch: objectValue(think, "watch"),
  };
}

function percentages(count0: number, count1: number): readonly [number, number] {
  const total = count0 + count1;
  if (total <= 0) return [50, 50];

  const option0 = Math.round((count0 / total) * 100);
  return [option0, 100 - option0];
}

function buildOptions(labels: readonly [string, string], counts: AppVoteCountsRow | null): readonly [
  QuestionOption,
  QuestionOption,
] {
  const [pct0, pct1] = percentages(counts?.option0_count ?? 0, counts?.option1_count ?? 0);
  return [
    { label: labels[0], pct: pct0 },
    { label: labels[1], pct: pct1 },
  ];
}

function flagForCountry(code: string): string {
  return code
    .toUpperCase()
    .replace(/./g, (char) => String.fromCodePoint(127397 + char.charCodeAt(0)));
}

function countryName(code: string): string {
  try {
    return new Intl.DisplayNames(["en"], { type: "region" }).of(code) ?? code;
  } catch {
    return code;
  }
}

function buildChips(
  labels: readonly [string, string],
  countryRows: readonly AppCountryCountsRow[],
): readonly CountryChip[] {
  return countryRows
    .map((row) => {
      const total = row.option0_count + row.option1_count;
      if (total <= 0) return null;

      const [pct0, pct1] = percentages(row.option0_count, row.option1_count);
      const winner = pct0 >= pct1 ? 0 : 1;
      const code = row.country_code.toUpperCase();
      return {
        flag: flagForCountry(code),
        name: countryName(code),
        line: `${winner === 0 ? pct0 : pct1}% ${labels[winner]}`,
        total,
      };
    })
    .filter((chip): chip is CountryChip & { total: number } => chip !== null)
    .sort((a, b) => b.total - a.total)
    .slice(0, 5)
    .map(({ flag, name, line }) => ({ flag, name, line }));
}

function discussionUrlForRow(row: AppDailyQuestionWithLink): string | null {
  if (row.discussionUrl !== undefined) return row.discussionUrl;
  const pathUrl = row.discussion_path ? discussionPathUrl(row.discussion_path) : null;
  if (pathUrl) return pathUrl;
  if (!row.linked_question || row.linked_question.status !== "published") return null;

  return questionDiscussionUrl(row.linked_question.slug);
}

function toQuestion(
  row: AppDailyQuestionWithLink,
  counts: AppVoteCountsRow | null,
  countryRows: readonly AppCountryCountsRow[],
): LiveDailyQuestion {
  const labels = parseLabels(row.options);
  return {
    id: row.id,
    questionId: row.question_id,
    activeDate: row.active_date,
    discussionUrl: discussionUrlForRow(row),
    day: row.day_number,
    kind: row.kind,
    text: row.question_text,
    context: row.context ?? "",
    options: buildOptions(labels, counts),
    chips: buildChips(labels, countryRows),
    twist: row.twist ?? "",
    think: parseThink(row.think),
    totalVotes: (counts?.option0_count ?? 0) + (counts?.option1_count ?? 0),
  };
}

async function fetchCounts(questionId: string): Promise<AppVoteCountsRow | null> {
  const { data, error } = await supabase
    .from("app_vote_counts")
    .select("*")
    .eq("question_id", questionId)
    .maybeSingle();

  if (error) throw error;
  return data;
}

async function fetchCountryCounts(questionId: string): Promise<AppCountryCountsRow[]> {
  const { data, error } = await supabase
    .from("app_vote_country_counts")
    .select("*")
    .eq("question_id", questionId);

  if (error) throw error;
  return data ?? [];
}

export async function loadActiveQuestion(): Promise<LiveDailyQuestion> {
  const { data, error } = await supabase
    .from("app_daily_questions")
    .select("*, linked_question:human_questions(id, slug, status)")
    .lte("active_date", utcDateString())
    .order("active_date", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  if (!data) throw new Error("No active daily question is available yet.");

  const [counts, countryRows] = await Promise.all([fetchCounts(data.id), fetchCountryCounts(data.id)]);
  return toQuestion(data, counts, countryRows);
}

function parseVoteResponse(value: Json): Pick<AppVoteCountsRow, "option0_count" | "option1_count"> & {
  already_voted: boolean;
} {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Unexpected vote response from Supabase.");
  }

  const option0 = value.option0_count;
  const option1 = value.option1_count;
  const alreadyVoted = value.already_voted;
  if (typeof option0 !== "number" || typeof option1 !== "number" || typeof alreadyVoted !== "boolean") {
    throw new Error("Unexpected vote response from Supabase.");
  }

  return {
    option0_count: option0,
    option1_count: option1,
    already_voted: alreadyVoted,
  };
}

export async function castVote(
  question: LiveDailyQuestion,
  deviceId: string,
  choice: OptionIndex,
  countryCode: string | null,
): Promise<VoteResult> {
  const { data, error } = await supabase.rpc("cast_vote", {
    p_question_id: question.id,
    p_device_id: deviceId,
    p_option_index: choice,
    p_country_code: countryCode,
  });

  if (error) throw error;

  const response = parseVoteResponse(data);
  const counts: AppVoteCountsRow = {
    question_id: question.id,
    option0_count: response.option0_count,
    option1_count: response.option1_count,
    updated_at: new Date().toISOString(),
  };
  const countryRows = await fetchCountryCounts(question.id);

  return {
    question: toQuestion(
      {
        id: question.id,
        question_id: question.questionId,
        active_date: question.activeDate,
        discussionUrl: question.discussionUrl,
        discussion_path: null,
        day_number: question.day,
        kind: question.kind,
        question_text: question.text,
        context: question.context,
        options: question.options.map(({ label }) => ({ label })),
        think: {
          fact: question.think.fact,
          opinion: question.think.opinion,
          watch: question.think.watch,
        },
        twist: question.twist,
        created_at: "",
        updated_at: "",
      },
      counts,
      countryRows,
    ),
    alreadyVoted: response.already_voted,
  };
}

export function detectCountryCode(): string | null {
  try {
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (timeZone === "Asia/Kolkata" || timeZone === "Asia/Calcutta") return "IN";

    const locale = new Intl.Locale(navigator.language);
    const region = locale.region?.toUpperCase();
    return region && /^[A-Z]{2}$/.test(region) ? region : null;
  } catch {
    return null;
  }
}
