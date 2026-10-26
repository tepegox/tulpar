# Tulpar

Tulpar is a terminal-based operating system under development for
**amd64 and ARM64 servers**. It is forked from
[Vinix](https://github.com/vlang/vinix) and written in [V](https://vlang.io).
Its goals are lightweight operation, simplicity, and security.
The name comes from the legendary winged horse, Tulpar.

The base contains the kernel, musl, BusyBox, and a small V init that starts
`/bin/sh` and supervises the shell. Desktop applications, X11, Hyprland,
Android, Apple hardware, iOS, and macOS are unsupported. Guest compilers
and editors are not included. Build and run Tulpar on Linux.

## Build

Install a current V compiler with V3 support and put `v` on your `PATH`.
The qualified compiler revision is `f7e9ee96c22ca6db47b56d28332e7553715c659f`.

On Debian or Ubuntu:

```sh
sudo apt install build-essential clang llvm lld git curl file rsync \
    xorriso xz-utils mtools libarchive-dev qemu-system-x86 ovmf \
    qemu-system-arm qemu-efi-aarch64
git clone https://github.com/tepegox/tulpar.git
cd tulpar
make all
```

Build ARM64 instead with:

```sh
make ARCH=arm64 all
```

The outputs are `tulpar-amd64.iso` and `tulpar-arm64.iso`.
Build files and caches stay under `build/terminal/`.
Use `make V=/path/to/v all` to select a compiler explicitly.

## Run in QEMU

Boot an existing image:

```sh
make run-no-build              # amd64
make ARCH=arm64 run-no-build   # ARM64
```

Use `make run` or `make ARCH=arm64 run` to build and boot in one step.
QEMU uses 512 MiB RAM and two vCPUs, entirely in the terminal.
Press **Ctrl+A, then X** to exit. Guest files live in RAM by default.
Set `TULPAR_ACCEL=kvm` on a matching Linux host for hardware acceleration.
The default is TCG.
Set `TULPAR_FIRMWARE` if UEFI firmware is outside the standard locations.
After DHCP completes, `ping -c 3 10.0.2.2` checks the QEMU gateway.
Boot displays detected devices and attached drivers; `cat /proc/bootlog` reads
the retained kernel diagnostics.

## Verify

```sh
make test-terminal
make ARCH=arm64 test-terminal
```

Both architectures have passed headless QEMU checks for serial input,
commands, pipes, jobs, IPv4 ping, socket permissions, Ctrl-C, restart, and poweroff.
See the [ICMP](docs/icmp-sockets.md) and [boot diagnostic](docs/boot-diagnostics.md)
verification reports.

The commands above rebuild the images and repeat those checks. Logs go under
`~/.local/state/tulpar/`; use `STATE_DIR=/external/fresh-directory` to choose
another location. The verified uncompressed base images are roughly 8 MiB.

## License

[GNU GPL v2](LICENSE). Tulpar retains the work and attribution of Vinix
and its contributors.
