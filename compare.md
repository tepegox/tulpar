# Tulpar scope

Tulpar is a fork of Vinix focused on a small terminal-based server system.
Its base consists of the kernel, musl, BusyBox, and a V init supervisor.
The supported targets are amd64 and ARM64, built on Linux and tested in QEMU.

Tulpar does not aim to provide a desktop or support X11, Hyprland, Android,
or Apple platforms. Its priorities are a lean base, predictable resource use,
server networking, and security mechanisms that can be measured and tested.

Linux and BSD systems have much broader hardware coverage, compatibility,
and production experience. Tulpar is under development; its lightweight and
security aims are goals, rather than claims of superiority over those systems.
