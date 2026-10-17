#!/usr/bin/env bash
# Copy the working tree (without build output or git metadata) to the build
# workstation. Usage: tools/haiku/sync.sh   (remote dir: $GC_REMOTE_DIR)
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
REMOTE_DIR=${GC_REMOTE_DIR:-/boot/home/gridcraft}
cd "$ROOT"
tar -czf - --exclude=./target --exclude=./.git --exclude='*/target' . |
    bash tools/haiku/ws.sh "mkdir -p $REMOTE_DIR && tar xzf - -m -C $REMOTE_DIR"
