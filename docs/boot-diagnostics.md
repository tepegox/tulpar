# Serial boot diagnostics — 25 October 2026

Qualified source: `93703bdbda76c212796bf566c77a0a0dc1589c7e`.
Baseline: `73aec358e`.

Production amd64 builds now send normal kernel diagnostics to the serial
console, matching ARM64. PCI discovery includes bus/device/function, vendor
and device IDs, and class/subclass. The device core reports successful driver
attachments. These are built-in drivers; no dynamic module loader was added.
Diagnostics remain available through `/proc/bootlog`.

Initramfs startup reports inflation, module size, and the final entry count.
Per-entry names and `>+!` markers were removed, as were repetitive ARM64
thread-stage messages. Complete zero-filled tar terminators finish quietly.
Malformed signatures and short headers still produce explicit diagnostics;
the next header's length is checked before reading it.

Both `make test-terminal` and `make ARCH=arm64 test-terminal` passed under
QEMU 10.0.13, TCG, 512 MiB RAM and two vCPUs, using V `f7e9ee9` and Clang/LLD
19.1.7. The checks require archive completion and device/driver messages and
reject the old archive noise or malformed-header messages. The amd64 guest
reported PCI Ethernet `8086:100e`, e1000 and AHCI attachments; ARM64 reported
PCI devices and VirtIO networking. Both unpacked 522 entries and passed the
shell, pipes, jobs, ICMP, permission denial, Ctrl-C, restart and poweroff checks.
The header-classification and boot-log host tests also passed.

The QEMU runs preceded the feature commit. After committing, every tracked
kernel source in each build was compared with the qualified source, deleted
UART adapters were confirmed absent, and the ISO/kernel/initramfs hashes were
checked against the run receipts. These checks cover the terminal base in
QEMU, not physical server boards or the entire historical test collection.

Evidence archive:
`/home/artu/.local/state/tulpar/boot-messages-20261025.tar.gz`.

Archive SHA-256: `24fe9a686f3d0b10bfa8065d94259b5be970a616b5b252177ca8fbf176693b08`.

The archive contains both boot images, kernels, initramfs archives, firmware,
generated kernel/init C, source hashes, serial transcripts, guest inventories,
build/test logs, toolchain versions, the feature patch, an incremental Git
bundle requiring the baseline, and `qualified/SHA256SUMS`.
