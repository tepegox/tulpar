// SPDX-License-Identifier: GPL-2.0-or-later
module sessioncore

#include <string.h>
$if macos { fn C.memset_s(voidptr, uint, int, uint) int }
$else { fn C.explicit_bzero(voidptr, uint) }

// Borrowed secret storage remains owned by run_manager; only its bytes retire
// here. The unlock child has its own fork snapshot before this is called.
fn retire_login_password(secret []u8) {
	if secret.len == 0 { return }
	$if macos { C.memset_s(secret.data, uint(secret.len), 0, uint(secret.len)) }
	$else { C.explicit_bzero(secret.data, uint(secret.len)) }
}
