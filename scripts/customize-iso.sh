#!/usr/bin/env bash
set -euo pipefail

ISO="${1:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"
OUT="${2:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"
WALLPAPER="${3:?usage: customize-iso.sh input.iso output.iso wallpaper.svg}"

work="$(mktemp -d)"
system_mount="$work/system-mount"
cleanup() {
  if mountpoint -q "$system_mount" 2>/dev/null; then
    sudo umount "$system_mount" || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/apk" "$work/png" "$system_mount"

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
unsquashfs -d "$work/sfs-root" "$work/system.sfs" >/dev/null

# Android-x86 9.0-r2 stores the actual Android /system filesystem as
# an ext4 system.img inside system.sfs.
system_img="$(find "$work/sfs-root" -type f -name 'system.img' -print -quit)"
if [ -z "$system_img" ]; then
  echo "ERROR: system.img was not found inside system.sfs" >&2
  echo "Extracted system.sfs tree:" >&2
  find "$work/sfs-root" -maxdepth 3 -print | head -150 >&2 || true
  exit 1
fi
echo "Found system.img at: $system_img"

echo "==> Mounting Android-x86 system.img"
sudo mount -o loop "$system_img" "$system_mount"

echo "==> Locating framework-res.apk"
framework="$(find "$system_mount" -type f -name 'framework-res.apk' -print -quit)"
if [ -z "$framework" ]; then
  echo "ERROR: framework-res.apk was not found inside system.img" >&2
  echo "Framework directory candidates:" >&2
  find "$system_mount" -type d -path '*/framework*' -print | head -50 >&2 || true
  echo "Top-level /system tree:" >&2
  find "$system_mount" -maxdepth 3 -type d -print | head -100 >&2 || true
  exit 1
fi
echo "Found framework-res.apk at: $framework"

echo "==> Rendering Andy OS wallpaper"
rsvg-convert -w 1920 -h 1080 "$WALLPAPER" -o "$work/png/default_wallpaper.png"

echo "==> Replacing framework default wallpaper"
rm -rf "$work/apk/root"
mkdir -p "$work/apk/root"
unzip -q "$framework" -d "$work/apk/root"

if [ ! -d "$work/apk/root/res" ]; then
  echo "ERROR: framework-res.apk has no res directory" >&2
  exit 1
fi

mapfile -t wallpaper_entries < <(find "$work/apk/root/res" -type f \( -name 'default_wallpaper.png' -o -name 'default_wallpaper.jpg' -o -name 'default_wallpaper.jpeg' \))
if [ "${#wallpaper_entries[@]}" -eq 0 ]; then
  echo "ERROR: framework-res.apk has no default wallpaper resource" >&2
  find "$work/apk/root/res" -type f -iname '*wallpaper*' -print >&2 || true
  exit 1
fi

echo "Found ${#wallpaper_entries[@]} default wallpaper resource(s)."
for entry in "${wallpaper_entries[@]}"; do
  case "$entry" in
    *.png) cp "$work/png/default_wallpaper.png" "$entry" ;;
    *.jpg|*.jpeg) convert "$work/png/default_wallpaper.png" -quality 95 "$entry" ;;
  esac
done

# The APK contents changed, so stale signing metadata is invalid.
rm -rf "$work/apk/root/META-INF"

rm -rf "$work/apk/repacked"
mkdir -p "$work/apk/repacked"
(
  cd "$work/apk/root"
  zip -q -r -9 "$work/apk/repacked/framework-res.apk" .
)

cp "$work/apk/repacked/framework-res.apk" "$framework"

sync
sudo umount "$system_mount"

echo "==> Rebuilding system.sfs"
rm -f "$work/system-new.sfs"
mksquashfs "$work/sfs-root" "$work/system-new.sfs" -comp xz -b 1048576 -noappend >/dev/null

echo "==> Rebuilding ISO while replaying original boot equipment"
rm -f "$OUT"
xorriso -indev "$ISO" -outdev "$OUT" \
  -map "$work/system-new.sfs" /android/system.sfs \
  -map "$WALLPAPER" /android/andy-os-robot-wallpaper.svg \
  -boot_image any replay \
  -commit -end >/dev/null

echo "==> Customized ISO created: $OUT"
