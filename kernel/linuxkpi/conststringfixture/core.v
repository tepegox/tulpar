// SPDX-License-Identifier: GPL-2.0-only
// Original Linux const-qualified ownership calls, with explicit pointer views.
@[translated]
module conststringfixture

#include "linuxkpi_conststring_fixture_v_contract.h"

@[typedef]
struct C.vks_const_char {}
@[typedef]
struct C.vks_const_void {}

fn C.kstrdup_const(&C.vks_const_char, u32) &C.vks_const_char
fn C.kfree_const(&C.vks_const_void)
fn C.kmalloc(uint, u32) voidptr
fn C.tulpar_conststring_gfp_kernel() u32
fn C.tulpar_linuxkpi_is_kernel_rodata(&C.vks_const_void) bool

// symbols.h declares arrays. These function designators take their addresses;
// no image symbol is called, and no candidate address is dereferenced.
fn C.rodata_start()
fn C.rodata_end()
fn C.text_start()

@[export: 'tulpar_linuxkpi_conststring_fixture_dup']
pub fn dup(src voidptr, flags u32) voidptr {
	return unsafe { voidptr(C.kstrdup_const(&C.vks_const_char(src), flags)) }
}

@[export: 'tulpar_linuxkpi_conststring_fixture_free']
pub fn free(ptr voidptr) {
	unsafe { C.kfree_const(&C.vks_const_void(ptr)) }
}

@[export: 'tulpar_linuxkpi_conststring_fixture_alloc']
pub fn alloc(size uint) voidptr {
	return C.kmalloc(size, C.tulpar_conststring_gfp_kernel())
}

@[export: 'tulpar_linuxkpi_conststring_fixture_gfp']
pub fn gfp() u32 { return C.tulpar_conststring_gfp_kernel() }

@[export: 'tulpar_linuxkpi_conststring_fixture_literal']
pub fn literal() voidptr { return unsafe { voidptr(c'tulpar-constant-string') } }

@[export: 'tulpar_linuxkpi_conststring_fixture_address']
pub fn address(which u32) uint {
	if which == 0 { return uint(voidptr(C.rodata_start)) }
	if which == 1 { return uint(voidptr(C.rodata_end)) }
	if which == 2 { return uint(voidptr(C.text_start)) }
	return 0
}

@[export: 'tulpar_linuxkpi_conststring_fixture_rodata']
pub fn rodata(ptr voidptr) bool {
	return unsafe { C.tulpar_linuxkpi_is_kernel_rodata(&C.vks_const_void(ptr)) }
}
