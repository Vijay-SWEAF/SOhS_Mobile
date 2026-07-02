import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "org.sweaf.sohs",
  appName: "SOhS",
  webDir: "dist",
  backgroundColor: "#0B1020",
  android: {
    allowMixedContent: false,
  },
};

export default config;
