# Tulpar roadmap

Tulpar is a lightweight, terminal-only operating system under development for
amd64 and ARM64 servers. It is forked from Vinix. Desktop environments,
X11, Hyprland, Android, and Apple platforms are outside its scope.

- Keep the boot image small: kernel, musl, BusyBox, and the V init supervisor.
- Improve storage durability, recovery, and the installation/update path.
- Develop server networking and Linux userspace compatibility with bounded
  resource use and explicit permission checks.
- Test process isolation, capabilities, memory protection, and syscall policy.
- Qualify standard amd64 and ARM64 firmware and server devices, beyond QEMU.
- Maintain reproducible builds, serial diagnostics, and regression tests on
  both architectures.

These are development goals. Tulpar is not yet a production server platform.
