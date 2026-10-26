module main

fn test_securelevel_values() {
 for value, expected in {'-1': -1, '0': 0, '1': 1, '2': 2, ' \t1\r\n': 1} {
  actual, valid := parse_securelevel_value(value)
  assert valid && actual == expected
 }
 for value in ['', ' ', '3', '-2', 'garbage', '+1', '01', '1x', '1 2', '1\x00', '2147483648'] {
  _, valid := parse_securelevel_value(value)
  assert !valid
 }
}

fn test_securelevel_boot_tokens() {
 for value, expected in {'': -2, 'other=1': -2, 'tulpar.securelevel=1': 1,
  'other=1\ttulpar.securelevel=2\nlast=3': 2, 'tulpar.securelevel=-1': -1,
  'tulpar.securelevel=0': 0, 'xtulpar.securelevel=2': -2,
  'other=tulpar.securelevel=2': -2, 'tulpar.securelevel_extra=2': -2} {
  actual, valid := parse_securelevel_boot(value)
  assert valid && actual == expected
 }
 for value in ['tulpar.securelevel', 'tulpar.securelevel=', 'tulpar.securelevel=3',
  'tulpar.securelevel=garbage', 'tulpar.securelevel=1x', 'tulpar.securelevel=+1',
  'tulpar.securelevel=1 tulpar.securelevel=2', 'tulpar.securelevel=1 tulpar.securelevel=1',
  'tulpar.securelevel= 1'] {
  _, valid := parse_securelevel_boot(value)
  assert !valid
 }
 _, valid := parse_securelevel_boot(' '.repeat(securelevel_cmdline_max))
 assert !valid
}
