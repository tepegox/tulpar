// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2026 Alexander Medvednikov
module cpufreq

// Generic ARM64 exposes policies without inventing a SoC frequency driver.
const no_cluster = u32(0xffffffff)

fn driver_start(cpus int) {
	cpufreq_driver.name = 'none'
	for cpu_number in 0 .. cpus {
		if cpu_number < max_cpus && cpufreq_policy_of[cpu_number] == 0 {
			add_policy(u64(1) << u32(cpu_number), Limits{}, .performance, .performance, no_cluster)
		}
	}
}
