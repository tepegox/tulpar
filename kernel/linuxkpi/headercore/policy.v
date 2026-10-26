// SPDX-License-Identifier: GPL-2.0-or-later
// Runtime pointer and scheduler policy; compiler primitives and constant native
// expressions are generated separately from structured ABI metadata.
@[translated]
module headercore

#include "linuxkpi_header_primitive_v_contract.h"
fn C.tulpar_linuxkpi_preempt_count() u32
fn C.irqs_disabled() bool
fn C.tulpar_linuxkpi_may_sleep() bool
fn C.tulpar_linuxkpi_bug(C.vkh_const_char_p, i32)

@[export: 'tulpar_zero_or_null_ptr']
pub fn zero_or_null(pointer uint) bool { return pointer <= 16 }

@[export: 'tulpar_preemptible']
pub fn preemptible() bool {
	// Observe IF, pins and actual maskable IRQ depth together. An IRQ-enabled
	// nested handler still borrows its interrupted task rather than task context.
	return C.tulpar_linuxkpi_may_sleep()
}

// A false condition carries no sleep annotation. The true path uses the same
// native task-context invariant as might_sleep(), without changing scheduling.
@[export: 'tulpar_might_sleep_if_native']
pub fn might_sleep_if(condition bool, file C.vkh_const_char_p, line i32) {
	if !condition { return }
	if !C.tulpar_linuxkpi_may_sleep() { C.tulpar_linuxkpi_bug(file, line) }
}
