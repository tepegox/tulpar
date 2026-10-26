module kprint

import dev.serial
import term

pub fn kwrite(message charptr, msglen u64) {
	kprint_lock.acquire()
	bootlog.append(message, msglen)
	if console_claimed() { kprint_lock.release(); return }

	// The serial terminal is the normal console on headless servers, including
	// production builds. Keep driver diagnostics visible there as on ARM64.
	unsafe {
		for i := 0; i < msglen; i++ {
			serial.out(u8(message[i]))
		}
	}

	term.print(message, msglen)

	kprint_lock.release()
}
