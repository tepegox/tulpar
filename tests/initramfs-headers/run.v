// SPDX-License-Identifier: GPL-2.0-or-later
module main

import os

fn main() {
	repo := os.real_path(os.dir(@FILE) + '/../..')
	work := os.temp_dir() + '/tulpar-initramfs-headers-' + os.getpid().str()
	os.mkdir_all(work)!
	defer { os.rmdir_all(work) or {} }
	os.write_file(work + '/v.mod', "Module {name: 'initramfs'}\n")!
	os.cp(repo + '/kernel/initramfs/header.v', work + '/header.v')!
	os.cp(repo + '/tests/initramfs-headers/fixture/header_test.v', work + '/header_test.v')!
	mut child := os.new_process(os.getenv_opt('V') or { @VEXE })
	child.set_args(['-cc', 'clang', 'test', work])
	child.run()
	child.wait()
	code := child.code
	child.close()
	if code != 0 { exit(code) }
}
