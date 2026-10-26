# IPv4 ICMP sockets

Tulpar exposes `AF_INET/SOCK_RAW/IPPROTO_ICMP` for BusyBox `ping` and other
privileged ICMP applications. Creation requires `CAP_NET_RAW`, a trusted
process, the initial user/network namespaces, and the `inet` pledge promise.
Raw I/O rechecks pledge for descriptors retained across a later restriction.

Send buffers contain the ICMP header, checksum, and payload; lwIP generates
the IPv4 header. Receive buffers include the complete IPv4 packet. Receive
copies have independent ownership and a bounded queue. ICMP filtering,
TTL/TOS, bind/connect, polling, peek/truncation, shutdown, and close use the
existing socket interfaces. ICMPv6, unprivileged ICMP datagram sockets,
`IP_HDRINCL`, and the Linux ICMP error queue remain unsupported.

Run the native V fixture against the production V core and real lwIP:

```sh
v -new-compiler -cc clang -gc none run tests/network-icmp/run.v /external/fresh-state
```

It enables ASan/UBSan, including function-type checks and fatal diagnostics,
rejects implicit V allocator imports from the transport, and measures lwIP
allocations across 300 socket lifecycle/queue-flood cycles. It also runs the
existing socket-option, IPv6, and TCP lifetime fixture assertions. The V
runner stages their test-driver stub parameter qualifiers to match the
production driver ABI; the original fixture logic remains unchanged.
Generated C, objects, executables and logs stay outside Git.

Both architecture checks boot the terminal OS, wait for DHCP, ping loopback
and QEMU's gateway, and verify that `nobody` cannot open a raw socket:

```sh
make test-terminal
make ARCH=arm64 test-terminal
```
