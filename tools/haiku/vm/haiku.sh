#!/usr/bin/env bash
# Runs a command in the GridCraft test VM over SSH (port 2230). See run-vm.sh.
set -euo pipefail
DIR=${GC_VM_DIR:-/mnt/HaikuWork/tmp/gridcraft-vm}
exec ssh -i "$DIR/id_ed25519" -p 2230 -o IdentitiesOnly=yes -o BatchMode=yes \
    -o UserKnownHostsFile="$DIR/known_hosts" -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 -o ServerAliveInterval=30 user@127.0.0.1 "$@"
