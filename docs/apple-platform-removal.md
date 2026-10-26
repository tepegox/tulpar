# Apple platform removal — 25 October 2026

Qualified source: `fb5b7f15150b8480b0a8c51e170fa68d19237103`.
Baseline: `38f11a8df196aae6e9785b09505f399138d2f5b4`.

Tulpar now targets generic amd64 and ARM64 servers using Linux build hosts.
Apple boot loaders, AIC/PMGR/watchdog, ANS, SMC, DART, SPI input, Wi-Fi,
speaker, AGX and DCP drivers, Apple DVFS, iOS package profiles, macOS
benchmark/kernel-extension producers, and their platform-specific tooling,
tests and documentation were removed. The generic ACPI fixture compiler
was moved out of the retired Apple test tree. The ARM64 Limine builder is
now V, with Linux LLVM tooling; the QEMU runner accepts TCG or KVM.

Generic GIC, UART, VirtIO, ACPI, PSCI, PCI configuration, and both native
variadic ABIs remain. ARM64 PCI message interrupts still require a GIC ITS
implementation: the obsolete Apple MSI placeholder was removed, leaving
polled devices available. Shared XNU-derived allocator code and its licenses
remain because they serve both supported architectures.

| Target | ISO bytes | Initramfs bytes | Headless QEMU |
| --- | ---: | ---: | --- |
| amd64 | 21,024,768 | 8,130,560 | PASS |
| ARM64 | 20,406,272 | 8,468,480 | PASS |

Both kernels were rebuilt with V revision
`f7e9ee96c22ca6db47b56d28332e7553715c659f`. Each guest ran under TCG with
512 MiB RAM and two vCPUs. The maintained checker exercised serial input,
architecture reporting, arithmetic, file creation, pipes, background jobs and
wait status, terminal settings, `/proc/meminfo`, Ctrl-C, shell restart, and
poweroff. Both QEMU processes exited successfully without kernel panics.
The checks were repeated after committing; their image/kernel/initramfs
checksums match the build runs. Defined-symbol inventories contain none of
the retired Apple driver or kernel-extension entry points.

Additional passing checks cover native package validation for both targets,
refusal of Apple/iOS/macOS package kinds, package launch ownership, the four
CPU idle/frequency decision test files, and the generic allocator sampler's
success, allocation failure, zeroing, clock failure and allocator-import
guards. The relocated ACPI helper generated native fixtures for both targets.
These checks qualify the terminal base in QEMU, not physical server boards
or the entire historical test collection.

Reproduce the OS checks with:

```sh
make test-terminal
make ARCH=arm64 test-terminal
```

Evidence archive:
`/home/artu/.local/state/tulpar/apple-removal-20261025.tar.gz`.

Archive SHA-256: `7aa1925f074f7b341505803e3a29ae2cd589fc997ab1f7abe299e883fa40dfad`.

The archive contains images, kernels, initramfs archives, serial transcripts,
inventories, toolchain versions, build and test logs, generated ACPI fixtures,
the sampler evidence, and `qualified/SHA256SUMS`. `original.bundle` preserves
the complete pre-removal Git history, including historical checkers and
tracked evidence. `platform-change.bundle` adds the qualified source revision.
Historical audit checkers still require their original complete evidence;
their acceptance rules have not been relaxed to accept missing artifacts.
