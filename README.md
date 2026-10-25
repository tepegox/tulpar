Tulpar is an operating system under development, forked from
[Vinix](https://github.com/vlang/vinix) and written in [V](https://vlang.io).
The goal is a lightweight, secure server OS with a command-line interface
and no GUI. Its name and winged-horse emblem come from the legendary Tulpar.

## Build and run

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
make run-no-build
```

This produces `tulpar-amd64.iso`. Build and run ARM64 with:

```sh
make ARCH=arm64 all
make ARCH=arm64 run-no-build
```

The guest boots into a BusyBox shell through a small V init. No desktop,
X11, Hyprland, Android runtime, guest compiler, or editor is included.
QEMU runs entirely in the terminal; press **Ctrl+A, then X** to exit.
Set `TULPAR_ACCEL=kvm` on a matching Linux host for hardware acceleration,
or `TULPAR_ACCEL=hvf` on a matching macOS host. The default is TCG.
Set `TULPAR_FIRMWARE` if UEFI firmware is outside the standard locations.

## Verify

```sh
make test-terminal
make ARCH=arm64 test-terminal
```

These boot QEMU and test serial input, commands, pipes, background jobs,
Ctrl-C, shell restart, and poweroff. Logs go under
`~/.local/state/tulpar/`; use `STATE_DIR=/external/fresh-directory` to choose
another location. Guest files live in RAM unless a disk is configured.

## License

[GNU GPL v2](LICENSE). Tulpar retains the work and attribution of Vinix
and its contributors.
