#!/usr/bin/env bash
set -u

check() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK   %-18s %s\n' "$name" "$(command -v "$cmd")"
  else
    printf 'MISS %-18s %s\n' "$name" "$cmd"
    return 1
  fi
}

fail=0
check "git" git || fail=1
check "repo" repo || fail=1
check "java" java || fail=1
check "python3" python3 || fail=1
check "ccache" ccache || fail=1
check "squashfs-tools" mksquashfs || fail=1
check "syslinux" isohybrid || fail=1

if [ "$fail" -eq 0 ]; then
  echo "Environment looks ready for the Andy OS base build."
else
  echo "One or more required host tools are missing."
fi
exit "$fail"
