// SPDX-License-Identifier: GPL-2.0-or-later
module main

import os
import runtime
import crypto.sha256

const version = '12.9.3'
const digest = 'b28b9c9f614f4252cae79580d6cbbc09f4d764a541ec01d586b5c385e3776c99'
const label = 'Limine ${version} (aarch64, UEFI)'

fn command(program string, args []string, directory string) int {
	mut child := os.new_process(program)
	child.set_args(args)
	child.set_work_folder(directory)
	child.run()
	child.wait()
	code := child.code
	child.close()
	return code
}

fn run(program string, args []string, directory string) ! {
	if command(program, args, directory) != 0 { return error(program + ' failed') }
}

fn expected(path string) bool {
	data := os.read_file(path) or { return false }
	return data.contains(label) && !data.contains('Base revision %u is no longer supported for aarch64')
}

fn build() ! {
	$if !linux {
		return error('Build Tulpar on Linux')
	}
	root := os.real_path(os.dir(@FILE) + '/..')
	boot := root + '/boot-image'
	source := boot + '/limine-src-' + version
	installed := boot + '/limine-bin/BOOTAA64.EFI'
	if os.args.len == 2 && os.args[1] == '--check' {
		if !expected(installed) { return error('Missing or unexpected ARM64 loader: ' + installed) }
		println(label + ': ' + sha256.sum(os.read_bytes(installed)!).hex())
		return
	}
	if os.args.len != 1 { return error('Usage: build-limine-aarch64.v [--check]') }
	_ = os.find_abs_path_of_executable('llvm-objcopy') or { return error('Install LLVM, including llvm-objcopy') }
	if !os.is_dir(source) {
		work := os.join_path(os.temp_dir(), 'tulpar-limine-' + os.getpid().str())
		os.mkdir(work)!
		defer { os.rmdir_all(work) or {} }
		archive := work + '/source.tar.gz'
		run('curl', ['-fsSL',
			'https://github.com/limine-bootloader/limine/releases/download/v${version}/limine-${version}.tar.gz',
			'-o', archive], root)!
		if sha256.sum(os.read_bytes(archive)!).hex() != digest {
			return error('Limine source checksum mismatch')
		}
		run('tar', ['xzf', archive, '-C', work], root)!
		os.mkdir_all(boot)!
		os.mv(work + '/limine-' + version, source)!
	}
	patch_directory := root + '/build-support/limine'
	mut patches := os.ls(patch_directory)!
	patches.sort()
	for name in patches {
		if !name.starts_with(version + '-') || !name.ends_with('.patch') { continue }
		patch := patch_directory + '/' + name
		if command('git', ['apply', '--check', patch], source) == 0 {
			run('git', ['apply', patch], source)!
		} else if command('git', ['apply', '--reverse', '--check', patch], source) != 0 {
			return error('Cannot apply or verify Limine patch: ' + name)
		}
	}
	if !os.is_file(source + '/GNUmakefile') {
		run('./configure', ['--enable-uefi-aarch64', '--disable-uefi-cd', '--disable-bios',
			'--disable-bios-cd', '--disable-bios-pxe'], source)!
	}
	run('make', ['-j' + runtime.nr_cpus().str()], source)!
	loader := source + '/bin/BOOTAA64.EFI'
	if !expected(loader) { return error('Unexpected ARM64 loader version or protocol support') }
	os.mkdir_all(os.dir(installed))!
	if os.is_file(installed) && os.read_bytes(installed)! != os.read_bytes(loader)! {
		os.cp(installed, installed + '.previous')!
	}
	os.cp(loader, installed)!
	println('Installed ' + label)
}

fn main() {
	build() or {
		eprintln(err)
		exit(1)
	}
}
