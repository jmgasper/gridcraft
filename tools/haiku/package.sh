#!/usr/bin/env bash
# Builds GridCraft for air/OS and packages it as an .hpkg.
#
# The binary is cross-compiled here (tools/haiku/build.sh); the resources,
# MIME attributes and the package itself are made on a Haiku machine, because
# rc, xres, mimeset and package are Haiku tools: the test VM by default
# (tools/haiku/vm/haiku.sh), or the workstation with GC_PKG_HOST=ws.
# The package lands in artifacts/haiku/. Usage: tools/haiku/package.sh
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"
RES=apps/gridcraft-haiku/resources
NAME=$(awk '$1 == "name" { print $2; exit }' $RES/GridCraft.PackageInfo)
VERSION=$(awk '$1 == "version" { print $2; exit }' $RES/GridCraft.PackageInfo)
FILE=$NAME-$VERSION-x86_64.hpkg
case ${GC_PKG_HOST:-vm} in
	ws) RUN="bash tools/haiku/ws.sh" ;;
	*) RUN="bash tools/haiku/vm/haiku.sh" ;;
esac

bash tools/haiku/build.sh
mkdir -p artifacts/haiku
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/gridcraft-pkg-XXXXXX")
trap 'rm -rf -- "$STAGE"' EXIT
. tools/haiku/env.sh
"$HAIKU_CROSS-strip" -o "$STAGE/GridCraft" target/x86_64-unknown-haiku/release/GridCraft
cp $RES/GridCraft.rdef $RES/GridCraft.hvif $RES/GridCraft.PackageInfo $RES/gridcraft-post-install.sh README.md \
	LICENSE-MIT LICENSE-APACHE NOTICE docs/haiku.md "$STAGE/"

REMOTE=/tmp/gridcraft-package
tar -C "$STAGE" -czf - . | $RUN "rm -rf $REMOTE && mkdir -p $REMOTE/in && tar -xzf - -C $REMOTE/in && cd $REMOTE && \
	S=$REMOTE/stage && DOCS=\$S/documentation/packages/gridcraft && \
	mkdir -p \$S/apps \$S/data/deskbar/menu/Applications \$S/boot/post-install \$DOCS && \
	cp in/gridcraft-post-install.sh \$S/boot/post-install/gridcraft.sh && chmod 755 \$S/boot/post-install/gridcraft.sh && \
	cp in/GridCraft \$S/apps/GridCraft && \
	(cd in && rc -o GridCraft.rsrc GridCraft.rdef) && xres -o \$S/apps/GridCraft in/GridCraft.rsrc && \
	cp in/README.md in/LICENSE-MIT in/LICENSE-APACHE in/NOTICE in/haiku.md \$DOCS/ && \
	ln -s ../../../../apps/GridCraft \$S/data/deskbar/menu/Applications/GridCraft && \
	cp in/GridCraft.PackageInfo \$S/.PackageInfo && \
	(cd \$S && mimeset --all -f --mimedb data/mime_db --mimedb /boot/system/data/mime_db apps/GridCraft) && \
	rmattr META:PPATH \$S/data/mime_db/application/x-vnd.storytold-gridcraft && \
	package create -C \$S $REMOTE/$FILE && rm -rf \$S && package list $REMOTE/$FILE | tail -3" >&2
$RUN "cat $REMOTE/$FILE" > "artifacts/haiku/$FILE"
ls -l "artifacts/haiku/$FILE" >&2
echo "artifacts/haiku/$FILE"
