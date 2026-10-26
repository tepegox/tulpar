// SPDX-License-Identifier: GPL-2.0-or-later
module terminalbuild

import os

fn test_rebranding_keeps_legacy_desktop_and_android_content_excluded() {
	work := os.temp_dir() + '/tulpar-inventory-' + os.getpid().str()
	os.mkdir_all(work + '/sbin')!
	os.mkdir_all(work + '/bin')!
	defer { os.rmdir_all(work) or {} }
	for binary in ['sbin/init', 'bin/busybox'] {
		os.write_file(work + '/' + binary, '')!
		os.chmod(work + '/' + binary, 0o755)!
	}
	check_inventory(work)!
	for forbidden in ['usr/bin/vinix-desktop', 'opt/vinix-android-aarch64',
		'usr/bin/tulpar-desktop', 'opt/tulpar-android-aarch64'] {
		os.mkdir_all(os.dir(work + '/' + forbidden))!
		os.write_file(work + '/' + forbidden, '')!
		mut rejected := false
		check_inventory(work) or { rejected = true }
		assert rejected, forbidden
		os.rm(work + '/' + forbidden)!
	}
}
