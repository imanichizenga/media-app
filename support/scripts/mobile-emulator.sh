#!/usr/bin/env bash
# The integration tests (mobile-build.sh made them) on the connected Android device, against the API in
# config/dev.json. Bounded everywhere: a frozen app is not stopped by its own timeout, and adb waits forever for a
# device that is gone. If no test failed and the device did not last, build/emulator-lost says so.
#   cd mobile && ../support/scripts/mobile-emulator.sh
set -uo pipefail
out="$(mktemp)"
adb() { timeout 60 "$(type -P adb)" "$@"; }
adb logcat -c
timeout 600 flutter drive --debug --flavor dev --no-dds --use-application-binary build/apk/test.apk \
  --driver test_driver/perf_driver.dart --target integration_test/app_test.dart 2>&1 | tee "$out"
[ "${PIPESTATUS[0]}" = 0 ] && exit 0
echo "== the device's last words"
adb logcat -d -t 600 | grep -E "flutter|news.dev|AndroidRuntime|libc|ANR|DEBUG" | tail -80
# Every test names its failure; a device that went away names none.
grep -qE 'Test failed|Failure Details|Failure in method|EXCEPTION CAUGHT' "$out" || touch build/emulator-lost
exit 1
