#!/bin/sh
set -eu

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export HOME=/root
export TULPAR_QEMU_STATE_DIR=/root
export TULPAR_QEMU_GUEST_MEM=512

echo 'TULPAR NESTED QEMU: START'
if ! tulpar-qemu /root/tulpar-inner.img; then
    echo 'TULPAR NESTED QEMU: FAIL'
fi

sync
/sbin/poweroff -f 2>/dev/null
exec /bin/sh
