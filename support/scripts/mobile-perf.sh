#!/usr/bin/env bash
# Frames and cold starts of a profile build on the connected Android device, against the API in config/dev.json.
#   cd mobile && ../support/scripts/mobile-perf.sh
# Writes build/perf.json and build/perf.md; fails above the budgets in support/docs/perf/mobile.md.
set -euo pipefail
app="tz.mfano.news.dev"
main="$app/tz.mfano.news_app.MainActivity"
flags=(--profile --flavor dev --dart-define-from-file=config/dev.json)
# Built first, so that nothing compiles while something is measured.
echo "== building the app"; date -u
timeout 1200 flutter build apk "${flags[@]}" --target-platform android-x64 --target lib/main.dart
cp build/app/outputs/flutter-apk/app-dev-profile.apk build/app-profile.apk
echo "== frames"; date -u
# The test connects to the VM service from the device; the debug proxy (DDS) listens on the computer only.
timeout 1200 flutter drive "${flags[@]}" --no-dds --driver test_driver/perf_driver.dart --target test_driver/perf.dart --keep-app-running
echo "== cold starts"; date -u
# The app itself over the measuring one; its storage stays.
adb shell am force-stop "$app"
adb install -r build/app-profile.apk
adb shell cmd connectivity airplane-mode enable
sleep 5
times=()
for run in 0 1 2 3 4 5 6; do
  adb shell am force-stop "$app"
  sleep 3
  adb logcat -c
  adb shell am start -W -n "$main" > /dev/null
  line=""
  for _ in $(seq 20); do
    line="$(adb logcat -d -s ActivityTaskManager:I | grep "Fully drawn $app" || true)"
    [ -n "$line" ] && break
    sleep 0.5
  done
  [ -n "$line" ] || { echo "no news was drawn"; adb logcat -d -t 200; exit 1; }
  # The first only warms the disk.
  ms="$(sed -E 's/.*\+(([0-9]+)s)?([0-9]+)ms.*/\2 \3/' <<< "$line" | awk 'NF == 2 { print $1 * 1000 + $2; next } { print $1 }')"
  echo "cold start $run: $ms ms"
  [ "$run" = 0 ] || times+=("$ms")
done
adb shell cmd connectivity airplane-mode disable
python3 -I "$(dirname "$0")/mobile-perf.py" build/integration_response_data.json build "${times[@]}"
