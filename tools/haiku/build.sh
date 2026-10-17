#!/usr/bin/env bash
# Cross-compiles GridCraft for air/OS (Haiku x86_64): target/x86_64-unknown-haiku/release/GridCraft.
# See docs/haiku.md for the toolchain (rustup stable with rust-src, the Haiku sysroot).
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"
. tools/haiku/env.sh
GRIDCRAFT_BUILD_SHA=${GRIDCRAFT_BUILD_SHA:-$(git rev-parse HEAD 2>/dev/null || echo dev)} \
	cargo build --release --target x86_64-unknown-haiku -Zbuild-std=std,panic_abort -p gridcraft-haiku "$@"
