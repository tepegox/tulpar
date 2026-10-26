# CPU idle states and frequency control

The host checks compile the kernel's idle governor, x86 idle-state tables,
frequency policy, and x86 frequency-register arithmetic through source links:

```sh
sh tests/cpu-power/run.sh
```

The generic ARM64 driver exposes frequency policies with unknown frequencies
and no hardware frequency control. Its virtual idle path uses ARM WFI.
Apple DVFS and Apple-specific idle overrides have been removed.

Guest scenarios remain available through `tests/hardware-platform/run`:

```sh
tests/hardware-platform/run --arch x86_64 --kernel /path/to/kernel --scenario cpu-power --scenario cpu-power-simulated
tests/hardware-platform/run --arch aarch64 --kernel /path/to/kernel --scenario cpu-power
```

`cpu-power` checks idle accounting, disabled states, timer wake-ups, pipe
traffic, and refusal of unsupported frequency changes. The simulated
frequency driver is now x86-only; it exercises governors and profiles without
writing physical frequency registers.

Physical HWP, SpeedStep, CPPC, APERF/MPERF, and deep MWAIT states still require
hardware qualification. Host decision tests and QEMU do not establish their
power consumption or physical register behavior.
