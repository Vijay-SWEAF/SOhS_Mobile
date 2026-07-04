#!/bin/zsh
set -euo pipefail

APP_ID="${SOHS_ANDROID_APP_ID:-biz.sweaf.sohs}"

echo "Connected devices:"
adb devices
echo
echo "Clearing local app data for ${APP_ID}..."
adb shell pm clear "${APP_ID}"
echo
echo "Done. This resets local Preferences and cache only; Supabase app_* rows are unchanged."
