// SPDX-License-Identifier: GPL-2.0-or-later
module main

import os
import terminalbuild

fn main() {
	terminalbuild.cli(os.args[1..]) or { eprintln(err); exit(1) }
}
