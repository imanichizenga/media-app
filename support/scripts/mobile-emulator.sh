#!/usr/bin/env bash
# The integration tests on the connected Android device, against the API in config/dev.json. Bounded: a test that
# freezes the app is not stopped by its own timeout. Then what the device said is shown.
#   cd mobile && ../support/scripts/mobile-emulator.sh
set -uo pipefail
run() {
  timeout 900 flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json --timeout 4m \
    --reporter expanded
}
adb logcat -c
run && exit 0
echo "== the device's last words"
adb logcat -d -t 600 | grep -E "flutter|ActivityManager|AndroidRuntime|libc|ANR|DEBUG" | tail -120
exit 1
