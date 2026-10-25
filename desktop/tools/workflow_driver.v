// SPDX-License-Identifier: GPL-2.0-or-later
// Bootstrap the native workflow tools with a stable V compiler. The selected
// production compiler still generates every application and test.
module main
import os

fn command(program string, args []string) ! {
	mut p := os.new_process(program)
	defer { p.close() }
	p.set_args(args)
	p.run()
	p.wait()
	code := p.code
	if code != 0 { return error_with_code('${program} failed (${code})', code) }
}

fn main() {
	run() or { eprintln(err); exit(err.code()) }
}

fn run() ! {
	if os.args.len < 2 { eprintln('usage: workflow_driver.v check|publish [arguments]'); exit(2) }
	mode := os.args[1]
	if mode !in ['check', 'publish'] { exit(2) }
	root := os.real_path('.')
	v := os.getenv('V')
	if v == '' { eprintln('Set V to the production compiler'); exit(2) }
	os.setenv('VEXE', v, true)
	work := os.join_path(os.temp_dir(), 'vinix-workflow-driver-${os.getpid()}')
	os.mkdir_all(work) or { panic(err) }
	defer { os.rmdir_all(work) or {} }
	// This tool runs on the host. Let V select the hosted libc declarations,
	// native runtime sources and linker flags instead of linking generated C
	// by hand with the kernel's target-header mode.
	command(v, ['-new-compiler', '-cc', 'clang', '-gc', 'none', '-manualfree', '-path', '@vlib|@vmodules|${root}/tests/linuxkpi', '-o', '${work}/tool', '${root}/desktop/tools/workflow_${mode}.v'])!
	command('${work}/tool', os.args[2..])!
}
