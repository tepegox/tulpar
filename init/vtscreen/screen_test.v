module vtscreen

fn send(mut screen Screen, text string) {
	screen.feed(text.str, text.len)
}

fn test_fragmented_editor_screen_and_alternate_restore() {
	mut screen := Screen{}
	send(mut screen, 'shell prompt')
	send(mut screen, '\x1b[?104')
	send(mut screen, '9h\x1b[2J\x1b[3;4H\x1b[1;31mhello')
	assert screen.alt
	assert screen.cell(2 * columns + 3).character == `h`
	assert screen.cell(2 * columns + 3).style == 0x102
	assert screen.x == 8 && screen.y == 2
	send(mut screen, '\x1b[?1049l')
	assert !screen.alt
	assert screen.x == 12 && screen.y == 0
	assert screen.cell(0).character == `s`
}

fn test_scroll_region_erasure_and_line_edits() {
	mut screen := Screen{}
	send(mut screen, 'fixed\x1b[2;4r\x1b[2;1Hone\x1b[3;1Htwo\x1b[4;1Hthree\r\n')
	assert screen.cell(0).character == `f`
	assert screen.cell(columns).character == `t`
	assert screen.cell(2 * columns).character == `t`
	assert screen.cell(3 * columns).character == ` `
	send(mut screen, '\x1b[3;1H\x1b[Linserted\x1b[2K')
	assert screen.cell(2 * columns).character == ` `
	assert screen.cell(3 * columns).character == `t`
}

fn test_bounded_escape_parameters_and_hidden_control_strings() {
	mut screen := Screen{}
	send(mut screen, '\x1b]0;private title\x07\x1b[99999999999999999999;99999999999999999999H!')
	assert screen.cell(cells - 1).character == `!`
	send(mut screen, '\x1b[H\x1b[?25lA\x1b7B\x1b8C')
	assert !screen.visible
	assert screen.cell(0).character == `A`
	assert screen.cell(1).character == `C`
}
