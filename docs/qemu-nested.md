# Run Tulpar in Tulpar with QEMU

The AArch64 QEMU system layer runs a second Tulpar kernel using TCG software
emulation. Hardware virtualization is not required inside Tulpar.

The `tulpar-qemu` launcher explicitly selects `-accel tcg`. Tulpar does not
implement Linux's `/dev/kvm` API, so an outer VM accelerated by KVM does not
give this inner QEMU instance KVM acceleration. See
[Virtualization and KVM support](virtualization.md) for the supported modes.

On the build host, stage QEMU and build a desktop image containing it:

```sh
./scripts/build-qemu-system-aarch64.sh
./scripts/build-desktop-aarch64.sh --compact-initramfs --with-qemu-system
./scripts/run-desktop-aarch64.sh --no-build
```

The builder uses Alpine 3.21's native AArch64 QEMU package and copies the
AArch64 UEFI firmware from the host QEMU installation. Set
`TULPAR_QEMU_FIRMWARE_CODE` and `TULPAR_QEMU_FIRMWARE_VARS` if the firmware is
installed elsewhere.

Build a bootable raw image for the inner VM from the current kernel and base
userland initramfs:

```sh
./scripts/build-tulpar-guest-disk.sh
```

The image is written to `build-aarch64-qemu-system/tulpar-guest.img`. The
builder refuses to overwrite an existing image; move or remove it when you
intend to rebuild. You can pass an output path and a different uncompressed
initramfs tar as the first two arguments.

Copy that image into Tulpar. For a Tulpar desktop running in the host QEMU, a
simple way is to serve it from the host:

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory build-aarch64-qemu-system
```

Then, in the Tulpar terminal:

```sh
curl -fLo /root/tulpar-guest.img http://10.0.2.2:8765/tulpar-guest.img
tulpar-qemu /root/tulpar-guest.img
```

`tulpar-qemu` creates a writable UEFI variables file under
`$HOME/.tulpar-qemu`, enables the memory permissions QEMU's TCG needs, and
boots the raw image with a serial console. Set `TULPAR_QEMU_GUEST_MEM` (MiB)
or `TULPAR_QEMU_GUEST_SMP` to change the inner VM's memory or CPU count. The
default is 2048 MiB and one CPU. The inner image is writable and keeps its
changes across runs. QEMU leaves the inner VM's network disabled by default;
pass explicit QEMU network options after the image path if it is needed.

To open a second Tulpar desktop in a window, build the small inner desktop disk,
copy it to `/root/tulpar-inner-desktop.img` in the outer desktop, and open
**Tulpar in QEMU** from the Start menu. The launcher shows QEMU's VNC display in
a fixed 1024×768 Tulpar window and gives the inner VM 1024 MiB by default. The
viewer accepts inner resolutions up to 1024×768. On the build host:

```sh
./scripts/build-nested-desktop-aarch64.sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory build-aarch64-qemu-system
```

Then, in the outer Tulpar Terminal:

```sh
curl -fLo /root/tulpar-inner-desktop.img http://10.0.2.2:8765/tulpar-inner-desktop.img
```

The small image includes the native desktop and core applications. Create its
user profile in the inner desktop when it first starts.

For another image path, set `TULPAR_QEMU_DESKTOP_IMAGE` before launching
`tulpar-qemu-desktop` from a hosted X11 session. The plain `tulpar-qemu` command
remains suitable for serial and automated boot checks. The desktop launcher
uses `TULPAR_QEMU_DISPLAY=vnc=127.0.0.1:1` and writes the serial log to
`/tmp/tulpar-qemu-desktop-serial.log`.

For a two level boot check with a tiny inner initramfs, run
`./tests/qemu-nested/run.sh` on the build host. It reports
`TULPAR NESTED QEMU: PASS` only when PID 1 in the inner Tulpar prints the marker.
