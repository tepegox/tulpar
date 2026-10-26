#!/bin/sh
# PID 1 for the automated Docker VM test (scripts/run-aarch64.sh --guest-init).
export HOME=/root
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export TERM=linux

echo
echo "TULPAR DOCKER TEST: START"
if /root/docker-smoke.sh; then
	echo "TULPAR DOCKER TEST: PASS"
else
	echo "TULPAR DOCKER TEST: FAIL"
fi
sync
/sbin/poweroff -f 2>/dev/null
exec /bin/sh
