#!/bin/sh
# Plays tones through the guest's /dev/dsp into a WAV recording and checks it.
set -eu

repo=$(cd "$(dirname "$0")/../.." && pwd)
sysroot=${TULPAR_AARCH64_SYSROOT:-"$repo/build-aarch64-userland/sysroot"}
cc=${CC:-clang}
work=$(mktemp -d "${TMPDIR:-/tmp}/tulpar-sound.XXXXXX")

cleanup() {
	if [ "${TULPAR_SOUND_KEEP:-0}" = 1 ]; then
		echo "==> Kept $work"
	else
		rm -rf "$work"
	fi
}
trap cleanup EXIT INT TERM

for input in "$sysroot/include" "$sysroot/lib/crt1.o" "$sysroot/lib/libc.a"; do
	if [ ! -e "$input" ]; then
		echo "ERROR: AArch64 test sysroot input is missing: $input" >&2
		echo "       Run ./scripts/build-userland-aarch64.sh first or set TULPAR_AARCH64_SYSROOT." >&2
		exit 1
	fi
done

echo "==> Building static AArch64 sound-test init..."
"$cc" --target=aarch64-linux-musl --sysroot="$sysroot" \
	-static -O2 -fno-stack-protector -Wall -Wextra -Werror \
	"$repo/tests/sound/test.c" -L"$sysroot/lib" -fuse-ld=lld \
	-o "$work/init"

mkdir -p "$work/rootfs/root" "$work/rootfs/sbin"
COPYFILE_DISABLE=1 tar --format=ustar -cf "$work/initramfs.tar" \
	-C "$work/rootfs" .

set -- --init "$work/init" --initramfs "$work/initramfs.tar" \
	--state-dir "$work/vm" --timeout "${TULPAR_QEMU_TIMEOUT:-300}"
if [ -n "${TULPAR_SOUND_ROOT:-}" ]; then
	set -- "$@" --root "$TULPAR_SOUND_ROOT"
fi
if [ "${TULPAR_SOUND_NO_BUILD:-0}" = 1 ]; then
	set -- "$@" --no-build
fi
"$repo/tests/sound/run_vm" "$@"
