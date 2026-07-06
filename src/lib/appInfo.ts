import { App } from "@capacitor/app";
import { Capacitor } from "@capacitor/core";

export interface AppVersionInfo {
  version: string;
  build: string;
  label: string;
}

export async function getAppVersionInfo(): Promise<AppVersionInfo | null> {
  if (!Capacitor.isNativePlatform()) {
    return null;
  }

  try {
    const info = await App.getInfo();
    const version = info.version ?? "";
    const build = info.build ?? "";

    if (!version && !build) {
      return null;
    }

    return {
      version,
      build,
      label: build ? `v${version} (${build})` : `v${version}`,
    };
  } catch {
    return null;
  }
}
