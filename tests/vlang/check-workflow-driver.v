// SPDX-License-Identifier: GPL-2.0-or-later
// Compile, link and execute the real publishing helper through its public
// entry point. Invalid input stops before any cross-build or publication.
module main

import os
import time

fn main() {
	root := os.dir(os.dir(os.dir(@FILE)))
	mut child := os.new_process(root + '/scripts/cross-compile-app.sh')
	defer { child.close() }
	child.set_work_folder(root)
	child.set_args(['invalid-app'])
	child.set_redirect_stdio()
	child.run()
	// Drain both streams while compiling so compiler diagnostics cannot fill
	// a pipe and leave the regression check waiting on its child.
	mut output := ''
	for child.is_alive() {
		if child.is_pending(.stdout) { output += child.stdout_read() }
		if child.is_pending(.stderr) { output += child.stderr_read() }
		time.sleep(time.millisecond)
	}
	child.wait()
	output += child.stdout_slurp() + child.stderr_slurp()
	if child.code != 2 || !output.contains('unsupported app: invalid-app') {
		eprintln(output)
		eprintln('FAIL: publishing helper did not compile, link and reject invalid input')
		exit(1)
	}
	println('PASS: workflow helper compiles, links and preserves its exit status')
}
