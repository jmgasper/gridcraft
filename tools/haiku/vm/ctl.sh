#!/usr/bin/env bash
# Sends control-channel requests (JSON objects without "id", one per argument) to GridCraft
# running in the test VM with --control 7979, and prints the replies. See
# docs/control-protocol.md for the methods.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
reqs=""
n=1
for r in "$@"; do
    reqs+="${r%\}},\"id\":$n}"$'\n'
    n=$((n + 1))
done
printf '%s' "$reqs" | bash "$HERE/haiku.sh" 'nc -q 3 127.0.0.1 7979 2>/dev/null || nc 127.0.0.1 7979'
