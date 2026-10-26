@[has_globals]
module console

import sched
import aarch64.uart
import aarch64.virtio_input
import aarch64.virtio_net
import dev.e1000
import socket.inet
import flanterm as _

// Poll UART and VirtIO input into the console.
// Called from the scheduler's await() loop to avoid needing a separate thread.
pub fn poll_uart_input() {
	// Networking shares the scheduler's idle poll path with input devices, so
	// blocking socket operations keep hardware, DHCP and TCP timers moving.
	virtio_net.poll()
	e1000.poll()
	inet.poll()
	c := uart.getc()
	if c >= 0 {
		mut byte_val := u8(c)
		if byte_val == 0x7f {
			byte_val = `\b`
		}
		add_to_buf(&byte_val, 1, true)
	}
	// Poll virtio keyboard
	virtio_input.poll()
	if vi_outlen > 0 {
		add_to_buf(&vi_outbuf[0], vi_outlen, true)
		vi_outlen = 0
	}

}

pub fn initialise() {
	C.flanterm_set_callback(flanterm_ctx, voidptr(flanterm_callback))

	setup_console()

	sched.set_uart_poll_callback(voidptr(poll_uart_input))
}

fn caps_lock_on() bool {
	return vi_caps_active
}

fn num_lock_on() bool { return vi_num_active }

// What the console shows goes to the UART as well.
fn mirror_to_serial(buf voidptr, count u64) {
	uart.write(charptr(buf), count)
}
