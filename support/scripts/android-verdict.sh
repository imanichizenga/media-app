#!/usr/bin/env bash
# Why a device run ended, from the evidence android-emulator.sh and ci-watch.sh kept. Writes DIR/verdict.md and
# prints it; the job adds it to its summary. One of:
#   (a) the app crashed or was killed: a fatal exception, a native crash, an ANR or the low-memory killer naming it
#   (b) the emulator crashed: it exited by itself (a signal of its own, or an error), with no OOM kill on the runner
#   (c) the runner ran out of memory: the kernel's OOM killer took the emulator or something beside it
#   support/scripts/android-verdict.sh DIR [package]
set -uo pipefail
dir="$1" app="${2:-tz.mfano.news}"
log="$dir/logcat.txt" emu="$dir/emulator.log" kern="$dir/dmesg.log"
first() { grep -m 8 -E "$1" "$2" 2> /dev/null; }
crash="$(first "FATAL EXCEPTION|Fatal signal [0-9]+.*$app|>>> $app|ANR in $app|am_crash.*$app|am_anr.*$app" "$log")"
# `am_kill … stop <app> due to from pid` is a force-stop that a script asked for: not a death.
lmk="$(grep -E "(lowmemorykiller|lmkd).*(Kill|kill).*$app|am_kill.*$app|Process $app.* has died" "$log" 2> /dev/null |
  grep -v "due to from pid" | head -8)"
status="$(sed -n 's/^== emulator exited with status //p' "$emu" 2> /dev/null | tail -1)"
# A core is proof the emulator crashed, even if it was still writing it when the job looked.
core="$(sed -n 's/^core: [^ ]*core\.\([^ .]*\)\.[0-9]* binary: \(.*\)/thread \1 of \2/p' "$dir/backtrace.txt" 2> /dev/null)"
[ -n "$core" ] && [ -z "$status" ] && status="crashed ($core)"
emuerr="$(first "Segmentation fault|Aborted|core dumped|FATAL|terminate called|Assertion|crashed|Failed to find ColorBuffer|invalid color buffer" "$emu")"
oom="$(first "Out of memory|oom-kill|Killed process|invoked oom-killer" "$kern")"
{
  echo "### Device verdict"
  if [ -n "$oom" ]; then
    echo "**(c) The runner ran out of memory.** The kernel's OOM killer acted:"
    printf '```\n%s\n```\n' "$oom"
  elif [ -n "$crash" ] || [ -n "$lmk" ]; then
    echo "**(a) The app crashed or was killed** (a product defect until proven otherwise):"
    printf '```\n%s\n%s\n```\n' "$crash" "$lmk"
  elif [ -n "$status" ] || [ -n "$emuerr" ]; then
    echo "**(b) The emulator ended by itself** (status ${status:-unknown}), with no OOM kill on the runner:"
    printf '```\n%s\n```\n' "$emuerr"
    if [ -s "$dir/backtrace.txt" ]; then
      echo "Where it crashed (the first frames of the crashing thread, and the libraries they are in):"
      printf '```\n%s\n```\n' "$(grep -m 25 -E '^#[0-9]+' "$dir/backtrace.txt")"
    fi
  else
    echo "The device was still running at the end: no crash, no kill."
  fi
  [ -n "$status" ] && echo "Emulator exit status: $status"
  [ -e "$dir/watch.md" ] && { echo; tail -n +2 "$dir/watch.md"; }
} > "$dir/verdict.md"
cat "$dir/verdict.md"
