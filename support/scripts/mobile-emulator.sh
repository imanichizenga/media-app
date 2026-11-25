#!/usr/bin/env bash
# The integration tests on the connected Android device, against the API in config/dev.json. Bounded: a test that
# freezes the app is not stopped by its own timeout. Then what the device said is shown.
# An emulator sometimes installs the app and never attaches to it. Then, and only then, it is tried once more: a test
# that started and failed is a failure.
#   cd mobile && ../support/scripts/mobile-emulator.sh
set -uo pipefail
out="$(mktemp)"
run() {
  timeout "$1" flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json --timeout 4m \
    --reporter expanded 2>&1 | tee "$out"
}
words() {
  echo "== the device's last words"
  adb logcat -d -t 600 | grep -E "flutter|news.dev|AndroidRuntime|libc|ANR|DEBUG" | tail -80
}
adb logcat -c
run 480 && exit 0
words
grep -qE '^[0-9:]+ \+[0-9]+.*: first launch' "$out" && exit 1
echo "::warning title=Emulator::No test started; trying once more"
adb shell am force-stop tz.mfano.news.dev
adb uninstall tz.mfano.news.dev
adb reboot
adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 2; done'
sleep 10
adb shell input keyevent 82
adb logcat -c
run 900 && exit 0
words
exit 1
