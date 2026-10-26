// SPDX-License-Identifier: GPL-2.0-or-later
module terminalbuild

import os
import net.unix
import time
import crypto.sha256

fn firmware(arch string) !string {
	if selected := os.getenv_opt('TULPAR_FIRMWARE') {
		if !os.is_file(selected) { return error('Firmware not found: ' + selected) }
		return selected
	}
	paths := if arch == 'arm64' {
		['/usr/share/AAVMF/AAVMF_CODE.fd', '/usr/share/qemu-efi-aarch64/QEMU_EFI.fd']
	} else {
		['/usr/share/OVMF/OVMF_CODE_4M.fd', '/usr/share/OVMF/OVMF_CODE.fd']
	}
	for path in paths { if os.is_file(path) { return path } }
	return error('Set TULPAR_FIRMWARE to the UEFI firmware image')
}

fn qemu(arch string) string { return if arch == 'arm64' { 'qemu-system-aarch64' } else { 'qemu-system-x86_64' } }

fn guest_args(arch string) ![]string {
	if !os.is_file(image(arch)) { return error('Build the image first: ' + image(arch)) }
	accel := os.getenv_opt('TULPAR_ACCEL') or { 'tcg' }
	if accel !in ['tcg', 'kvm'] { return error('TULPAR_ACCEL must be tcg or kvm') }
	cpu := if accel == 'tcg' { 'max' } else { 'host' }
	mut args := ['-m', '512', '-smp', '2', '-display', 'none', '-no-reboot']
	if arch == 'arm64' {
		args << ['-machine', 'virt,gic-version=3', '-cpu', cpu, '-accel', accel,
			'-bios', firmware(arch)!, '-device', 'ramfb', '-device', 'virtio-scsi-pci',
			'-drive', 'if=none,id=cd,media=cdrom,readonly=on,file=' + image(arch),
			'-device', 'scsi-cd,drive=cd', '-netdev', 'user,id=net0',
			'-device', 'virtio-net-device,netdev=net0']
	} else {
		args << ['-machine', 'q35,smm=off', '-cpu', cpu, '-accel', accel,
			'-drive', 'if=pflash,format=raw,unit=0,readonly=on,file=' + firmware(arch)!,
			'-cdrom', image(arch), '-nic', 'user,model=e1000']
	}
	return args
}

pub fn run_guest(arch string) ! {
	mut args := guest_args(arch)!
	args << ['-serial', 'mon:stdio']
	println('Tulpar ${arch}: Ctrl-A X exits QEMU')
	run(qemu(arch), args)!
}

struct Transcript {
mut:
	text string
	cursor int
}

fn receive(mut connection unix.StreamConn, mut transcript Transcript, expected string, seconds int) ! {
	deadline := time.sys_mono_now() + u64(seconds) * u64(time.second)
	mut bytes := [4096]u8{}
	for time.sys_mono_now() < deadline {
		if position := transcript.text[transcript.cursor..].index(expected) {
			transcript.cursor += position + expected.len
			return
		}
		length := connection.read(mut bytes) or { continue }
		if length == 0 { break }
		transcript.text += bytes[..length].bytestr()
	}
	return error('Guest timed out waiting for: ' + expected)
}

pub fn check_guest(arch string, requested string) ! {
	selected := if requested == '' {
		os.home_dir() + '/.local/state/tulpar/terminal-' + arch + '-' + time.now().unix_nano().str()
	} else { requested }
	if selected == root() || selected.starts_with(root() + '/') {
		return error('Keep QEMU evidence outside the source tree')
	}
	if os.exists(selected) { return error('Use a fresh state directory: ' + selected) }
	os.mkdir_all(selected)!
	check_inventory(directory(arch) + '/root')!
	os.write_file(selected + '/source-revision.txt', capture('git', ['-C', root(), 'rev-parse', 'HEAD'])! + '\n')!
	os.write_file(selected + '/guest-files.txt', capture('tar', ['-tf', directory(arch) + '/initramfs.tar'])! + '\n')!
	mut hashes := ''
	for path in [image(arch), directory(arch) + '/kernel/bin/vinix', directory(arch) + '/initramfs.tar'] {
		hashes += sha256.sum(os.read_bytes(path)!).hex() + '  ' + path + '\n'
	}
	os.write_file(selected + '/image-checksums.txt', hashes)!
	socket := selected + '/serial.sock'
	mut args := guest_args(arch)!
	args << ['-monitor', 'none', '-chardev', 'socket,id=serial,path=' + socket + ',server=on,wait=on',
		'-serial', 'chardev:serial']
	mut guest := os.new_process(qemu(arch))
	guest.set_args(args)
	guest.run()
	defer { if guest.is_alive() { guest.signal_kill(); guest.wait() }; guest.close() }
	for _ in 0 .. 1000 {
		if os.exists(socket) { break }
		if !guest.is_alive() { return error('QEMU failed to start') }
		time.sleep(10 * time.millisecond)
	}
	mut connection := unix.connect_stream(socket)!
	defer { connection.close() or {} }
	connection.set_read_timeout(250 * time.millisecond)
	mut transcript := Transcript{}
	defer { os.write_file(selected + '/serial.log', transcript.text) or {} }
	receive(mut connection, mut transcript, 'tulpar# ', 120)!
	connection.write_string("printf 'ARCH=%s\\n' \"$(uname -m)\"; printf 'ARITH=%s\\n' \"$((20+26))\"; echo tulpar > /tmp/probe; cat /tmp/probe | grep -q tulpar && printf 'PIPE_%s\\n' PASS; (sleep 1; exit 7) & wait $!; test $? -eq 7 && printf 'WAIT_%s\\n' PASS; stty -a; cat /proc/meminfo; printf 'COMMANDS_%s\\n' DONE\n")!
	receive(mut connection, mut transcript, 'COMMANDS_DONE', 30)!
	for expected in ['ARCH=' + target(arch), 'ARITH=46', 'PIPE_PASS', 'WAIT_PASS'] {
		if !transcript.text.contains(expected + '\r\n') && !transcript.text.contains(expected + '\n') {
			return error('Missing guest verdict: ' + expected)
		}
	}
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string('sleep 30\n')!
	time.sleep(500 * time.millisecond)
	connection.write_string('\x03')!
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string('exit\n')!
	receive(mut connection, mut transcript, 'init: restarting shell', 10)!
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string("printf 'RESTART_%s\\n' PASS\npoweroff -f\n")!
	receive(mut connection, mut transcript, 'RESTART_PASS', 10)!
	for _ in 0 .. 2000 {
		if !guest.is_alive() { break }
		time.sleep(10 * time.millisecond)
	}
	if guest.is_alive() { return error('Guest poweroff did not terminate QEMU') }
	guest.wait()
	if guest.code != 0 { return error('QEMU exited with code ' + guest.code.str()) }
	if transcript.text.contains('KERNEL PANIC') { return error('Kernel panic in serial transcript') }
	os.write_file(selected + '/verdict.txt', 'PASS: ' + arch + ' serial input, shell commands, pipes, wait, Ctrl-C, restart, poweroff\n')!
	println('PASS: ${arch} terminal, pipes, wait, Ctrl-C, shell restart, poweroff; ' + selected)
}
