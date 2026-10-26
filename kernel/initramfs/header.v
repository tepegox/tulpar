// SPDX-License-Identifier: GPL-2.0-or-later
module initramfs

enum ArchiveHeaderKind {
	truncated
	end
	ustar
	invalid
}

// A zero-filled tar record is the normal terminator, not a bad signature.
// Check the available length before touching any part of the next header.
fn archive_header_kind(data &u8, available u64) ArchiveHeaderKind {
	if available < 512 { return .truncated }
	unsafe {
		mut empty := true
		for i in 0 .. 512 {
			if data[i] != 0 { empty = false; break }
		}
		if empty { return .end }
		if data[257] == `u` && data[258] == `s` && data[259] == `t`
			&& data[260] == `a` && data[261] == `r` {
			return .ustar
		}
	}
	return .invalid
}
