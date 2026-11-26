#!/usr/bin/env bash
# The three apps the emulator runs, built beforehand: the tests, the measuring, and the app that is measured.
#   cd mobile && ../support/scripts/mobile-build.sh
set -euo pipefail
common=(--flavor dev --dart-define-from-file=config/dev.json --target-platform android-x64)
out=build/app/outputs/flutter-apk
mkdir -p build/apk
flutter build apk --debug "${common[@]}" --target integration_test/app_test.dart
cp "$out/app-dev-debug.apk" build/apk/test.apk
flutter build apk --profile "${common[@]}" --target test_driver/perf.dart
cp "$out/app-dev-profile.apk" build/apk/perf.apk
flutter build apk --profile "${common[@]}" --target lib/main.dart
cp "$out/app-dev-profile.apk" build/apk/app.apk
