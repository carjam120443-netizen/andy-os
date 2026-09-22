#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/android-x86"

if ! command -v repo >/dev/null 2>&1; then
  echo "ERROR: 'repo' is not installed."
  echo "Install Google's repo tool before running this script."
  exit 1
fi

if [ ! -d "${SRC}/.repo" ]; then
  mkdir -p "${SRC}"
  cd "${SRC}"
  repo init -u "${ANDROID_X86_MANIFEST_URL:-https://git.osdn.net/gitroot/android-x86/manifest}"     -b "${ANDROID_X86_BRANCH:-pie-x86}"
else
  cd "${SRC}"
fi

repo sync --no-tags --no-clone-bundle -j"$(nproc)"
cp "${ROOT}/configs/buildspec.mk" "${SRC}/buildspec.mk"

echo
echo "Andy OS source bootstrap complete."
echo "Source: ${SRC}"
echo "Target: android_x86_64-userdebug"
echo "Next: ./build/build-iso.sh"
