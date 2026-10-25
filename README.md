Tulpar is an operating system under development, forked from
[Vinix](https://github.com/vlang/vinix) and written in [V](https://vlang.io).
The goal is a lightweight, secure server OS with a command-line interface
and no GUI. Its name and winged-horse emblem come from the legendary Tulpar.

## Build

These instructions target an x86_64 Linux host. On Debian or Ubuntu, install:

```sh
sudo apt install build-essential clang llvm lld git curl file xz-utils \
    rsync patch xorriso qemu-system-x86 ovmf libarchive-dev musl-tools
```

Install a current V compiler and put `v` on your `PATH`, then:

```sh
git clone https://github.com/tepegox/tulpar.git
cd tulpar
export V="$(command -v v)"
export VINIX_MUSL_CC_X86_64=musl-gcc
export VINIX_AMD64_ISO="$PWD/tulpar.iso"
make all
```

This downloads the required dependencies and Alpine userland, builds the
kernel, and creates `tulpar.iso` with a console userland and no desktop.
Build scripts and internal paths still use inherited `vinix` names.

## Run in QEMU

From the same terminal, boot the image into the development shell:

```sh
./scripts/run-amd64-alpine.sh --no-build --interactive
```

For KVM acceleration on Linux, use:

```sh
VINIX_QEMU_ACCEL=kvm VINIX_QEMU_CPU=host \
    ./scripts/run-amd64-alpine.sh --no-build --interactive
```

The launcher uses OVMF firmware; set `VINIX_OVMF_CODE` if it is installed
outside the standard locations. Use the QEMU window for keyboard input;
boot messages and shell output appear in the host terminal.

## License

[GNU GPL v2](LICENSE)
