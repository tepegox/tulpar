# Terminal base qualification — 25 October 2026

Source revision: `370d69b1d2ca38d0a6f003016c708327c55d60bc`.

Both supported images were rebuilt after removing the desktop, X11,
Hyprland, Android and application build layers. The images contain the
pinned Alpine 3.21.7 minirootfs and the same small V PID 1, which starts
BusyBox `/bin/sh`, reaps children and restarts the shell. Build-only musl
headers and static libraries stay outside the guest filesystem.

| Target | ISO bytes | Uncompressed initramfs bytes | Headless QEMU |
| --- | ---: | ---: | --- |
| amd64 | 21,024,768 | 8,130,560 | PASS |
| ARM64 | 27,887,616 | 8,468,480 | PASS |

Each guest ran under TCG with 512 MiB RAM and two vCPUs. The committed
checker exercised serial input, architecture reporting, shell arithmetic,
file creation, pipelines, background execution and wait status, terminal
settings, Ctrl-C interruption, shell exit/restart and guest poweroff.
Image inventory checks reject desktop/X11/Hyprland/Android binaries,
Zsh, Vim, Oh My Zsh and guest compilers. QEMU exited successfully in both
checks and neither serial transcript contains a kernel panic.

The shared host value/transport tests passed. Package-store, verified-boot,
ext2 and LinuxKPI host tools compiled after extracting their shared helpers
from the removed Android and game trees. This does not qualify all historical
test suites, networking, server workloads or real hardware. Kernel terminal
and framebuffer device support remain available for text consoles.

Reproduce the image build and guest checks with:

```sh
make test-terminal
make ARCH=arm64 test-terminal
```

Complete evidence is retained outside Git:

`/home/artu/.local/state/tulpar/terminal-qualification-20261025.tar.gz`

Archive SHA-256: `39180d3f7fb4469b05b4a37f6f53fb3796f1dbd86befec802fe3d0456cc5ef01`.

The archive includes serial logs, image inventories, source revision records,
image/kernel/initramfs payloads, build logs and a `SHA256SUMS` manifest.
It also preserves the original complete Git history in `original.bundle`,
verified with `git bundle verify`, so removed historical source and evidence
checkers remain recoverable. That bundle starts at
`b03a2507dbca7dff48684ce7ce4b4fcf0f413d44` and has SHA-256
`3f2ea6753efd77e9ccd0f69e7f060156a53647bd3c017779a733e9b9473398d7`.
