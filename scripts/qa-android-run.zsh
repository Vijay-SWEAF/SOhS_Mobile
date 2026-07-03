#!/bin/zsh
set -euo pipefail

TARGET="${1:-${ANDROID_TARGET:-}}"

npm run build
npx cap sync android

if [[ -n "${TARGET}" ]]; then
  npx cap run android --target "${TARGET}"
else
  npx cap run android
fi
