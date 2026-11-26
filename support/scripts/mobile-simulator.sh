#!/usr/bin/env bash
# The integration tests on a booted iOS simulator, against the recorded API (support/tests/replay.mjs).
# Bounded, and never retried: a run that never attaches to the app is a fault to find, not to hide. The tool's
# verbose log goes to $EVIDENCE/flutter-test.log for that; the console shows the tests.
#   cd mobile && ../support/scripts/mobile-simulator.sh
set -uo pipefail
evidence="${EVIDENCE:-build}"
mkdir -p "$evidence"
bounded() { perl -e '$SIG{ALRM} = sub { kill "TERM", -$$; exit 124 }; alarm shift; setpgrp; system @ARGV; exit($? >> 8)' "$@"; }
device=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("iPhone"))][0].udid')
xcrun simctl list devices | grep "$device" | tee "$evidence/simulator.txt"
# The tool asks xcodebuild for the build settings with a one-minute limit; twice in ten runs it took longer (98 s, then
# over 60 s: resolving the package graph, Sentry from GitHub, and the simulator destinations) and no test started
# (ADR-0048). The same question asked here first, bounded at ten minutes, leaves xcodebuild's caches warm.
start=$SECONDS
bounded 600 xcrun xcodebuild -project ios/Runner.xcodeproj -scheme dev -configuration Debug-dev -sdk iphonesimulator \
  -destination "id=$device" -clonedSourcePackagesDirPath build/ios/SourcePackages -showBuildSettings \
  > "$evidence/build-settings.log" 2>&1 || echo "::warning title=Xcode::The build settings did not come (see build-settings.log)"
echo "Build settings in $((SECONDS - start)) s" | tee -a "$evidence/simulator.txt"
xcrun simctl boot "$device" 2> /dev/null
xcrun simctl bootstatus "$device" -b > /dev/null
bounded 1200 flutter test integration_test -v -d "$device" --flavor dev --dart-define-from-file=config/dev-ios.json \
  --timeout 4m --reporter expanded 2>&1 | tee "$evidence/flutter-test.log" | grep -vE '^\[ *\+?[0-9]+ ms\]'
status="${PIPESTATUS[0]}"
[ "$status" = 0 ] && exit 0
grep -qE '^[0-9]{2}:[0-9]{2} \+[0-9]+' "$evidence/flutter-test.log" ||
  echo "::error title=Simulator::No test started (status $status). The tool's last steps: $evidence/flutter-test.log"
exit "$status"
