// SPDX-License-Identifier: GPL-2.0-or-later
// Observe a private QEMU boot through its serial log and QMP socket.
module main

import json2
import os
import tools.qmpclient
import time

fn verify() ! {
	if os.args.len !in [5, 6] {
		return error('Usage: verify-amd64-boot.v SERIAL_LOG QMP_SOCKET EXPECTED_MARKER SCREENSHOT.png [--quit]')
	}
	quit := os.args.len == 6
	if quit && os.args[5] != '--quit' { return error('unexpected boot verification option') }
	deadline := time.sys_mono_now() + u64(120 * time.second)
	for {
		text := os.read_file(os.args[1]) or { '' }
		if text.contains('KERNEL PANIC') || text.contains('Heap self-test failed') {
			return error('guest panicked; inspect ' + os.args[1])
		}
		if text.contains(os.args[3]) { break }
		if time.sys_mono_now() >= deadline {
			return error('guest boot marker timed out: ' + os.args[3])
		}
		time.sleep(100 * time.millisecond)
	}
	// Let a desktop render its first frame after init's startup marker.
	for _ in 0 .. 50 { time.sleep(100 * time.millisecond) }
	mut monitor := qmpclient.connect_bounded(os.args[2],
		time.sys_mono_now() + u64(10 * time.second), unsafe { nil })!
	defer {
		if quit { monitor.command('quit', {}) or {} }
		monitor.close()
	}
	screenshot := os.abs_path(os.args[4])
	monitor.command('screendump', {
		'filename': json2.Any(screenshot)
		'format':   json2.Any('png')
	})!
	if os.file_size(screenshot) < 1024 { return error('QEMU screenshot is empty') }
	latest := os.read_file(os.args[1])!
	if latest.contains('KERNEL PANIC') || latest.contains('Heap self-test failed')
		|| (os.args[3] == 'Tulpar: starting the desktop' && latest.count(os.args[3]) != 1) {
		return error('guest did not remain running; inspect the serial log and screenshot')
	}
	println('PASS: ' + os.args[3] + '; screenshot: ' + screenshot)
}

fn main() {
	verify() or {
		eprintln(err)
		exit(1)
	}
}
