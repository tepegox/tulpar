# Tulpar

![Tulpar logo](tulpar-logo.jpeg)

Tulpar is an operating system under development for **amd64 and ARM64 servers**,
forked from [Vinix](https://github.com/vlang/vinix) and written in V.
It aims to be lightweight, simple, and secure, with a terminal-only interface.

## Dependencies

Build on Linux with a [V compiler](https://github.com/vlang/v) supporting
`-new-compiler`, available as `v` on your `PATH` (tested: `f7e9ee9`).
On Debian/Ubuntu, install:

```sh
sudo apt install build-essential clang llvm lld git curl file rsync \
    xorriso xz-utils mtools libarchive-dev qemu-system-x86 ovmf \
    qemu-system-arm qemu-efi-aarch64
```

## Build and run

```sh
git clone https://github.com/tepegox/tulpar.git
cd tulpar

# amd64
make
make run-no-build

# ARM64
make ARCH=arm64
make ARCH=arm64 run-no-build
```

Images are saved as `tulpar-amd64.iso` and `tulpar-arm64.iso`.
