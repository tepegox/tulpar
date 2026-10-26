# Initramfs header termination

```sh
v run tests/initramfs-headers/run.v
```

Runs the production header classifier on complete zero terminators, a
nonzero final byte, valid and damaged USTAR signatures, and every short
header length. The short-header checks use a null pointer to prove no bytes
are touched before the length check. Temporary files stay outside Git.

`make test-terminal` and `make ARCH=arm64 test-terminal` also verify actual
archive unpacking, device/driver messages, and the absence of archive debug
markers or malformed-header diagnostics during normal QEMU boot.
