#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$root/build-support/find-v.sh"
TULPAR_PAGING_HOST=1 V="$V" sh "$root/tests/private-pages/run-host.sh"
