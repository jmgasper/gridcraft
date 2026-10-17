#!/usr/bin/env bash
# Run a command on the Haiku/air/OS build workstation ("shredder"), where the
# Haiku port is built. Usage: tools/haiku/ws.sh 'command'   (stdin is forwarded)
set -euo pipefail
GC_WS_HOST=${GC_WS_HOST:-192.168.1.247}
GC_WS_USER=${GC_WS_USER:-user}
GC_WS_KEY=${GC_WS_KEY:-/mnt/HaikuWork/x399/ssh/workstation_ed25519}
exec ssh -i "$GC_WS_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
    -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR \
    -o ConnectTimeout=15 -o ServerAliveInterval=30 -o ServerAliveCountMax=8 \
    "$GC_WS_USER@$GC_WS_HOST" "$@"
