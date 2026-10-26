# Native V generators

The maintained generators support generic amd64 and ARM64 fixtures, allocator
benchmarks, freestanding allocator samplers, and Linux compatibility fixtures.
Public entry points include `build-support/compile-v-module`,
`tests/alloc-bench/compile-v-bench`, `tests/alloc-bench/compile-v-sampler`, and
`tests/linuxkpi/compile-compat`.

Mach-O metadata, macOS kernel-extension generation, and their platform-specific
qualification runner have been retired. Historical qualification sources and
complete evidence remain in the original Git bundle recorded in
[the platform removal report](../../docs/apple-platform-removal.md).

The generic allocator sampler fixture retains allocation-failure, zeroing,
ownership, clock-failure, and allocator-import checks. Run it on Linux with:

```sh
tests/alloc-bench/test-v-sampler --state-dir /external/new-sampler-state
```

The historical reports and integrity checkers still require their original
complete evidence bundles; removed platform producers are not substitutes for
those artifacts.
