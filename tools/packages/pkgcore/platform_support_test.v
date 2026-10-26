// SPDX-License-Identifier: GPL-2.0-or-later
module pkgcore

fn test_native_targets_remain_valid_and_apple_packages_are_refused() {
	for architecture in ['aarch64', 'x86_64'] {
		package := Package{
			id:           'org.tulpar.probe'
			version:      '1.0.0'
			architecture: architecture
			name:         'Terminal probe'
			license:      'MIT'
			kind:         'native'
			entrypoint:   'bin/probe'
			files:        [Payload{ path: 'bin/probe', sha256: '0'.repeat(64), bytes: 1, executable: true }]
		}
		package.validate()!
		for kind in ['apple', 'ios', 'macos'] {
			unsupported := Package{ ...package, kind: kind }
			mut refused := false
			unsupported.validate() or { refused = err.msg() == 'invalid package kind: ' + kind }
			assert refused
		}
	}
}
