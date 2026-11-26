#!/usr/bin/env bash
# The integration tests (mobile-build.sh made them) on the connected Android device, against the API in
# config/dev.json. Bounded: a frozen app is not stopped by its own timeout, and adb waits forever for a device that
# is gone. Nothing is retried: why a run ended is android-verdict.sh's to say, from the evidence in $EVIDENCE.
#   cd mobile && ../support/scripts/mobile-emulator.sh
set -uo pipefail
# shellcheck disable=SC2086 # FLUTTER_ENGINE_FLAGS is a list of flags (ADR-0048)
timeout 600 flutter drive --debug --flavor dev --no-dds ${FLUTTER_ENGINE_FLAGS:-} --use-application-binary build/apk/test.apk \
  --driver test_driver/perf_driver.dart --target integration_test/app_test.dart
status=$?
[ "$status" = 0 ] && exit 0
if [ -s "${EVIDENCE:-}/logcat.txt" ]; then
  echo "== the device's last words (all of them: $EVIDENCE/logcat.txt)"
  grep -E "flutter|news\.dev|AndroidRuntime|libc|DEBUG|ANR|lmkd|lowmemory|ActivityManager" "$EVIDENCE/logcat.txt" | tail -60
fi
exit "$status"
