import { Haptics, ImpactStyle, NotificationType } from "@capacitor/haptics";

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
