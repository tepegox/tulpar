// SPDX-License-Identifier: GPL-2.0-or-later
// The same bounded PID 1 is linked against musl for both targets.
module initcore

#include <unistd.h>
#include <sys/wait.h>
#include <sys/ioctl.h>
#include <sys/reboot.h>
#include <signal.h>
#include <fcntl.h>

fn C.open(&char, i32) i32
fn C.close(i32) i32
fn C.dup2(i32, i32) i32
fn C.setsid() i32
fn C.setpgid(i32, i32) i32
fn C.getpid() i32
fn C.sethostname(&char, uint) i32
fn C.tcsetpgrp(i32, i32) i32
fn C.ioctl(i32, u64, voidptr) i32
fn C.fork() i32
fn C.execve(&char, &&char, &&char) i32
fn C.waitpid(i32, &i32, i32) i32
fn C.write(i32, voidptr, uint) int
fn C.signal(i32, voidptr) voidptr
fn C.sleep(u32) u32
fn C.sync()
fn C.reboot(i32) i32
fn C._exit(i32)

fn password_ready() bool {
	fd := C.open(c'/etc/shadow', C.O_RDONLY)
	if fd < 0 { return false }
	defer { C.close(fd) }
	mut matched := 0
	mut character := u8(0)
	for C.read(fd, unsafe { &character }, 1) == 1 {
		if character == 10 {
			matched = 0
			continue
		}
		if matched < 0 { continue }
		if matched == 5 {
			// The first byte after root: must be a real password hash.
			return character != 58 && character != 33 && character != 42
		}
		expected := match matched {
			0 { u8(114) }
			1, 2 { u8(111) }
			3 { u8(116) }
			else { u8(58) }
		}
		if character == expected { matched++ } else { matched = -1 }
	}
	return false
}

fn wait_for(child i32) i32 {
	mut status := i32(0)
	for {
		ended := C.waitpid(child, &status, 0)
		if ended == child { return status }
		if ended < 0 { C.sleep(1) }
	}
}

// Password provisioning is interactive and never grants a shell. BusyBox
// owns password hashing; every subsequent session still passes through login.
fn provision_password() {
	mut original := C.termios{}
	for C.tcgetattr(0, unsafe { &original }) != 0 {
		message(c'init: cannot read password terminal settings\r\n')
		C.sleep(1)
	}
	mut hidden := original
	hidden.c_lflag &= ~u32(C.ECHO)
	for C.tcsetattr(0, C.TCSANOW, unsafe { &hidden }) != 0 {
		message(c'init: cannot protect password input\r\n')
		C.sleep(1)
	}
	for !password_ready() {
		message(c'\nTulpar: set the root password before logging in.\n')
		child := C.fork()
		if child == 0 {
			C.setpgid(0, 0)
			C.tcsetpgrp(0, C.getpid())
			shell_signals(unsafe { nil })
			arguments := [&char(c'/bin/busybox'), &char(c'passwd'), &char(c'root'),
				&char(unsafe { nil })]!
			environment := [&char(c'PATH=/usr/sbin:/usr/bin:/sbin:/bin'), &char(c'TERM=vt100'),
				&char(unsafe { nil })]!
			C.execve(arguments[0], unsafe { &&char(&arguments[0]) }, unsafe { &&char(&environment[0]) })
			C._exit(127)
		}
		if child < 0 {
			C.sleep(1)
			continue
		}
		C.setpgid(child, child)
		C.tcsetpgrp(0, child)
		wait_for(child)
		C.tcsetpgrp(0, C.getpid())
	}
	C.tcsetattr(0, C.TCSANOW, unsafe { &original })
}

fn message(text &char) {
	mut length := uint(0)
	for unsafe { text[length] } != 0 { length++ }
	C.write(1, text, length)
}

fn stop(_ i32) {
	C.sync()
	C.reboot(i32(0x4321fedc))
}

fn shell_signals(handler voidptr) {
	C.signal(2, handler)
	C.signal(3, handler)
	C.signal(20, handler)
	C.signal(21, handler)
	C.signal(22, handler)
}

@[export: 'main']
pub fn start() i32 {
	if C.getpid() != 1 { return 1 }
	C.setsid()
	fd := C.open(c'/dev/console', 2)
	if fd < 0 { return 1 }
	for number in 0 .. 3 { C.dup2(fd, i32(number)) }
	if fd > 2 { C.close(fd) }
	C.ioctl(0, 0x540e, unsafe { nil }) // TIOCSCTTY
	C.sethostname(c'tulpar', 6)
	shell_signals(voidptr(1)) // SIG_IGN in the supervisor only.
	C.signal(15, voidptr(stop))
	message(c'\nTulpar: terminal base ready\n')
	provision_password()
	return manage_terminals()
}
