import { Preferences } from "@capacitor/preferences";
import type { OptionIndex } from "./questions";

const DEVICE_ID_KEY = "sohs_device_id";
const VOTE_KEY_PREFIX = "sohs_vote_";

function randomId(): string {
  if ("randomUUID" in crypto) return crypto.randomUUID();
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (crypto.getRandomValues(new Uint8Array(1))[0] ?? 0) & 15;
    const v = c === "x" ? r : (r & 3) | 8;
    return v.toString(16);
  });
}

export async function getDeviceId(): Promise<string> {
  const existing = await Preferences.get({ key: DEVICE_ID_KEY });
  if (existing.value) return existing.value;

  const next = randomId();
  await Preferences.set({ key: DEVICE_ID_KEY, value: next });
  return next;
}

export async function getStoredVote(questionId: string): Promise<OptionIndex | null> {
  const existing = await Preferences.get({ key: `${VOTE_KEY_PREFIX}${questionId}` });
  if (existing.value === "0") return 0;
  if (existing.value === "1") return 1;
  return null;
}

export async function storeVote(questionId: string, choice: OptionIndex): Promise<void> {
  await Preferences.set({ key: `${VOTE_KEY_PREFIX}${questionId}`, value: String(choice) });
}
