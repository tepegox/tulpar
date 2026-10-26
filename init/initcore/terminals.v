// SPDX-License-Identifier: GPL-2.0-or-later
// A local console multiplexer. PID 1 owns every PTY master; getty/login and
// the authenticated account own the slaves. No network or IPC endpoint.
module initcore

import vtscreen

#include <stdlib.h>
#include <termios.h>
#include <poll.h>
#include <errno.h>

struct C.termios {
mut:
	c_iflag u32
	c_oflag u32
	c_lflag u32
	c_cc    [32]u8
}

struct C.winsize {
mut:
	ws_row u16
	ws_col u16
}

struct C.pollfd {
mut:
	fd      i32
	events  i16
	revents i16
}

@[typedef]
struct C.siginfo_t {
	si_pid i32
}

fn C.fcntl(i32, i32, ...voidptr) i32
fn C.tcgetattr(i32, &C.termios) i32
fn C.tcsetattr(i32, i32, &C.termios) i32
fn C.cfmakeraw(&C.termios)
fn C.read(i32, voidptr, usize) isize
fn C.poll(&C.pollfd, usize, i32) i32
fn C.kill(i32, i32) i32
fn C.waitid(i32, u32, &C.siginfo_t, i32) i32
fn C.__errno_location() &i32
fn C.memmove(voidptr, voidptr, usize) voidptr
fn C.calloc(usize, usize) voidptr
fn C.free(voidptr)
fn C.abort()
fn C.access(&char, i32) i32
fn C.unlink(&char) i32
fn C.usleep(u32) i32

// -no-builtin keeps the init image small. Supply the checked fixed-array
// primitive emitted by V rather than disabling bounds checks.
@[export: 'v_fixed_index']
pub fn checked_index(index i64, length i64) i64 {
	if index < 0 || index >= length { C.abort() }
	return index
}

const terminals = 4

struct LocalTerminal {
mut:
	master  i32 = -1
	pid     i32
	screen  vtscreen.Screen
	input   [4096]u8
	pending int
}

fn errno_value() i32 { return unsafe { *C.__errno_location() } }

fn output(bytes voidptr, length int) bool {
	mut at := 0
	for at < length {
		written := C.write(1, unsafe { voidptr(&u8(bytes) + at) }, uint(length - at))
		if written < 0 && errno_value() == C.EINTR { continue }
		if written <= 0 { return false }
		at += written
	}
	return true
}

fn spawn_login(mut terminal LocalTerminal, all &LocalTerminal) bool {
	master := C.open(c'/dev/ptmx', C.O_RDWR | C.O_NOCTTY | C.O_CLOEXEC)
	if master < 0 { return false }
	mut unlocked := i32(0)
	if C.ioctl(master, C.TIOCSPTLCK, &unlocked) != 0 {
		C.close(master)
		return false
	}
	mut path := [64]char{}
	mut pty_number := u32(0)
	if C.ioctl(master, C.TIOCGPTN, &pty_number) != 0 {
		C.close(master)
		return false
	}
	mut end := append_text(unsafe { &path[0] }, sizeof(path) - 1, 0, c'/dev/pts/')
	end = append_decimal(unsafe { &path[0] }, sizeof(path) - 1, end, int(pty_number))
	path[end] = 0
	mut size := C.winsize{ ws_row: u16(vtscreen.rows), ws_col: u16(vtscreen.columns) }
	if C.ioctl(master, C.TIOCSWINSZ, &size) != 0 {
		C.close(master)
		return false
	}
	child := C.fork()
	if child == 0 {
		for i in 0 .. terminals {
			descriptor := unsafe { all[i].master }
			if descriptor >= 0 { C.close(descriptor) }
		}
		C.close(master)
		slave := C.open(unsafe { &path[0] }, C.O_RDWR | C.O_NOCTTY)
		if slave < 0 { C._exit(126) }
		for number in 0 .. 3 { if C.dup2(slave, i32(number)) < 0 { C._exit(126) } }
		if slave > 2 { C.close(slave) }
		shell_signals(unsafe { nil })
		C.signal(15, unsafe { nil })
		// getty creates the session and invokes /bin/login without -f. No
		// root HOME, USER, login scripts or inherited environment are passed.
		arguments := [&char(c'/sbin/getty'), &char(c'-L'), &char(c'0'), unsafe { &path[0] },
			&char(c'vt100'), &char(unsafe { nil })]!
		environment := [&char(c'PATH=/usr/sbin:/usr/bin:/sbin:/bin'), &char(c'TERM=vt100'),
			&char(unsafe { nil })]!
		C.execve(arguments[0], unsafe { &&char(&arguments[0]) }, unsafe { &&char(&environment[0]) })
		C._exit(127)
	}
	if child < 0 {
		C.close(master)
		return false
	}
	terminal.master = master
	terminal.pid = child
	if C.fcntl(master, C.F_SETFL, C.O_NONBLOCK) < 0 {
		C.kill(child, C.SIGKILL)
		wait_for(child)
		C.close(master)
		terminal.master = -1
		terminal.pid = 0
		return false
	}
	return true
}

fn start_logging() i32 {
	// A dead logger can leave a stale socket pathname. Wait for the new
	// instance to bind its own socket before allowing getty to run.
	C.unlink(c'/dev/log')
	child := C.fork()
	if child == 0 {
		null_fd := C.open(c'/dev/null', C.O_RDWR)
		if null_fd < 0 { C._exit(126) }
		for number in 0 .. 3 { C.dup2(null_fd, i32(number)) }
		if null_fd > 2 { C.close(null_fd) }
		shell_signals(unsafe { nil })
		C.signal(15, unsafe { nil })
		arguments := [&char(c'/sbin/syslogd'), &char(c'-n'), &char(c'-O'), &char(c'/var/log/messages'),
			&char(c'-s'), &char(c'64'), &char(c'-b'), &char(c'1'), &char(unsafe { nil })]!
		environment := [&char(c'PATH=/usr/sbin:/usr/bin:/sbin:/bin'), &char(unsafe { nil })]!
		C.execve(arguments[0], unsafe { &&char(&arguments[0]) }, unsafe { &&char(&environment[0]) })
		C._exit(127)
	}
	if child < 0 { return 0 }
	// login uses LOG_CONS if /dev/log is unavailable. Establish the local log
	// socket first so authentication events cannot overwrite another terminal.
	for _ in 0 .. 500 {
		if C.access(c'/dev/log', C.F_OK) == 0 { return child }
		C.usleep(10000)
	}
	C.kill(child, C.SIGKILL)
	wait_for(child)
	return 0
}

fn retire_login(mut terminal LocalTerminal) {
	// WNOWAIT keeps the leader PID reserved until after signals. Closing the
	// master hangs up the foreground group and revokes its controlling tty.
	C.close(terminal.master)
	C.kill(-terminal.pid, C.SIGHUP)
	C.kill(-terminal.pid, C.SIGKILL)
	wait_for(terminal.pid)
	terminal = LocalTerminal{}
}

fn reap_sessions(sessions &LocalTerminal, logger i32, active int) u32 {
	mut changes := u32(0)
	for {
		mut info := C.siginfo_t{}
		if C.waitid(C.P_ALL, 0, unsafe { &info }, C.WEXITED | C.WNOHANG | C.WNOWAIT) != 0 || info.si_pid == 0 {
			break
		}
		mut known := false
		for i in 0 .. terminals {
			unsafe {
				if sessions[i].pid == info.si_pid {
					mut terminal := &sessions[i]
					retire_login(mut terminal)
					if i == active { changes |= 1 }
					known = true
					break
				}
			}
		}
		if !known { wait_for(info.si_pid) }
		if info.si_pid == logger { changes |= 2 }
	}
	return changes
}

fn append_text(buffer &char, capacity u32, start int, part &char) int {
	mut at := start
	mut index := 0
	for at < int(capacity) && unsafe { part[index] } != 0 {
		unsafe { buffer[at] = part[index] }
		at++
		index++
	}
	return at
}

fn append_decimal(buffer &char, capacity u32, start int, number int) int {
	value := if number < 0 {
		0
	} else {
		number
	}
	mut divisor := 1000000000
	for divisor > 1 && value < divisor { divisor /= 10 }
	mut at := start
	for divisor > 0 && at < int(capacity) {
		unsafe { buffer[at] = char(48 + value / divisor % 10) }
		at++
		divisor /= 10
	}
	return at
}

fn paint(terminal &LocalTerminal, previous &[vtscreen.cells]vtscreen.Cell, force bool, number int) {
	message(c'\x1b[?25l\x1b[?7l\x1b[0m')
	if force { message(c'\x1b[r\x1b[2J') }
	mut buffer := [4096]char{}
	for row in 0 .. vtscreen.rows {
		mut dirty := force
		for col in 0 .. vtscreen.columns {
			at := row * vtscreen.columns + col
			cell := terminal.screen.cell(at)
			if cell.character != unsafe { previous[at].character } || cell.style != unsafe { previous[at].style } {
				dirty = true
			}
		}
		if !dirty { continue }
		mut length := append_text(unsafe { &buffer[0] }, sizeof(buffer), 0, c'\x1b[')
		length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, row + 1)
		length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';1H')
		mut style := u16(0xffff)
		for col in 0 .. vtscreen.columns {
			at := row * vtscreen.columns + col
			cell := terminal.screen.cell(at)
			unsafe { previous[at] = cell }
			if cell.style != style {
				style = cell.style
				fg := int(style & 15)
				bg := int((style >> 4) & 15)
				foreground := if fg == 0 {
					39
				} else if fg <= 8 {
					fg + 29
				} else {
					fg + 81
				}
				background := if bg == 0 {
					49
				} else if bg <= 8 {
					bg + 39
				} else {
					bg + 91
				}
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c'\x1b[0;')
				length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, if style & 0x100 != 0 {
					1
				} else {
					22
				})
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';')
				length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, if style & 0x200 != 0 {
					4
				} else {
					24
				})
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';')
				length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, if style & 0x400 != 0 {
					7
				} else {
					27
				})
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';')
				length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, foreground)
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';')
				length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, background)
				length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c'm')
			}
			if length < sizeof(buffer) {
				buffer[length] = char(cell.character)
				length++
			}
		}
		output(unsafe { &buffer[0] }, length)
	}
	if force {
		mut length := append_text(unsafe { &buffer[0] }, sizeof(buffer), 0,
			c'\x1b[24;1H\x1b[0;7m Tulpar terminal ')
		length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, number + 1)
		length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length,
			c' | Ctrl-] then 1-4 switches terminals \x1b[K\x1b[0m')
		output(unsafe { &buffer[0] }, length)
	}
	mut length := append_text(unsafe { &buffer[0] }, sizeof(buffer), 0, c'\x1b[')
	length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, terminal.screen.y + 1)
	length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c';')
	length = append_decimal(unsafe { &buffer[0] }, sizeof(buffer), length, terminal.screen.x + 1)
	length = append_text(unsafe { &buffer[0] }, sizeof(buffer), length, c'H')
	output(unsafe { &buffer[0] }, length)
	if terminal.screen.visible { message(c'\x1b[?25h') }
}

fn flush_input(mut terminal LocalTerminal) bool {
	if terminal.pending == 0 { return true }
	written := C.write(terminal.master, unsafe { &terminal.input[0] }, uint(terminal.pending))
	if written < 0 { return errno_value() == C.EINTR || errno_value() == C.EAGAIN }
	if written == 0 { return false }
	terminal.pending -= written
	if terminal.pending != 0 {
		unsafe { C.memmove(&terminal.input[0], &terminal.input[written], usize(terminal.pending)) }
	}
	return true
}

fn manage_terminals() i32 {
	mut settings := C.termios{}
	if C.tcgetattr(0, unsafe { &settings }) != 0 {
		message(c'init: cannot read console settings\n')
		return 1
	}
	C.cfmakeraw(unsafe { &settings })
	if C.tcsetattr(0, C.TCSANOW, unsafe { &settings }) != 0 {
		message(c'init: cannot set console raw mode\n')
		return 1
	}
	storage := C.calloc(terminals, sizeof(LocalTerminal))
	if storage == unsafe { nil } {
		message(c'init: no memory for local terminals\n')
		return 1
	}
	defer { C.free(storage) }
	mut sessions := unsafe { &LocalTerminal(storage) }
	unsafe {
		for i in 0 .. terminals { sessions[i] = LocalTerminal{} }
		mut previous := [vtscreen.cells]vtscreen.Cell{}
		mut active := 0
		mut prefix := false
		mut repaint := true
		mut logger := start_logging()
		if logger == 0 {
			message(c'init: cannot start local logging\r\n')
			return 1
		}
		for {
			changes := reap_sessions(sessions, logger, active)
			if changes & 1 != 0 { repaint = true }
			if changes & 2 != 0 {
				logger = start_logging()
				if logger == 0 { return 1 }
			}
			if sessions[active].pid == 0 && !spawn_login(mut sessions[active], sessions) {
				message(c'init: cannot start local login; retrying\r\n')
				C.sleep(1)
				continue
			}
			mut descriptors := [terminals + 1]C.pollfd{}
			descriptors[0] = C.pollfd{
				fd:     0
				events: i16(if sessions[active].pending <= 3968 {
					C.POLLIN
				} else {
					0
				})
			}
			for i in 0 .. terminals {
				descriptors[i + 1] = C.pollfd{
					fd:     sessions[i].master
					events: i16(C.POLLIN | if sessions[i].pending != 0 { C.POLLOUT } else { 0 })
				}
			}
			if C.poll(&descriptors[0], terminals + 1, 100) < 0 && errno_value() != C.EINTR {
				return 1
			}
			mut buffer := [4096]u8{}
			if descriptors[0].revents & C.POLLIN != 0 {
				count := C.read(0, &buffer[0], 128)
				for i := 0; i < count; i++ {
					ch := buffer[i]
					if prefix {
						prefix = false
						if ch >= `1` && ch <= `4` {
							active = int(ch - `1`)
							repaint = true
							continue
						}
						if ch != 0x1d { continue }
					} else if ch == 0x1d {
						prefix = true
						continue
					}
					if sessions[active].pending < 4096 {
						sessions[active].input[sessions[active].pending] = ch
						sessions[active].pending++
					}
				}
			}
			mut changed := repaint
			for i in 0 .. terminals {
				if sessions[i].master < 0 { continue }
				if sessions[i].pending != 0 { flush_input(mut sessions[i]) }
				if descriptors[i + 1].revents & (C.POLLIN | C.POLLHUP) != 0 {
					count := C.read(sessions[i].master, &buffer[0], sizeof(buffer))
					if count > 0 {
						sessions[i].screen.feed(&buffer[0], int(count))
						if sessions[i].screen.reply != 0 && sessions[i].pending < 4000 {
							mut reply := [32]char{}
							mut length := 0
							if sessions[i].screen.reply == 1 {
								length = append_text(&reply[0], sizeof(reply), 0, c'\x1b[')
								length = append_decimal(&reply[0], sizeof(reply), length, sessions[i].screen.y + 1)
								length = append_text(&reply[0], sizeof(reply), length, c';')
								length = append_decimal(&reply[0], sizeof(reply), length, sessions[i].screen.x + 1)
								length = append_text(&reply[0], sizeof(reply), length, c'R')
							} else {
								length = append_text(&reply[0], sizeof(reply), 0, c'\x1b[?1;0c')
							}
							for j := 0; j < length; j++ {
								sessions[i].input[sessions[i].pending] = u8(reply[j])
								sessions[i].pending++
							}
							sessions[i].screen.reply = 0
						}
						if i == active { changed = true }
					}
				}
			}
			if changed {
				paint(&sessions[active], &previous, repaint, active)
				repaint = false
			}
		}
	}
	return 1
}
