// SPDX-License-Identifier: GPL-2.0-or-later
// The same allocation-free PID 1 is linked against musl for both targets.
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
	for {
		child := C.fork()
		if child == 0 {
			C.setpgid(0, 0)
			C.tcsetpgrp(0, C.getpid())
			shell_signals(unsafe { nil })
			C.signal(15, unsafe { nil })
			arguments := [&char(c'/bin/sh'), &char(c'-l'), &char(unsafe { nil })]!
			environment := [&char(c'PATH=/usr/sbin:/usr/bin:/sbin:/bin'),
				&char(c'HOME=/root'), &char(c'USER=root'), &char(c'LOGNAME=root'),
				&char(c'TERM=vt100'), &char(c'SHELL=/bin/sh'), &char(c'PS1=tulpar# '),
				&char(unsafe { nil })]!
			C.execve(arguments[0], unsafe { &&char(&arguments[0]) },
				unsafe { &&char(&environment[0]) })
			message(c'init: cannot execute /bin/sh\n')
			C._exit(127)
		}
		if child < 0 { C.sleep(1); continue }
		C.setpgid(child, child)
		C.tcsetpgrp(0, child)
		mut status := i32(0)
		for {
			ended := C.waitpid(-1, unsafe { &status }, 0)
			if ended == child { break }
			// Interrupted waits are retried; adopted children are reaped too.
			if ended < 0 { C.sleep(1) }
		}
		C.tcsetpgrp(0, C.getpid())
		message(c'init: restarting shell\n')
	}
	return 0
}
