// SPDX-License-Identifier: GPL-2.0-or-later
module allocationhost

import cachecli
import strconv

fn integer(args cachecli.Arguments, name string, fallback int) !int {
	return int(strconv.parse_int(args.value(name, fallback.str()), 10, 32) or { return InputError{'invalid integer for ' + name} })
}

fn status(failure IError) int {
	report_failure(failure)
	if cachecli.cancelled() { return cachecli.interrupt_status() }
	return if failure is InputError { 2 } else { 1 }
}

pub fn vinix_cli(argv []string, kind VinixKind) int {
	mut scalar := if kind == .kernel {
		['--kernel', '--state-dir', '--firmware', '--qemu', '--timeout', '--cc', '--cpus']
	} else {
		['--kernel', '--sysroot', '--state-dir', '--firmware', '--qemu', '--iterations', '--samples',
			'--timeout', '--allocator-check']
	}
	if kind in [.saved_final, .preboot] { scalar << '--original-reference' }
	args := cachecli.arguments(argv, scalar, []string{}, ['--build-only'], 0, 0,
		'usage: run-vinix --kernel FILE --sysroot ROOT --state-dir NEW_DIR [--iterations N --samples N --timeout SECONDS --allocator-check FILE]') or {
		eprintln(err)
		return 2
	}
	kernel := args.required('--kernel') or {
		eprintln(err)
		return 2
	}
	state := args.required('--state-dir') or {
		eprintln(err)
		return 2
	}
	sysroot := if kind == .kernel {
		''
	} else {
		args.required('--sysroot') or {
			eprintln(err)
			return 2
		}
	}
	iterations := integer(args, '--iterations', 200000) or { return status(err) }
	samples := integer(args, '--samples', 7) or { return status(err) }
	timeout := integer(args, '--timeout', if kind == .kernel { 180 } else { 3600 }) or { return status(err) }
	cpus := integer(args, '--cpus', 1) or { return status(err) }
	if timeout <= 0 || (kind != .kernel && (iterations < 1 || iterations > 1000000000 || samples < 5 || samples > 31)) || (kind == .kernel && (cpus < 1 || cpus > 256)) {
		eprintln('invalid iterations, samples, timeout or CPU count')
		return 2
	}
	options := VinixOptions{
		kernel:             kernel
		sysroot:            sysroot
		state:              state
		firmware:           if '--firmware' in args.options {
			resolve(args.value('--firmware', '')) or { return status(err) }
		} else {
			''
		}
		qemu:               args.value('--qemu', 'qemu-system-x86_64')
		cc:                 args.value('--cc', 'x86_64-linux-musl-gcc')
		iterations:         iterations
		samples:            samples
		timeout:            timeout
		cpus:               cpus
		allocator_check:    if '--allocator-check' in args.options {
			resolve(args.value('--allocator-check', '')) or { return status(err) }
		} else {
			''
		}
		original_reference: if '--original-reference' in args.options {
			resolve(args.value('--original-reference', '')) or { return status(err) }
		} else {
			''
		}
	}
	guard := cachecli.own_commands()
	defer { guard.close() }
	command, work := prepare_vinix(options, kind) or { return status(err) }
	if '--build-only' in args.options { return 0 }
	capture_vm(command, work, timeout, options.allocator_check != '', kind) or { return status(err) }
	return 0
}
