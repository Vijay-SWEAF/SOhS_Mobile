import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#0B1020",
        "ink-2": "#0E1428",
        paper: "#EEF1F8",
        muted: "#93A0BF",
        faint: "#5A6486",
        gold: "#E4B968",
        "gold-deep": "#A9823A",
        teal: "#5FD0C8",
        "teal-deep": "#2C8B86",
      },
      fontFamily: {
        serif: ["Fraunces", "Georgia", "serif"],
        sans: ["Inter", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
} satisfies Config;
