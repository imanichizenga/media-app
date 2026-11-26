#!/usr/bin/env bash
# The Android emulator the device tests run on, started by us so that nothing it says is lost: its own output goes to
# DIR/emulator.log, every log buffer of the device (logcat -b all) to DIR/logcat.txt from the moment adb sees it.
# The configuration is ADR-0048's; change it there first.
#   support/scripts/android-emulator.sh start DIR     boots it and waits (at most 5 minutes)
#   support/scripts/android-emulator.sh stop DIR      collects what the device left (tombstones, ANR traces) and stops it
set -euo pipefail
cmd="$1" dir="$2"
mkdir -p "$dir"
api="${EMULATOR_API:-34}"
target="${EMULATOR_TARGET:-google_apis}"
ram="${EMULATOR_RAM:-3072}"
heap="${EMULATOR_HEAP:-512}"
cores="${EMULATOR_CORES:-2}"
image="system-images;android-$api;$target;x86_64"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
export PATH="$sdk/emulator:$sdk/platform-tools:$sdk/cmdline-tools/latest/bin:$PATH"
# One place for the AVD, whatever the tools' version thinks the default is.
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
mkdir -p "$ANDROID_AVD_HOME"
adb() { timeout 60 "$(type -P adb)" "$@"; }

case "$cmd" in
  start)
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    sdkmanager --install emulator platform-tools "$image" > /dev/null
    echo "no" | avdmanager create avd --force -n ci --abi "$target/x86_64" --package "$image" > /dev/null
    cfg="$ANDROID_AVD_HOME/ci.avd/config.ini"
    # Fixed, so that a run is the same as the last: screen 320×640 at 160 dpi (what the tests were written on).
    cat >> "$cfg" << CFG
hw.ramSize=$ram
vm.heapSize=$heap
hw.cpu.ncore=$cores
disk.dataPartition.size=6G
hw.lcd.width=320
hw.lcd.height=640
hw.lcd.density=160
hw.keyboard=yes
hw.audioInput=no
hw.audioOutput=no
hw.camera.back=none
hw.camera.front=none
hw.gpu.enabled=yes
hw.gpu.mode=swiftshader_indirect
CFG
    emulator -version | head -1 | tee "$dir/emulator-version.txt"
    echo "$image ram=${ram}M heap=${heap}M cores=$cores ${EMULATOR_OPTIONS:-}" | tee "$dir/config.txt"
    # shellcheck disable=SC2086
    # How it ended is written last: 137 is a kill from outside (the OOM killer), 139 and 134 are its own crash.
    nohup bash -c "emulator -avd ci -port 5554 -no-window -no-snapshot -no-boot-anim -no-audio -gpu swiftshader_indirect \
      -camera-back none -camera-front none -accel on ${EMULATOR_OPTIONS:-}; echo \"== emulator exited with status \$?\"" \
      > "$dir/emulator.log" 2>&1 &
    echo $! > "$dir/.emulator.pid"
    "$(type -P adb)" start-server > /dev/null
    nohup bash -c "'$(type -P adb)' -s emulator-5554 wait-for-device && exec '$(type -P adb)' -s emulator-5554 logcat -b all -v threadtime,UTC" \
      > "$dir/logcat.txt" 2>&1 &
    echo $! > "$dir/.logcat.pid"
    for _ in $(seq 150); do
      [ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ] && break
      kill -0 "$(cat "$dir/.emulator.pid")" 2> /dev/null || { echo "The emulator exited while booting"; tail -50 "$dir/emulator.log"; exit 1; }
      sleep 2
    done
    [ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ] || { echo "No boot in 5 minutes"; exit 1; }
    adb -s emulator-5554 shell input keyevent 82
    adb -s emulator-5554 logcat -G 16M || true
    adb -s emulator-5554 shell settings put global package_verifier_user_consent -1 || true
    echo "Booted in ${SECONDS}s"
    ;;
  stop)
    if [ "$(adb -s emulator-5554 get-state 2> /dev/null)" = device ]; then
      adb -s emulator-5554 root > /dev/null 2>&1 && sleep 2 || true
      adb -s emulator-5554 pull /data/tombstones "$dir/tombstones" > /dev/null 2>&1 || true
      adb -s emulator-5554 pull /data/anr "$dir/anr" > /dev/null 2>&1 || true
      adb -s emulator-5554 emu kill > /dev/null 2>&1 || true
    else
      echo "The device was already gone"
    fi
    for f in "$dir"/.logcat.pid "$dir"/.emulator.pid; do
      [ -e "$f" ] && { kill "$(cat "$f")" 2> /dev/null || true; rm -f "$f"; }
    done
    # Crash reports the emulator itself wrote, if it crashed rather than being killed.
    find /tmp "$HOME/.android" -maxdepth 3 \( -name 'emu-crash*' -o -name '*.dmp' \) -newer "$dir/config.txt" \
      -exec cp -r {} "$dir/" \; 2> /dev/null || true
    ;;
esac
