// SPDX-License-Identifier: GPL-2.0-or-later
// Bounded VT100 screen state for local, text-only terminals. No output history
// or keyboard input is retained; switching paints only the current screen.
module vtscreen

pub const rows = 23
pub const columns = 80
pub const cells = rows * columns

pub struct Cell {
pub mut:
	character u8 = ` `
	style     u16
}

pub struct Screen {
pub mut:
	primary            [cells]Cell
	alternate          [cells]Cell
	x                  int
	y                  int
	saved_x            int
	saved_y            int
	saved_style        u16
	primary_x          int
	primary_y          int
	style              u16
	top                int
	bottom             int = rows - 1
	alt                bool
	visible            bool = true
	application_cursor bool
	reply              int
	wrap               bool = true
	pending_wrap       bool
mut:
	state        int
	parameters   [16]int
	parameter    int
	private_mode bool
}

pub fn (s &Screen) cell(index int) Cell {
	cell := if s.alt { s.alternate[index] } else { s.primary[index] }
	return if cell.character == 0 { Cell{ character: ` `, style: cell.style } } else { cell }
}

fn (mut s Screen) put(index int, cell Cell) {
	if index < 0 || index >= cells { return }
	if s.alt { s.alternate[index] = cell } else { s.primary[index] = cell }
}

fn (mut s Screen) clear(first int, end int) {
	for i := first; i < end; i++ { s.put(i, Cell{ style: s.style }) }
}

fn bounded(value int, maximum int) int {
	if value < 0 { return 0 }
	if value > maximum { return maximum }
	return value
}

fn (mut s Screen) scroll(up bool, requested int) {
	count := bounded(requested, s.bottom - s.top + 1)
	if up {
		for row := s.top; row <= s.bottom - count; row++ {
			for col in 0 .. columns {
				s.put(row * columns + col, s.cell((row + count) * columns + col))
			}
		}
		s.clear((s.bottom - count + 1) * columns, (s.bottom + 1) * columns)
	} else {
		for row := s.bottom; row >= s.top + count; row-- {
			for col in 0 .. columns {
				s.put(row * columns + col, s.cell((row - count) * columns + col))
			}
		}
		s.clear(s.top * columns, (s.top + count) * columns)
	}
}

fn (mut s Screen) linefeed() {
	if s.y == s.bottom { s.scroll(true, 1) } else { s.y = bounded(s.y + 1, rows - 1) }
	s.pending_wrap = false
}

fn (s &Screen) argument(index int, fallback int) int {
	if index > s.parameter || s.parameters[index] == 0 { return fallback }
	return s.parameters[index]
}

fn (mut s Screen) save() {
	s.saved_x = s.x
	s.saved_y = s.y
	s.saved_style = s.style
}

fn (mut s Screen) restore() {
	s.x = s.saved_x
	s.y = s.saved_y
	s.style = s.saved_style
	s.pending_wrap = false
}

fn (mut s Screen) mode(on bool) {
	for i := 0; i <= s.parameter; i++ {
		match s.parameters[i] {
			1 { s.application_cursor = on }
			7 { s.wrap = on }
			25 { s.visible = on }
			47, 1047, 1049 {
				if on && !s.alt {
					s.primary_x = s.x
					s.primary_y = s.y
					s.alt = true
					s.x = 0
					s.y = 0
					s.clear(0, cells)
				} else if !on && s.alt {
					s.alt = false
					s.x = s.primary_x
					s.y = s.primary_y
				}
			}
			else {}
		}
	}
}

fn (mut s Screen) attributes() {
	for i := 0; i <= s.parameter; i++ {
		value := s.parameters[i]
		match value {
			0 { s.style = 0 }
			1 { s.style |= 0x100 }
			4 { s.style |= 0x200 }
			7 { s.style |= 0x400 }
			22 { s.style &= ~u16(0x100) }
			24 { s.style &= ~u16(0x200) }
			27 { s.style &= ~u16(0x400) }
			30...37 { s.style = (s.style & ~u16(15)) | u16(value - 29) }
			39 { s.style &= ~u16(15) }
			40...47 { s.style = (s.style & ~u16(240)) | u16(value - 39) << 4 }
			49 { s.style &= ~u16(240) }
			90...97 { s.style = (s.style & ~u16(15)) | u16(value - 89) | 0x100 }
			100...107 { s.style = (s.style & ~u16(240)) | u16(value - 99) << 4 }
			else {}
		}
	}
}

fn (mut s Screen) csi(command u8) {
	n := s.argument(0, 1)
	position := s.y * columns + s.x
	match command {
		`A` { s.y = bounded(s.y - n, rows - 1) }
		`B` { s.y = bounded(s.y + n, rows - 1) }
		`C` { s.x = bounded(s.x + n, columns - 1) }
		`D` { s.x = bounded(s.x - n, columns - 1) }
		`E` {
			s.y = bounded(s.y + n, rows - 1)
			s.x = 0
		}
		`F` {
			s.y = bounded(s.y - n, rows - 1)
			s.x = 0
		}
		`G`, u8(96) { s.x = bounded(n - 1, columns - 1) }
		`d` { s.y = bounded(n - 1, rows - 1) }
		`H`, `f` {
			s.y = bounded(n - 1, rows - 1)
			s.x = bounded(s.argument(1, 1) - 1, columns - 1)
		}
		`J` {
			match s.parameters[0] {
				0 { s.clear(position, cells) }
				1 { s.clear(0, position + 1) }
				2, 3 { s.clear(0, cells) }
				else {}
			}
		}
		`K` {
			match s.parameters[0] {
				0 { s.clear(position, (s.y + 1) * columns) }
				1 { s.clear(s.y * columns, position + 1) }
				2 { s.clear(s.y * columns, (s.y + 1) * columns) }
				else {}
			}
		}
		`m` { s.attributes() }
		`r` {
			top := bounded(n - 1, rows - 1)
			bottom := bounded(s.argument(1, rows) - 1, rows - 1)
			if top < bottom {
				s.top = top
				s.bottom = bottom
				s.x = 0
				s.y = 0
			}
		}
		`S` { s.scroll(true, n) }
		`T` { s.scroll(false, n) }
		`L`, `M` {
			if s.y >= s.top && s.y <= s.bottom {
				top := s.top
				s.top = s.y
				s.scroll(command == `M`, n)
				s.top = top
			}
		}
		`@`, `P`, `X` {
			count := bounded(n, columns - s.x)
			if command == `@` {
				for col := columns - 1; col >= s.x + count; col-- {
					s.put(s.y * columns + col, s.cell(s.y * columns + col - count))
				}
				s.clear(position, position + count)
			} else if command == `P` {
				for col := s.x; col < columns - count; col++ {
					s.put(s.y * columns + col, s.cell(s.y * columns + col + count))
				}
				s.clear((s.y + 1) * columns - count, (s.y + 1) * columns)
			} else {
				s.clear(position, position + count)
			}
		}
		`s` { s.save() }
		`u` { s.restore() }
		`n` {
			if s.parameters[0] == 6 { s.reply = 1 }
		}
		`c` { s.reply = 2 }
		`h`, `l` {
			if s.private_mode { s.mode(command == `h`) }
		}
		else {}
	}
	s.pending_wrap = false
}

pub fn (mut s Screen) feed(bytes &u8, length int) {
	for i in 0 .. length {
		ch := unsafe { bytes[i] }
		if ch == 0x18 || ch == 0x1a {
			s.state = 0
			continue
		}
		if s.state == 3 || s.state == 4 {
			if ch == 7 || (s.state == 4 && ch == `\\`) {
				s.state = 0
			} else if ch == 0x1b {
				s.state = 4
			} else {
				s.state = 3
			}
			continue
		}
		if ch == 0x1b {
			s.state = 1
			continue
		}
		if s.state == 1 {
			s.state = 0
			match ch {
				`[` {
					s.state = 2
					s.parameter = 0
					s.private_mode = false
					for j in 0 .. 16 { s.parameters[j] = 0 }
				}
				`]`, `P`, `^`, `_` { s.state = 3 }
				`(`, `)`, `#` { s.state = 5 }
				`7` { s.save() }
				`8` { s.restore() }
				`D` { s.linefeed() }
				`E` {
					s.x = 0
					s.linefeed()
				}
				`M` {
					if s.y == s.top { s.scroll(false, 1) } else { s.y = bounded(s.y - 1, rows - 1) }
				}
				`c` { s = Screen{} }
				else {}
			}
			continue
		}
		if s.state == 5 {
			s.state = 0
			continue
		}
		if s.state == 2 {
			if ch >= `0` && ch <= `9` {
				s.parameters[s.parameter] = bounded(s.parameters[s.parameter] * 10 + int(ch - `0`), 10000)
			} else if ch == `;` {
				if s.parameter < 15 { s.parameter++ }
			} else if ch == `?` {
				s.private_mode = true
			} else if ch >= 0x40 && ch <= 0x7e {
				s.csi(ch)
				s.state = 0
			}
			continue
		}
		match ch {
			`\r` {
				s.x = 0
				s.pending_wrap = false
			}
			`\n`, 11, 12 { s.linefeed() }
			`\b` {
				s.x = bounded(s.x - 1, columns - 1)
				s.pending_wrap = false
			}
			`\t` {
				s.x = bounded((s.x / 8 + 1) * 8, columns - 1)
				s.pending_wrap = false
			}
			32...126, 160...255 {
				if s.pending_wrap && s.wrap {
					s.x = 0
					s.linefeed()
				}
				s.put(s.y * columns + s.x, Cell{ch, s.style})
				if s.x == columns - 1 { s.pending_wrap = true } else { s.x++ }
			}
			else {}
		}
	}
}
