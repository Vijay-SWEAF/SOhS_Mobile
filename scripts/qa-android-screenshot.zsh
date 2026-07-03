#!/bin/zsh
set -euo pipefail

OUTPUT="${1:-/private/tmp/sohs_mobile_qa_$(date +%Y%m%d_%H%M%S).png}"

adb exec-out screencap -p > "${OUTPUT}"
echo "Saved screenshot: ${OUTPUT}"
