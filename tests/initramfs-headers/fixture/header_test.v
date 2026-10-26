// SPDX-License-Identifier: GPL-2.0-or-later
module initramfs

fn test_zero_record_is_an_end_marker() {
	block := [512]u8{}
	assert archive_header_kind(unsafe { &block[0] }, 512) == .end
}

fn test_a_zero_prefix_does_not_hide_a_nonzero_header_tail() {
	mut block := [512]u8{}
	block[511] = 1
	assert archive_header_kind(&block[0], 512) == .invalid
}

fn test_ustar_signature_and_invalid_nonempty_record() {
	mut block := [512]u8{}
	block[0] = `f`
	for i, byte in 'ustar' { block[257 + i] = byte }
	assert archive_header_kind(&block[0], 512) == .ustar
	block[261] = `x`
	assert archive_header_kind(&block[0], 512) == .invalid
}

fn test_short_record_is_rejected_before_any_read() {
	for available in u64(0) .. 512 {
		assert archive_header_kind(unsafe { nil }, available) == .truncated
	}
}
