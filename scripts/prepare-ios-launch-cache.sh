#!/usr/bin/env bash
# Fetch the iPhone 17 iOS 26.5 filesystem and export its original launchd.plist.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

DEVICE="iPhone18,3"
IOS_VERSION="26.5"
OUT="$repo_root/out/ipsw"
IPSW_DIR="$OUT/firmware"
ROOT_MOUNT="$RUNNER_TEMP/b2l-ios26-root"
SYS_MOUNT="$RUNNER_TEMP/b2l-ios26-systemos"
mkdir -p "$IPSW_DIR" "$ROOT_MOUNT" "$SYS_MOUNT"

cleanup() {
  for mountpoint in "$SYS_MOUNT" "$ROOT_MOUNT"; do
    if mount | grep -Fq " on $mountpoint ("; then
      hdiutil detach "$mountpoint" -quiet || diskutil unmount "$mountpoint" >/dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT

if ! command -v ipsw >/dev/null 2>&1; then
  brew install blacktop/tap/ipsw
fi

ipsw download ipsw --device "$DEVICE" --version "$IOS_VERSION" --output "$IPSW_DIR" --confirm
IPSW="$(find "$IPSW_DIR" -maxdepth 1 -type f -name '*.ipsw' -print -quit)"
[[ -n "$IPSW" && -s "$IPSW" ]] || {
  echo "::error::No iPhone 17 iOS $IOS_VERSION IPSW was downloaded."
  exit 1
}

find_launchd() {
  local root="$1"
  find "$root" -type f -path '*/System/Library/xpc/launchd.plist' -print -quit 2>/dev/null
}

# First inspect the root filesystem; on newer releases the file may live in SystemOS.
ipsw mount fs "$IPSW" --mount-point "$ROOT_MOUNT" --detach
for _ in $(seq 1 120); do
  mount | grep -Fq " on $ROOT_MOUNT (" && break
  sleep 2
done
SOURCE="$(find_launchd "$ROOT_MOUNT")"

if [[ -z "$SOURCE" ]]; then
  ipsw mount sys "$IPSW" --device "$DEVICE" --mount-point "$SYS_MOUNT" --detach
  for _ in $(seq 1 120); do
    mount | grep -Fq " on $SYS_MOUNT (" && break
    sleep 2
  done
  SOURCE="$(find_launchd "$SYS_MOUNT")"
fi

[[ -n "$SOURCE" && -s "$SOURCE" ]] || {
  echo "::error::The iPhone 17 iOS $IOS_VERSION IPSW contains no System/Library/xpc/launchd.plist in FileSystem or SystemOS."
  exit 1
}

mkdir -p "$OUT"
cp "$SOURCE" "$OUT/launchd.plist"
python3 - "$OUT/launchd.plist" <<'PY'
import pathlib, plistlib, sys
p = pathlib.Path(sys.argv[1])
data = p.read_bytes()
if not data or len(data) > 16 * 1024 * 1024:
    raise SystemExit("Invalid launchd.plist size")
value = plistlib.loads(data)
if not isinstance(value, dict) or not isinstance(value.get("LaunchDaemons"), dict):
    raise SystemExit("launchd.plist has no LaunchDaemons dictionary")
print(f"Validated source launchd.plist: {len(data)} bytes; {len(value['LaunchDaemons'])} daemon entries")
PY
echo "IOS_SOURCE_DEVICE=$DEVICE" >> "$GITHUB_ENV"
echo "IOS_SOURCE_VERSION=$IOS_VERSION" >> "$GITHUB_ENV"
echo "Prepared source: $OUT/launchd.plist"
