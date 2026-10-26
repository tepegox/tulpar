@[has_globals]
module kprint

import klock
import katomic

@[markused]
__global (
	printf_lock klock.Lock
	kprint_lock klock.Lock
	interactive_console u64
)

// Boot diagnostics stay visible until userspace claims the console. Normal
// kernel output then goes to bootlog; panic output uses its own direct path.
pub fn claim_console() {
	kprint_lock.acquire()
	katomic.store(mut &interactive_console, 1)
	kprint_lock.release()
}

fn console_claimed() bool { return katomic.load(&interactive_console) != 0 }

// Terminal echo and application output are not kernel diagnostics. Keep them
// visible after handoff, without putting passwords or editor contents in logs.
pub fn console_write(message &char, length u64) {
	kprint_lock.acquire()
	unsafe {
		for i := u64(0); i < length; i++ { policy_serial(u8(message[i]), false) }
	}
	policy_terminal(message, length)
	kprint_lock.release()
}

fn C.byteptr_vstring(byteptr) string
fn C.byteptr_vstring_with_len(byteptr, int) string
fn C.char_vstring(charptr) string
