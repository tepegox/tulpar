// SPDX-License-Identifier: GPL-2.0-or-later
module muslnative

import os

fn test_size_types_match_the_native_pointer_width() {
	assert sizeof(uint) == sizeof(voidptr)
	assert sizeof(int) == sizeof(voidptr)
}

fn test_missing_compiler_is_reported_before_probing() {
	work := os.join_path(os.temp_dir(), 'vinix-musl-missing-cc-${os.getpid()}')
	os.mkdir_all(work + '/stage/lib')!
	defer { os.rmdir_all(work) or {} }
	mut loader := []u8{len: 32}
	for i, value in [u8(0x7f), `E`, `L`, `F`, 2, 1] { loader[i] = value }
	loader[18] = 62
	loader << '\x001.2.5\x00'.bytes()
	os.write_file_array(work + '/stage/lib/ld-musl-x86_64.so.1', loader)!
	compiler := work + '/missing-compiler'
	plan(Options{
		root:    work
		support: work + '/support'
		arch:    'x86_64'
		stage:   work + '/stage'
		cache:   work + '/cache'
		cc:      compiler
	}, '1') or {
		assert err is InputError
		assert err.msg() == 'target compiler missing: ' + compiler
		return
	}
	assert false, 'missing compiler was accepted'
}
