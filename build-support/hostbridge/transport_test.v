// SPDX-License-Identifier: GPL-2.0-or-later
module hostbridge

import hostvalue as ah
import json2

fn test_shared_transport_preserves_values_and_errors() {
	value := json2.decode[ah.Value]('[18446744073709551615,"text",true]') or { panic(err) }
	decoded := unpack(pack(value)) or { panic(err) }
	assert ah.encode(decoded) == ah.encode(value)
	failed := failure(error('ValueError: invalid path'))
	assert failed['kind']!.text() == 'ValueError'
	assert failed['error']!.text() == 'invalid path'
}
