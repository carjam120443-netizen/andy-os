#!/usr/bin/env bash
set -euo pipefail

ISO="${1:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"
OUT="${2:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"
WALLPAPER="${3:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/system" "$work/apk" "$work/png"

echo "==> Locating Android-x86 system.sfs"
system_sfs_path="$(xorriso -indev "$ISO" -find / -type f -name 'system.sfs' 2>/dev/null | awk 'NF {p=$NF} END {print p}' | sed "s/^'//;s/'$//")"
if [ -z "$system_sfs_path" ]; then
  echo "ERROR: could not find system.sfs anywhere in the ISO" >&2
  xorriso -indev "$ISO" -find / -maxdepth 2 -type f -print >&2
  exit 1
fi
echo "Found system.sfs at: $system_sfs_path"

echo "==> Extracting Android-x86 system.sfs"
xorriso -osirrox on -indev "$ISO" -extract "$system_sfs_path" "$work/system.sfs"

echo "==> Unpacking system.sfs"
unsquashfs -d "$work/system-root" "$work/system.sfs" >/dev/null

framework="$(find "$work/system-root/system/framework" -maxdepth 1 -type f -name 'framework-res.apk' -print -quit)"
test -n "$framework"

echo "==> Rendering Andy OS wallpaper"
rsvg-convert -w 1920 -h 1080 "$WALLPAPER" -o "$work/png/default_wallpaper.png"

echo "==> Replacing framework default wallpaper"
rm -rf "$work/apk/root"
mkdir -p "$work/apk/root"
unzip -q "$framework" -d "$work/apk/root"

mapfile -t wallpaper_entries < <(find "$work/apk/root/res" -type f \( -name 'default_wallpaper.png' -o -name 'default_wallpaper.jpg' -o -name 'default_wallpaper.jpeg' \))
if [ "${#wallpaper_entries[@]}" -eq 0 ]; then
  echo "ERROR: framework-res.apk has no default_wallpaper resource" >&2
  exit 1
fi

for entry in "${wallpaper_entries[@]}"; do
  case "$entry" in
    *.png) cp "$work/png/default_wallpaper.png" "$entry" ;;
    *.jpg|*.jpeg) convert "$work/png/default_wallpaper.png" -quality 95 "$entry" ;;
  esac
done

rm -rf "$work/apk/repacked"
mkdir -p "$work/apk/repacked"
(
  cd "$work/apk/root"
  zip -q -r -9 "$work/apk/repacked/framework-res.apk" .
)

cp "$work/apk/repacked/framework-res.apk" "$framework"

echo "==> Rebuilding system.sfs"
rm -f "$work/system-new.sfs"
mksquashfs "$work/system-root" "$work/system-new.sfs" -comp xz -b 1048576 -noappend >/dev/null

echo "==> Rebuilding ISO while replaying original boot equipment"
rm -f "$OUT"
xorriso -indev "$ISO" -outdev "$OUT" \
  -map "$work/system-new.sfs" /android/system.sfs \
  -map "$WALLPAPER" /android/andy-os-robot-wallpaper.svg \
  -boot_image any replay \
  -commit -end >/dev/null

echo "==> Customized ISO created: $OUT"
