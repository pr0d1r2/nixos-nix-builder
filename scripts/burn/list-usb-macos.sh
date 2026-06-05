#!/usr/bin/env bash
# macOS USB block-device enumerator.
# Output: <device>|<size>|<model>

set -Eeuo pipefail

plist="$(diskutil list -plist external physical 2>/dev/null || true)"
if [ -z "$plist" ]; then exit 0; fi

disks="$(
    python3 - "$plist" <<'PY'
import plistlib, sys
data = plistlib.loads(sys.argv[1].encode())
for d in data.get("AllDisksAndPartitions", []):
    print(d.get("DeviceIdentifier", ""))
PY
)"

while IFS= read -r dev; do
    [ -z "$dev" ] && continue
    info="$(diskutil info -plist "$dev" 2>/dev/null || true)"
    size="$(
        python3 - "$info" <<'PY'
import plistlib, sys
d = plistlib.loads(sys.argv[1].encode())
gb = d.get("TotalSize", 0) / (1024**3)
print(f"{int(gb)}G")
PY
    )"
    model="$(
        python3 - "$info" <<'PY'
import plistlib, sys
d = plistlib.loads(sys.argv[1].encode())
print(d.get("MediaName", "USB device"))
PY
    )"
    printf '/dev/%s|%s|%s\n' "$dev" "$size" "$model"
done <<<"$disks"
