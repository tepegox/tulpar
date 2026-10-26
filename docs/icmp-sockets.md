# IPv4 ICMP sockets — 25 October 2026

Qualified source: `8c73fa0ea82b3008a0fe1c7458e37067c65c8098`.
Baseline: `5da2512e1`.

Tulpar supports `AF_INET/SOCK_RAW/IPPROTO_ICMP`, allowing BusyBox `ping` to
send and receive IPv4 ICMP. Creation requires `CAP_NET_RAW`, a trusted process,
the initial user and network namespaces, and the `inet` pledge promise.
Existing raw descriptors also recheck pledge on I/O. ICMPv6, unprivileged
ICMP datagram sockets, `IP_HDRINCL`, and the Linux error queue are outside
this change. See the [socket contract and tests](../tests/network-icmp/README.md).

Both amd64 and ARM64 kernels were built in an isolated kernel worktree with
V `f7e9ee96c22ca6db47b56d28332e7553715c659f`, Clang/LLD 19.1.7, and tested in
QEMU 10.0.13 using TCG, 512 MiB RAM, and two vCPUs.

| Check | amd64 | ARM64 |
| --- | --- | --- |
| Loopback and QEMU gateway ping after DHCP | PASS | PASS |
| Unprivileged raw socket creation denied | PASS | PASS |
| Commands, pipes, jobs, Ctrl-C, shell restart, poweroff | PASS | PASS |

The checks passed again after committing, with matching ISO, kernel, and
initramfs checksums. Every tracked kernel source file in each build matches
the qualified revision. This verifies the terminal base in QEMU; physical
hardware and the entire historical test collection were not qualified.

The host fixture passed against the production V transport and real lwIP
with fatal ASan/UBSan diagnostics, including callback function-type checks.
It covers echo checksums, complete IPv4 receive headers, independent readers,
filtering, bind/connect, options, polling, peek/truncation, shutdown, bounded
queues, and 300 lifecycle/flood cycles returning lwIP allocations to baseline.
The generated transport imports no implicit V allocator functions. Existing
socket-option, IPv6, and TCP lifetime assertions also pass. Testing found and
fixed an existing TCP accept backlog call that accessed a listening PCB as a
full connection, plus const-qualified callback ABI mismatches. Independent
review approved packet, PCB, stack-address, and accepted-connection lifetimes.

The repository-wide allocation-site guard still exits with failure on both
baseline and qualified source because its allowance list does not cover
existing sites reported by this V compiler. Comparing its `NEW:` groups found
no additions: 133 baseline groups became 132, removing the transport's group
of 11 implicit stack-to-heap copies. Its checker and allowance list were not
relaxed. The measured ICMP allocation checks pass independently.

Reproduce:

```sh
v -new-compiler -cc clang -gc none run tests/network-icmp/run.v /external/fresh-state
make test-terminal
make ARCH=arm64 test-terminal
```

Reboot the rebuilt image, wait for DHCP, then run `ping -c 3 10.0.2.2`.
Public destinations additionally depend on the host network allowing ICMP.

Evidence archive:
`/home/artu/.local/state/tulpar/icmp-qualification-20261025.tar.gz`.

Archive SHA-256: `56d09a3ab33d93fe49e1f27dcb703479bc6d808abc90fd6a1806cef09f87e55e`.

The archive contains the qualified source and incremental Git bundle, host
fixtures and generated transport, lwIP sources, userland inputs, both images,
kernels, initramfs archives, generated kernel/init C, serial transcripts,
build inventories, toolchain versions, build/test logs, allocation comparison,
lifetime review, and `qualified/SHA256SUMS`. Earlier historical evidence and
its checkers remain unchanged.
