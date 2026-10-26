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

fn qemu(arch string) string {
	return if arch == 'arm64' { 'qemu-system-aarch64' } else { 'qemu-system-x86_64' }
}

fn guest_args(arch string) ![]string {
	if !os.is_file(image(arch)) { return error('Build the image first: ' + image(arch)) }
	accel := os.getenv_opt('TULPAR_ACCEL') or { 'tcg' }
	if accel !in ['tcg', 'kvm'] { return error('TULPAR_ACCEL must be tcg or kvm') }
	cpu := if accel == 'tcg' { 'max' } else { 'host' }
	mut args := ['-m', '512', '-smp', '2', '-display', 'none', '-no-reboot']
	if arch == 'arm64' {
		args << ['-machine', 'virt,gic-version=3', '-cpu', cpu, '-accel', accel, '-bios',
			firmware(arch)!, '-device', 'ramfb', '-device', 'virtio-scsi-pci', '-drive',
			'if=none,id=cd,media=cdrom,readonly=on,file=' + image(arch), '-device', 'scsi-cd,drive=cd',
			'-netdev', 'user,id=net0', '-device', 'virtio-net-device,netdev=net0']
	} else {
		args << ['-machine', 'q35,smm=off', '-cpu', cpu, '-accel', accel, '-drive',
			'if=pflash,format=raw,unit=0,readonly=on,file=' + firmware(arch)!, '-cdrom', image(arch),
			'-nic', 'user,model=e1000']
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
	text   string
	cursor int
	path   string
}

fn receive(mut connection unix.StreamConn, mut transcript Transcript, expected string, seconds int) ! {
	deadline := time.sys_mono_now() + u64(seconds) * u64(time.second)
	mut bytes := [4096]u8{}
	for time.sys_mono_now() < deadline {
		if position := transcript.text[transcript.cursor..].index(expected) {
			transcript.cursor += position + expected.len
			return
		}
		connection.wait_for_read() or { continue }
		length := connection.read(mut bytes) or { continue }
		if length == 0 { break }
		transcript.text += bytes[..length].bytestr()
		if transcript.path != '' { os.write_file(transcript.path, transcript.text)! }
	}
	return error('Guest timed out waiting for: ' + expected)
}

fn login(mut connection unix.StreamConn, mut transcript Transcript, name string, password string, prompt string) ! {
	connection.write_string(name + '\n')!
	receive(mut connection, mut transcript, 'Password:', 15)!
	start := transcript.text.len
	connection.write_string(password + '\n')!
	receive(mut connection, mut transcript, prompt, 20)!
	if transcript.text[start..].contains(password) {
		return error('Password echoed on the console')
	}
}

fn verdict(mut connection unix.StreamConn, mut transcript Transcript, command string, marker string, prompt string, seconds int) ! {
	connection.write_string(command + '\n')!
	receive(mut connection, mut transcript, marker, seconds)!
	receive(mut connection, mut transcript, prompt, 15)!
}

pub fn check_guest(arch string, requested string) ! {
	selected := if requested == '' {
		os.home_dir() + '/.local/state/tulpar/terminal-' + arch + '-' + time.now().unix_nano().str()
	} else {
		requested
	}
	if selected == root() || selected.starts_with(root() + '/') {
		return error('Keep QEMU evidence outside the source tree')
	}
	if os.exists(selected) { return error('Use a fresh state directory: ' + selected) }
	os.mkdir_all(selected)!
	check_inventory(directory(arch) + '/root')!
	os.write_file(selected + '/source-revision.txt', capture('git', ['-C', root(), 'rev-parse',
		'HEAD'])! + '\n')!
	os.write_file(selected + '/source-changes.patch', capture('git', ['-C', root(), 'diff', '--binary',
		'HEAD'])! + '\n')!
	os.write_file(selected + '/guest-files.txt', capture('tar', ['-tf',
		directory(arch) + '/initramfs.tar'])! + '\n')!
	mut hashes := ''
	for item in [[image(arch), 'boot.iso'], [directory(arch) + '/kernel/bin/tulpar', 'kernel.elf'],
		[directory(arch) + '/initramfs.tar', 'initramfs.tar']] {
		destination := selected + '/' + item[1]
		os.cp(item[0], destination)!
		hashes += sha256.sum(os.read_bytes(destination)!).hex() + '  ' + item[1] + '\n'
	}
	os.write_file(selected + '/image-checksums.txt', hashes)!
	socket := selected + '/serial.sock'
	mut args := guest_args(arch)!
	args << ['-monitor', 'none', '-chardev', 'socket,id=serial,path=' + socket + ',server=on,wait=on',
		'-serial', 'chardev:serial']
	mut guest := os.new_process(qemu(arch))
	guest.set_args(args)
	guest.run()
	defer {
		if guest.is_alive() {
			guest.signal_kill()
			guest.wait()
		}
		guest.close()
	}
	for _ in 0 .. 1000 {
		if os.exists(socket) { break }
		if !guest.is_alive() { return error('QEMU failed to start') }
		time.sleep(10 * time.millisecond)
	}
	mut connection := unix.connect_stream(socket)!
	defer { connection.close() or {} }
	connection.set_read_timeout(250 * time.millisecond)
	mut transcript := Transcript{ path: selected + '/serial.log' }
	defer { os.write_file(selected + '/serial.log', transcript.text) or {} }
	password := 'Terminal-Verify-2026!'
	receive(mut connection, mut transcript, 'New password:', 120)!
	start_password := transcript.text.len
	connection.write_string(password + '\n')!
	receive(mut connection, mut transcript, 'Retype password:', 15)!
	connection.write_string(password + '\n')!
	receive(mut connection, mut transcript, 'tulpar login:', 25)!
	if transcript.text[start_password..].contains(password) {
		return error('Root password setup echoed a password')
	}
	if transcript.text.to_lower().contains('vinix') {
		return error('Old branding in kernel boot output')
	}
	for unwanted in ['>+', ' sz=', 'no ustar sig', 'initramfs: invalid', 'initramfs: truncated'] {
		if transcript.text.contains(unwanted) {
			return error('Unexpected boot output: ' + unwanted)
		}
	}
	for expected in ['initramfs: ready (', 'driver ', ' attached',
		if arch == 'amd64' { 'e1000: ready' } else { 'virtio-net: ready' }] {
		if !transcript.text.contains(expected) {
			return error('Missing boot diagnostic: ' + expected)
		}
	}
	if arch == 'amd64' && (!transcript.text.contains('vendor=8086 device=100e') || !transcript.text.contains('class=02:00')) {
		return error('Missing PCI Ethernet device identity')
	}
	connection.write_string('root\n')!
	receive(mut connection, mut transcript, 'Password:', 15)!
	connection.write_string('definitely-wrong\n')!
	receive(mut connection, mut transcript, 'Login incorrect', 20)!
	receive(mut connection, mut transcript, 'tulpar login:', 15)!
	login(mut connection, mut transcript, 'root', password, 'tulpar# ')!
	interactive_start := transcript.text.len
	// Reproduce the delayed entropy diagnostic while vi owns the screen. The
	// message must be retained in bootlog without reaching the editor display.
	connection.write_string('vi /tmp/console-probe\n')!
	receive(mut connection, mut transcript, '/tmp/console-probe 1/1 100%', 10)!
	connection.write_string('inasilsin yawa')!
	connection.write_string('\x1d2')!
	receive(mut connection, mut transcript, 'tulpar login:', 15)!
	login(mut connection, mut transcript, 'root', password, 'tulpar# ')!
	verdict(mut connection, mut transcript,
		"stty -a; stty -a | grep -Eq '(^|[[:space:];])isig([[:space:];]|$)' && printf 'PTY_%s\\n' ISIG",
		'PTY_ISIG', 'tulpar# ', 15)!
	verdict(mut connection, mut transcript,
		'test "$(tty)" = /dev/pts/1 && test "$(stty size)" = \'23 80\' && printf \'SECOND_%s\\n\' PASS',
		'SECOND_PASS', 'tulpar# ', 15)!
	connection.write_string('\x1d1')!
	receive(mut connection, mut transcript, 'nasilsin yawa', 15)!
	connection.write_string('x')!
	receive(mut connection, mut transcript, 'nasilsin yawax', 15)!
	connection.write_string('\x7f')!
	receive(mut connection, mut transcript, 'nasilsin yawa ', 15)!
	time.sleep(40 * time.second)
	connection.write_string('\x1b')!
	time.sleep(300 * time.millisecond)
	connection.write_string(':wq\n')!
	receive(mut connection, mut transcript, 'tulpar# ', 15)!
	for unwanted in ['random: reseeded from', 'ELF auxval:'] {
		if transcript.text[interactive_start..].contains(unwanted) {
			return error('Kernel log overwrote the interactive console: ' + unwanted)
		}
	}
	connection.write_string('if test "$(cat /tmp/console-probe)" = \'nasilsin yawa\' && grep -q \'random: reseeded from\' /proc/bootlog && ! grep -q \'nasilsin yawa\' /proc/bootlog; then printf \'CONSOLE_%s\\n\' PASS; fi; printf \'CONSOLE_%s\\n\' DONE\n')!
	receive(mut connection, mut transcript, 'CONSOLE_DONE', 15)!
	if !transcript.text.contains('CONSOLE_PASS') {
		return error('Console handoff, retained kernel log or vi file contents failed')
	}
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string('uname -a; cat /proc/version; cat /proc/sys/kernel/ostype; cat /proc/sys/kernel/hostname; cat /etc/os-release; if test "$(uname -s)" = Tulpar && test "$(hostname)" = tulpar && test "$(cat /proc/sys/kernel/ostype)" = Tulpar && test "$(cat /proc/sys/kernel/hostname)" = tulpar && grep -q \'^Tulpar version\' /proc/version && grep -q \'^NAME=Tulpar\' /etc/os-release; then printf \'IDENTITY_%s\\n\' PASS; fi; printf \'IDENTITY_%s\\n\' DONE\n')!
	receive(mut connection, mut transcript, 'IDENTITY_DONE', 15)!
	if !transcript.text.contains('IDENTITY_PASS') {
		return error('Guest OS identity is not consistently Tulpar')
	}
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string('printf \'ARCH=%s\\n\' "$(uname -m)"; printf \'ARITH=%s\\n\' "$((20+26))"; echo tulpar > /tmp/probe; cat /tmp/probe | grep -q tulpar && printf \'PIPE_%s\\n\' PASS; (sleep 1; exit 7) & wait $!; test $? -eq 7 && printf \'WAIT_%s\\n\' PASS; stty -a; cat /proc/meminfo; printf \'COMMANDS_%s\\n\' DONE\n')!
	receive(mut connection, mut transcript, 'COMMANDS_DONE', 30)!
	for expected in ['ARCH=' + target(arch), 'ARITH=46', 'PIPE_PASS', 'WAIT_PASS'] {
		if !transcript.text.contains(expected) {
			return error('Missing guest verdict: ' + expected)
		}
	}
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	connection.write_string("ping -q -c 2 -W 2 127.0.0.1 && printf 'ICMP_%s\\n' LOOPBACK; for attempt in $(seq 1 30); do test -s /etc/resolv.conf && break; sleep 1; done; cat /etc/resolv.conf; for attempt in 1 2 3; do if ping -q -c 1 -W 2 10.0.2.2; then printf 'ICMP_%s\\n' GATEWAY; break; fi; sleep 1; done; if su -s /bin/sh -c 'ping -q -c 1 -W 1 127.0.0.1' nobody >/tmp/icmp-denied 2>&1; then printf 'ICMP_%s\\n' UNSAFE; elif grep -Ei 'not permitted|permission denied' /tmp/icmp-denied; then printf 'ICMP_%s\\n' DENIED; fi; printf 'ICMP_%s\\n' DONE\n")!
	receive(mut connection, mut transcript, 'ICMP_DONE', 60)!
	for expected in ['ICMP_LOOPBACK', 'ICMP_GATEWAY', 'ICMP_DENIED'] {
		if !transcript.text.contains(expected) {
			return error('Missing guest verdict: ' + expected)
		}
	}
	receive(mut connection, mut transcript, 'tulpar# ', 10)!
	// Create an ordinary account with BusyBox and authenticate it on a
	// separate terminal. Password input is interactive and must not echo.
	connection.write_string('adduser -D -s /bin/sh alice\n')!
	receive(mut connection, mut transcript, 'tulpar# ', 15)!
	connection.write_string('passwd alice\n')!
	receive(mut connection, mut transcript, 'New password:', 15)!
	normal_password_start := transcript.text.len
	connection.write_string(password + '\n')!
	receive(mut connection, mut transcript, 'Retype password:', 15)!
	connection.write_string(password + '\n')!
	receive(mut connection, mut transcript, 'tulpar# ', 15)!
	if transcript.text[normal_password_start..].contains(password) {
		return error('Ordinary account password setup echoed a password')
	}
	connection.write_string('\x1d3')!
	receive(mut connection, mut transcript, 'tulpar login:', 15)!
	login(mut connection, mut transcript, 'alice', password, 'tulpar$ ')!
	verdict(mut connection, mut transcript,
		'if test "$(id -un)" = alice && test "$(id -u)" != 0 && test "$HOME" = /home/alice && test ! -r /etc/shadow && test ! -r /dev/console && test ! -r /dev/pts/0; then printf \'USER_%s\\n\' PASS; fi',
		'USER_PASS', 'tulpar$ ', 15)!
	connection.write_string('\x1d2')!
	receive(mut connection, mut transcript, 'tulpar# ', 15)!
	verdict(mut connection, mut transcript,
		"grep -q 'root login' /var/log/messages && grep -q 'invalid password' /var/log/messages && printf 'LOG_%s\\n' PASS",
		'LOG_PASS', 'tulpar# ', 15)!
	verdict(mut connection, mut transcript,
		'killall -9 syslogd; sleep 2; if test -S /dev/log && test "$(grep -c \'syslogd started\' /var/log/messages)" -ge 2; then printf \'LOGGER_%s\\n\' PASS; fi',
		'LOGGER_PASS', 'tulpar# ', 15)!
	connection.write_string('exit\n')!
	receive(mut connection, mut transcript, 'tulpar login:', 20)!
	login(mut connection, mut transcript, 'root', password, 'tulpar# ')!
	verdict(mut connection, mut transcript, "printf 'RELOGIN_%s\\n' PASS",
		'RELOGIN_PASS', 'tulpar# ', 15)!
	connection.write_string('\x1d4')!
	receive(mut connection, mut transcript, 'tulpar login:', 15)!
	login(mut connection, mut transcript, 'root', password, 'tulpar# ')!
	verdict(mut connection, mut transcript,
		'case "$(stty -a < /dev/console)" in *-isig*) printf \'RAW_%s\\n\' PASS;; esac',
		'RAW_PASS', 'tulpar# ', 15)!
	connection.write_string('sh -c \'printf "SLEEP_%s\\n" STARTED; exec sleep 30\'\n')!
	receive(mut connection, mut transcript, 'SLEEP_STARTED', 15)!
	time.sleep(2 * time.second)
	connection.write_string('\x03')!
	receive(mut connection, mut transcript, '^C', 15)!
	receive(mut connection, mut transcript, 'tulpar# ', 15)!
	verdict(mut connection, mut transcript, "printf 'FINAL_%s\\n' READY",
		'FINAL_READY', 'tulpar# ', 10)!
	connection.write_string('poweroff -f\n')!
	shutdown_deadline := time.sys_mono_now() + u64(20) * u64(time.second)
	mut shutdown_bytes := [4096]u8{}
	for guest.is_alive() && time.sys_mono_now() < shutdown_deadline {
		if length := connection.read(mut shutdown_bytes) {
			if length > 0 {
				transcript.text += shutdown_bytes[..length].bytestr()
				os.write_file(transcript.path, transcript.text)!
			}
		} else {
			time.sleep(10 * time.millisecond)
		}
	}
	if guest.is_alive() { return error('Guest poweroff did not terminate QEMU') }
	guest.wait()
	if guest.code != 0 { return error('QEMU exited with code ' + guest.code.str()) }
	if transcript.text.contains('KERNEL PANIC') {
		return error('Kernel panic in serial transcript')
	}
	if transcript.text[interactive_start..].contains('login[') {
		return error('Authentication log bypassed the local logger')
	}
	os.write_file(selected + '/verdict.txt', 'PASS: ' + arch + ' password setup, rejected login, getty/login, four local terminals, vi state across switching, ordinary user permissions, logout/relogin, bootlog, shell and network checks, poweroff\n')!
	println('PASS: ' + arch + ' authenticated local terminals, ordinary user, vi, IPv4 ICMP, poweroff; ' + selected)
}
