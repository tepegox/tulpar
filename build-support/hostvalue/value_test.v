// SPDX-License-Identifier: GPL-2.0-or-later
module hostvalue

import json2

fn test_shared_values_preserve_integer_width() {
	value := json2.decode[Value]('{"large":18446744073709551615,"negative":-1,"items":[true,"text"]}') or { panic(err) }
	assert encode(field(value.object(), 'large')) == '18446744073709551615'
	large := integer(field(value.object(), 'large')) or { u64(0) }
	assert large == u64(0xffffffffffffffff)
	assert encode(field(value.object(), 'negative')) == '-1'
	assert encode(json2.decode[Value](encode(value)) or { panic(err) }) == encode(value)
}
