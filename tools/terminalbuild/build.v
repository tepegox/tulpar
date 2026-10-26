// SPDX-License-Identifier: GPL-2.0-or-later
module terminalbuild

import crypto.sha256
import os
import runtime

pub fn root() string { return os.dir(os.dir(os.dir(@FILE))) }

pub fn run(program string, arguments []string) ! {
	mut child := os.new_process(program)
	defer { child.close() }
	child.set_args(arguments)
	child.run()
	child.wait()
	if child.code != 0 { return error('${program} failed (${child.code})') }
}

fn capture(program string, arguments []string) !string {
	mut child := os.new_process(program)
	defer { child.close() }
	child.set_args(arguments)
	child.set_redirect_stdio()
	child.run()
	output := child.stdout_slurp()
	errors := child.stderr_slurp()
	child.wait()
	if child.code != 0 { return error(output + errors) }
	return output.trim_space()
}

fn compiler() string { return os.getenv_opt('V') or { @VEXE } }

fn fetch(url string, path string, expected string) ! {
	if !os.is_file(path) {
		os.mkdir_all(os.dir(path))!
		run('curl', ['-fL', '--retry', '3', '-o', path + '.tmp', url])!
		os.rename(path + '.tmp', path)!
	}
	actual := sha256.sum(os.read_bytes(path)!).hex()
	if actual != expected { return error('SHA256 mismatch: ${path}') }
}

pub fn directory(arch string) string { return root() + '/build/terminal/' + arch }

pub fn image(arch string) string { return root() + '/tulpar-' + arch + '.iso' }

fn target(arch string) string { return if arch == 'arm64' { 'aarch64' } else { 'x86_64' } }

fn userland(arch string) ! {
	work := directory(arch)
	staging := work + '/root'
	sysroot := work + '/sysroot'
	alpine := target(arch)
	cache := root() + '/build/terminal/downloads'
	archive := cache + '/alpine-minirootfs-3.21.7-' + alpine + '.tar.gz'
	digest := if arch == 'arm64' {
		'd1d1a3fae5f4d6146e9742790a47fcb116199622cfb8439f218a4d5fbe5000da'
	} else {
		'8cba1ea3e8b500ea986a313d8eecf3d5952a2a0d23a69117bb81c023d9ceac05'
	}
	fetch('https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/' + alpine + '/' + os.file_name(archive), archive, digest)!
	if os.exists(staging) { os.rmdir_all(staging)! }
	os.mkdir_all(staging)!
	run('tar', ['-xzf', archive, '-C', staging])!
	// Development headers and static libc are build inputs, never guest files.
	dev := cache + '/' + alpine + '-musl-dev.apk'
	dev_hash := if arch == 'arm64' {
		'638945ad611696b7be27f46c4839a3f487ccd1479b648dfe5e2bc87c4710d587'
	} else {
		'0b0357736d51253ddf82a4338378848cfbbe6d695aba60cf7790423670d61b2a'
	}
	fetch('https://dl-cdn.alpinelinux.org/alpine/v3.21/main/' + alpine + '/musl-dev-1.2.5-r12.apk', dev, dev_hash)!
	os.mkdir_all(sysroot)!
	run('tar', ['-xzf', dev, '--exclude=.SIGN.*', '-C', sysroot])!
	os.mkdir_all(sysroot + '/lib')!
	os.cp(staging + '/lib/ld-musl-' + alpine + '.so.1', sysroot + '/lib/libc.so')!
	generated := work + '/init.c'
	run(compiler(), ['-new-compiler', '-shared', '-no-builtin', '-no-closures', '-os', 'linux',
		'-path', '@vlib|@vmodules|' + root() + '/init', '-arch',
		if arch == 'arm64' { 'arm64' } else { 'x64' }, '-target-libc-headers', '-gc', 'none',
		'-manualfree', '-o', generated, root() + '/init/initcore'])!
	os.rm(staging + '/sbin/init') or {}
	run('clang', ['--target=' + alpine + '-linux-musl', '-static', '-nostdinc', '-nostdlib', '-isystem',
		sysroot + '/usr/include', '-D_GNU_SOURCE', '-Os', '-fno-stack-protector', '-w',
		sysroot + '/usr/lib/crt1.o', sysroot + '/usr/lib/crti.o', generated,
		'-L' + sysroot + '/usr/lib', '-lc', sysroot + '/usr/lib/crtn.o', '-fuse-ld=lld', '-o',
		staging + '/sbin/init'])!
	run('llvm-strip', [staging + '/sbin/init'])!
	os.write_file(staging + '/etc/hostname', 'tulpar\n')!
	os.write_file(staging + '/etc/profile', 'export PATH=/usr/sbin:/usr/bin:/sbin:/bin\nexport TERM=vt100\nif [ "$(id -u)" -eq 0 ]; then PS1="tulpar# "; else PS1="tulpar$ "; fi\nexport PS1\n')!
	// The live image has no shared default password or automatic root login.
	mut shadow := os.read_lines(staging + '/etc/shadow')!
	for i, line in shadow {
		if line.starts_with('root:') {
			mut fields := line.split(':')
			fields[1] = '!'
			shadow[i] = fields.join(':')
		}
	}
	os.write_file(staging + '/etc/shadow', shadow.join('\n') + '\n')!
	os.chmod(staging + '/etc/shadow', 0o600)!
	os.write_file(staging + '/etc/issue', 'Tulpar local terminal \\l\n\n')!
	os.write_file(staging + '/etc/motd', 'Tulpar\n')!
	// PID 1's local gettys use dynamic PTYs. Their IDs can change as users
	// allocate PTYs, so a static securetty list would lock out root.
	os.rm(staging + '/etc/securetty') or {}
	os.rm(staging + '/etc/inittab') or {}
	os.write_file(staging + '/etc/os-release', 'NAME=Tulpar\nID=tulpar\nPRETTY_NAME="Tulpar development"\n')!
	for name in ['dev', 'proc', 'sys', 'tmp', 'root', 'run'] { os.mkdir_all(staging + '/' + name)! }
	os.chmod(staging + '/tmp', 0o1777)!
	check_inventory(staging)!
	run('tar', ['--format=ustar', '-cf', work + '/initramfs.tar', '-C', staging, '.'])!
	println('Terminal initramfs: ' + os.file_size(work + '/initramfs.tar').str() + ' bytes')
}

pub fn check_inventory(staging string) ! {
	for name in ['usr/bin/Xorg', 'usr/bin/Xvfb', 'usr/bin/Hyprland', 'usr/bin/tulpar-desktop',
		'usr/bin/vinix-desktop', 'usr/bin/run-android', 'bin/zsh', 'usr/bin/vim', 'usr/bin/gcc',
		'usr/lib/vlang', 'usr/lib/libX11.so', 'root/.oh-my-zsh', 'opt/tulpar-android-aarch64',
		'opt/vinix-android-aarch64'] {
		if os.exists(staging + '/' + name) { return error('Non-base guest content: ' + name) }
	}
	if !os.is_executable(staging + '/sbin/init') || !os.is_executable(staging + '/bin/busybox') {
		return error('Missing terminal base executables')
	}
	for applet in ['sbin/getty', 'bin/login', 'usr/bin/passwd', 'sbin/syslogd'] {
		path := staging + '/' + applet
		if !os.is_link(path) || os.readlink(path)! != '/bin/busybox' {
			return error('Missing BusyBox login applet: ' + applet)
		}
	}
	if os.exists(staging + '/etc/inittab') || os.exists(staging + '/etc/securetty') {
		return error('Unsupported static terminal configuration')
	}
	mut root_locked := false
	for entry in os.read_lines(staging + '/etc/shadow')! {
		if entry.starts_with('root:') {
			root_locked = entry.split(':')[1] == '!'
		}
	}
	if !root_locked { return error('The live image must start with root locked') }
}

fn kernel(arch string) ! {
	source := os.getenv_opt('TULPAR_KERNEL_DIR') or { root() + '/kernel' }
	if !os.is_dir(source + '/freestnd-c-hdrs') { run(source + '/get-deps', [])! }
	work := directory(arch) + '/kernel'
	os.mkdir_all(work)!
	// Kernel generators resolve their maintained sources beside kernel/.
	for name in ['tests', 'build-support', 'tools'] {
		link := directory(arch) + '/' + name
		if !os.exists(link) { os.symlink(root() + '/' + name, link)! }
	}
	run('rsync', ['-aL', '--delete', '--exclude=.git/', '--exclude=*.o', '--exclude=*.a',
		'--exclude=/bin/', '--exclude=/obj/', '--exclude=/cc-runtime-x86_64/',
		'--exclude=/cc-runtime-aarch64/', source + '/', work + '/'])!
	runtime_archive := work + '/cc-runtime-' + target(arch)
	if os.is_link(runtime_archive) { os.rm(runtime_archive)! }
	llvm_ar := os.find_abs_path_of_executable('llvm-ar')!
	linker := os.find_abs_path_of_executable('ld.lld')!
	run('make', ['-C', work, '-j' + runtime.nr_cpus().str(), 'ARCH=' + target(arch), 'CC=clang',
		'AR=' + llvm_ar, 'LD_X86_64=' + linker, 'LD_AARCH64=' + linker, 'LIMINE_MP=1',
		'V=' + compiler()])!
}

fn iso(arch string) ! {
	work := directory(arch)
	run('llvm-strip', ['--strip-debug', '-o', work + '/kernel/bin/tulpar.boot',
		work + '/kernel/bin/tulpar'])!
	os.setenv('TULPAR_' + if arch == 'arm64' { 'AARCH64' } else { 'AMD64' } + '_KERNEL', work + '/kernel/bin/tulpar.boot', true)
	os.setenv('TULPAR_' + if arch == 'arm64' { 'AARCH64' } else { 'AMD64' } + '_INITRAMFS', work + '/initramfs.tar', true)
	os.setenv('TULPAR_' + if arch == 'arm64' { 'AARCH64' } else { 'AMD64' } + '_ISO', image(arch), true)
	run(root() + '/build-support/build-' + if arch == 'arm64' { 'aarch64' } else { 'amd64' } + '-iso.sh', [])!
}

pub fn cli(args []string) ! {
	if args.len == 0 || args[0] in ['--help', '-h'] {
		println('Usage: v run tools/terminal.v build|run|check [--arch=amd64|arm64] [--no-build] [--state-dir=DIR]')
		return
	}
	mut arch := 'amd64'
	mut no_build := false
	mut state := ''
	for arg in args[1..] {
		if arg.starts_with('--arch=') {
			arch = arg.all_after('=')
		} else if arg == '--no-build' {
			no_build = true
		} else if arg.starts_with('--state-dir=') {
			state = os.abs_path(arg.all_after('='))
		} else {
			return error('Unknown option: ' + arg)
		}
	}
	if arch !in ['amd64', 'arm64'] { return error('Unsupported architecture: ' + arch) }
	if args[0] == 'clean' {
		if os.exists(directory(arch)) { os.rmdir_all(directory(arch))! }
		if os.exists(image(arch)) { os.rm(image(arch))! }
		return
	}
	if args[0] !in ['build', 'run', 'check'] { return error('Unknown command: ' + args[0]) }
	if !no_build {
		os.mkdir_all(directory(arch))!
		userland(arch)!
		kernel(arch)!
		iso(arch)!
	}
	if args[0] == 'run' { run_guest(arch)! }
	if args[0] == 'check' { check_guest(arch, state)! }
}
