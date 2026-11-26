#!/usr/bin/env bash
# The integration tests on a booted iOS simulator, against the recorded API (support/tests/replay.mjs).
# Bounded: a test run that never attaches to the app prints nothing and waits forever. If no test started, the
# simulator is erased and tried once more; a test that failed is never tried again.
#   cd mobile && ../support/scripts/mobile-simulator.sh
set -uo pipefail
bounded() { perl -e '$SIG{ALRM} = sub { kill "TERM", -$$; exit 124 }; alarm shift; setpgrp; system @ARGV; exit($? >> 8)' "$@"; }
device=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("iPhone"))][0].udid')
for attempt in 1 2; do
  xcrun simctl boot "$device" 2> /dev/null; xcrun simctl bootstatus "$device" -b > /dev/null
  out="$(mktemp)"
  bounded 1200 flutter test integration_test -d "$device" --flavor dev --dart-define-from-file=config/dev-ios.json \
    --timeout 4m --reporter expanded 2>&1 | tee "$out"
  [ "${PIPESTATUS[0]}" = 0 ] && exit 0
  # Every test that ran names itself with a count ("00:12 +1: …"); a run that never attached has none.
  if grep -qE '^[0-9]{2}:[0-9]{2} \+[0-9]+.*: [^l]' "$out" || [ "$attempt" = 2 ]; then exit 1; fi
  echo "::warning title=Simulator::The tests never attached to the app; trying once on an erased simulator"
  xcrun simctl shutdown "$device" || true
  xcrun simctl erase "$device"
done
