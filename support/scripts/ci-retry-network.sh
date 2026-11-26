#!/usr/bin/env bash
# Runs a command once more only when its first failure was the network's, proven by what it printed: a name that did
# not resolve, a connection reset or refused by a remote host, a download that timed out, a server error from a
# registry, a registry's rate limit (429). Any other failure fails at once. A retry is written to $EVIDENCE/retries.md (the job's summary shows it)
# with the lines that proved it.
#   support/scripts/ci-retry-network.sh <command> [args…]
set -uo pipefail
out="$(mktemp)"
"$@" 2>&1 | tee "$out"
status="${PIPESTATUS[0]}"
[ "$status" = 0 ] && exit 0
proof="$(grep -m 5 -iE 'could not resolve host|temporary failure in name resolution|connection (reset|refused|timed out)|read timed out|connect timed out|socketexception|handshakeexception|unexpected end of stream|remote host terminated|http(s)? (status )?(code )?5[0-9]{2}|status code 5[0-9]{2}|502 bad gateway|503 service unavailable|failed host lookup|status code 429|too many requests|error while downloading artifacts from the network' "$out")"
if [ -z "$proof" ]; then
  echo "Failed with status $status, and not because of the network: not retried."
  exit "$status"
fi
{
  echo "### Retried: \`$*\`"
  echo "The first attempt failed (status $status) on the network:"
  printf '```\n%s\n```\n' "$proof"
} | tee -a "${EVIDENCE:-.}/retries.md"
echo "::warning title=Network retry::$* failed on the network and was run once more (see the job summary)"
sleep 90 # a rate limit needs longer than a dropped connection
"$@"
