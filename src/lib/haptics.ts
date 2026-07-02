import { registerPlugin } from "@capacitor/core";

enum ImpactStyle {
  Medium = "MEDIUM",
}

enum NotificationType {
  Success = "SUCCESS",
}

interface HapticsPlugin {
  impact(options: { style: ImpactStyle }): Promise<void>;
  notification(options: { type: NotificationType }): Promise<void>;
}

const Haptics = registerPlugin<HapticsPlugin>("Haptics", {
  web: {
    impact: async () => {},
    notification: async () => {},
  },
});

/* Fire-and-forget wrappers — haptics must never break the flow. */

export function tapHaptic(): void {
  void Haptics.impact({ style: ImpactStyle.Medium }).catch(() => {
    /* unsupported platform — silently skip */
  });
}

export function revealHaptic(): void {
  void Haptics.notification({ type: NotificationType.Success }).catch(() => {
    /* unsupported platform — silently skip */
  });
}
