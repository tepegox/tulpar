#!/bin/sh
# Compile and boot the security MAC regression against an already-built kernel.
set -eu
repo=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
arch=${1:-aarch64}
case "$arch" in
  aarch64) ;;
  amd64|x86_64) arch=x86_64 ;;
  *) echo "usage: $0 [aarch64|x86_64]" >&2; exit 2 ;;
esac
kernel=${TULPAR_KERNEL_DIR:-"$repo/kernel"}
if [ -n "${TULPAR_MAC_STATE_DIR:-}" ]; then
  exec "$repo/tests/kernel-gaps/run-native" \
    --source "$repo/tests/security-mac/guestfixture/core.v" --arch "$arch" \
    --kernel-dir "$kernel" --state-dir "$TULPAR_MAC_STATE_DIR" --no-network \
    --expect 'SECURITY MAC PASS' --fail 'SECURITY MAC FAIL' \
    --timeout "${TULPAR_QEMU_TIMEOUT:-300}"
fi
exec "$repo/tests/kernel-gaps/run-native" \
  --source "$repo/tests/security-mac/guestfixture/core.v" --arch "$arch" \
  --kernel-dir "$kernel" --no-network \
  --expect 'SECURITY MAC PASS' --fail 'SECURITY MAC FAIL' \
  --timeout "${TULPAR_QEMU_TIMEOUT:-300}"
