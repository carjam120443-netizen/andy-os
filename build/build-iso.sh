#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/android-x86"

if [ ! -d "${SRC}" ]; then
  echo "Android-x86 source is missing."
  echo "Run ./scripts/bootstrap.sh first."
  exit 1
fi

cd "${SRC}"
source build/envsetup.sh

TARGET="${ANDROID_X86_TARGET:-android_x86_64}"
VARIANT="${ANDROID_X86_VARIANT:-userdebug}"
JOBS="${JOBS:-$(nproc)}"

lunch "${TARGET}-${VARIANT}"
m -j"${JOBS}" iso_img

ISO="out/target/product/${TARGET}/${TARGET}.iso"
if [ -f "${ISO}" ]; then
  echo
  echo "=========================================="
  echo " Andy OS ISO build completed"
  echo " ${ISO}"
  echo "=========================================="
else
  echo "Build finished without the expected ISO: ${ISO}"
  exit 1
fi
