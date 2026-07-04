import { Capacitor } from "@capacitor/core";
import { LocalNotifications } from "@capacitor/local-notifications";
import { Preferences } from "@capacitor/preferences";

const LAUNCH_COUNT_KEY = "sohs.daily_reminder.launch_count";
const PROMPT_HANDLED_KEY = "sohs.daily_reminder.prompt_handled";
const SCHEDULED_KEY = "sohs.daily_reminder.scheduled";

const REMINDER_ID = 9001;
const REMINDER_CHANNEL_ID = "daily-question-reminder";
const REMINDER_HOUR = 9;
const REMINDER_MINUTE = 0;

const isAndroidNative = () => Capacitor.getPlatform() === "android";

async function getStoredNumber(key: string): Promise<number> {
  const { value } = await Preferences.get({ key });
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

async function getStoredBoolean(key: string): Promise<boolean> {
  const { value } = await Preferences.get({ key });
  return value === "true";
}

async function setStoredBoolean(key: string, value: boolean): Promise<void> {
  await Preferences.set({ key, value: String(value) });
}

async function incrementLaunchCount(): Promise<number> {
  const nextCount = (await getStoredNumber(LAUNCH_COUNT_KEY)) + 1;
  await Preferences.set({ key: LAUNCH_COUNT_KEY, value: String(nextCount) });
  return nextCount;
}

async function ensureReminderChannel(): Promise<void> {
  await LocalNotifications.createChannel({
    id: REMINDER_CHANNEL_ID,
    name: "Daily questions",
    description: "Daily SOhS question reminders.",
    importance: 3,
    visibility: 1,
    vibration: true,
  });
}

async function ensureNotificationPermission(): Promise<boolean> {
  const current = await LocalNotifications.checkPermissions();
  if (current.display === "granted") return true;
  if (current.display === "denied") return false;

  const requested = await LocalNotifications.requestPermissions();
  return requested.display === "granted";
}

async function scheduleDailyReminder(): Promise<void> {
  await LocalNotifications.cancel({ notifications: [{ id: REMINDER_ID }] });
  await LocalNotifications.schedule({
    notifications: [
      {
        id: REMINDER_ID,
        title: "Today's Human Question is live.",
        body: "Take a moment to vote and see how humanity thinks.",
        channelId: REMINDER_CHANNEL_ID,
        autoCancel: true,
        schedule: {
          on: { hour: REMINDER_HOUR, minute: REMINDER_MINUTE },
          repeats: true,
        },
      },
    ],
  });
}

export async function setupDailyReminderAfterLaunch(): Promise<void> {
  if (!isAndroidNative()) return;

  try {
    const launchCount = await incrementLaunchCount();
    const alreadyScheduled = await getStoredBoolean(SCHEDULED_KEY);
    if (alreadyScheduled || launchCount < 2) return;

    const alreadyPrompted = await getStoredBoolean(PROMPT_HANDLED_KEY);
    if (alreadyPrompted) return;

    await ensureReminderChannel();
    const hasPermission = await ensureNotificationPermission();
    await setStoredBoolean(PROMPT_HANDLED_KEY, true);
    if (!hasPermission) return;

    await scheduleDailyReminder();
    await setStoredBoolean(SCHEDULED_KEY, true);
  } catch (error) {
    console.warn("Daily reminder setup skipped.", error);
  }
}
