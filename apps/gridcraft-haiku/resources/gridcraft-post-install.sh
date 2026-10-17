#!/bin/sh
# GridCraft's post-install script (boot/post-install/gridcraft.sh in the package).
#
# Registers the application with the MIME database, whose packaged record names the machine
# the package was built on, and makes GridCraft the preferred application of the spreadsheet
# types that have none, so a double-click in Tracker opens them before GridCraft has ever run
# (it does the same at each start; the types are services.rs's DOCUMENT_TYPES).
# A preferred application someone already chose stays.
signature=application/x-vnd.storytold-GridCraft
app=$(findpaths -p "$0" B_FIND_PATH_APPS_DIRECTORY GridCraft 2>/dev/null)
[ -n "$app" ] && [ -e "$app" ] && mimeset -a -f "$app"
for type in \
		application/vnd.openxmlformats-officedocument.spreadsheetml.sheet \
		application/vnd.ms-excel.sheet.macroEnabled.12 \
		application/vnd.ms-excel.sheet.binary.macroEnabled.12 \
		application/vnd.ms-excel \
		application/vnd.oasis.opendocument.spreadsheet \
		text/csv \
		text/tab-separated-values; do
	setmime -dump "$type" 2>/dev/null | grep -q -- -preferredAppSig \
		|| setmime -set "$type" -preferredAppSig "$signature"
done
exit 0
