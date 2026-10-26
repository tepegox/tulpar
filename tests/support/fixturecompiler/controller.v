// SPDX-License-Identifier: GPL-2.0-only
module fixturecompiler

import hosttest
import os

// Compile the production ACPI synchronization fixture for either target.
pub fn run() {
	parsed := hosttest.parse_arguments(os.args[1..],
		[hosttest.Option{'--arch', true, ['arm64', 'amd64']}], 1,
		'Usage: compile-fixture OUTPUT --arch arm64|amd64',
		'Generate the maintained ACPI fixture from native V.') or {
		eprintln(err)
		exit(2)
	}
	arch := parsed.options['--arch'] or {
		eprintln('--arch is required')
		exit(2)
	}
	output := hosttest.module_resolve(parsed.positional[0]) or {
		eprintln(err)
		exit(1)
	}
	hosttest.generate_module(os.join_path(hosttest.root(), 'tests/acpi-sync/nativefixture'),
		output, arch, ['nofloat']) or {
		eprintln(err)
		exit(1)
	}
}
