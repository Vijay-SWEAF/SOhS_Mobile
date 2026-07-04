import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import { setupDailyReminderAfterLaunch } from "./lib/dailyReminder";

const container = document.getElementById("root");
if (!container) throw new Error("Root element #root not found");

void setupDailyReminderAfterLaunch();

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
