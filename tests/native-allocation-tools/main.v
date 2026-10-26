// SPDX-License-Identifier: GPL-2.0-or-later
module main

import allocationhost
import os

fn main() {
	if os.args.len < 2 {
		eprintln('missing allocation command')
		exit(2)
	}
	args := os.args[2..]
	if os.args[1] == 'vinix-driver' {
		if args.len < 1 {
			eprintln('missing driver origin')
			exit(2)
		}
		exit(allocationhost.saved_driver(args[1..], args[0], false))
	}
	exit(match os.args[1] {
		'bench' { allocationhost.test_cli(args, false) }
		'sampler' { allocationhost.test_cli(args, true) }
		'vinix' { allocationhost.vinix_cli(args, .current) }
		'vinix-saved' { allocationhost.vinix_cli(args, .saved_final) }
		'vinix-preboot' { allocationhost.vinix_cli(args, .preboot) }
		'kernel' { allocationhost.vinix_cli(args, .kernel) }
		else {
			eprintln('unknown allocation command')
			2
		}
	})
}
