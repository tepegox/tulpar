// SPDX-License-Identifier: GPL-2.0-only
// Run the unchanged host fixture, then exercise the real native policy macros.
@[translated]
module policyhost

fn C.tulpar_linuxkpi_i915_policy_native_selftest() i32
fn C.tulpar_linuxkpi_host_original_main(i32, &&char) i32

@[export: 'main']
pub fn main_entry(argc i32, argv &&char) i32 {
	result := C.tulpar_linuxkpi_host_original_main(argc, argv)
	if result != 0 { return result }
	return C.tulpar_linuxkpi_i915_policy_native_selftest()
}
