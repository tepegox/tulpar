#!/bin/sh
set -eu

echo "TULPAR ARM64 NETWORK TOOLS TEST"
curl --version
git --version
ssh -V
apk --version
pkg --help
xbps-query --version

if [ -n "${TULPAR_NETWORK_SMOKE_URL:-}" ]; then
    echo "fetching $TULPAR_NETWORK_SMOKE_URL"
    body="$(curl --fail --silent --show-error "$TULPAR_NETWORK_SMOKE_URL")"
    test "$body" = "tulpar-network-ok"
fi

echo "TULPAR ARM64 NETWORK TOOLS TEST: PASS"
