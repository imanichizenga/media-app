#!/usr/bin/env bash
# What the runner was doing while a device test ran: memory every 5 s with the largest processes, and the kernel's
# own log (the OOM killer writes there). Evidence for a job that loses its emulator or simulator.
#   support/scripts/ci-watch.sh start DIR      in the background until stop
#   support/scripts/ci-watch.sh stop DIR       stops, and writes the peak and every OOM line to DIR/watch.md
set -euo pipefail
cmd="$1" dir="$2"
mkdir -p "$dir"
case "$cmd" in
  start)
    nohup bash -c '
      while :; do
        echo "== $(date -u +%T)"
        if command -v free > /dev/null; then free -m | sed -n "2,3p"; else memory_pressure -Q | tail -1; fi
        ps -Ao rss=,comm= | sort -rn | head -6 | awk "{ printf \"  %6d MB %s\n\", \$1 / 1024, \$2 }"
        sleep 5
      done' > "$dir/memory.log" 2>&1 &
    echo $! > "$dir/.watch.pid"
    if [ "$(uname)" = Linux ]; then
      sudo dmesg -c > /dev/null 2>&1 || true
      nohup sudo dmesg -w -T > "$dir/dmesg.log" 2>&1 &
      echo $! > "$dir/.dmesg.pid"
    else
      nohup log stream --style compact --predicate 'eventMessage CONTAINS[c] "jetsam" OR eventMessage CONTAINS[c] "memorystatus"' \
        > "$dir/dmesg.log" 2>&1 &
      echo $! > "$dir/.dmesg.pid"
    fi
    ;;
  stop)
    for f in "$dir"/.watch.pid "$dir"/.dmesg.pid; do
      [ -e "$f" ] && { sudo kill "$(cat "$f")" 2> /dev/null || kill "$(cat "$f")" 2> /dev/null || true; rm -f "$f"; }
    done
    {
      echo "### Runner memory"
      # free -m on Linux: "Mem: total used free shared buff/cache available"
      awk '/^Mem:/ { if ($3 > used) used = $3; if (min == "" || $7 < min) min = $7; total = $2 }
           END { if (total) printf "Peak used %d MB of %d MB; least available %d MB\n", used, total, min }' "$dir/memory.log"
      oom="$(grep -iE 'out of memory|oom-kill|killed process|invoked oom-killer' "$dir/dmesg.log" 2> /dev/null || true)"
      if [ -n "$oom" ]; then printf '\n**The kernel killed a process:**\n```\n%s\n```\n' "$oom"; else echo "No OOM kill in the kernel log."; fi
    } > "$dir/watch.md"
    cat "$dir/watch.md"
    ;;
esac
