// SPDX-License-Identifier: GPL-2.0-only
// IPv4 ICMP raw sockets. All entry points run under inet's network lock.
@[translated]
module netcore

#include <lwip/raw.h>
#include "net_receive_abi.h"

struct C.raw_pcb {}

@[typedef]
struct C.raw_recv_fn {}

@[typedef]
struct C.vinix_receive_address {}

@[typedef]
struct C.vinix_output4_address {}

@[typedef]
struct C.vinix_output6_address {}

type RawReceive = fn (voidptr, &C.raw_pcb, &C.pbuf, C.vinix_receive_address) u8

fn C.raw_new_ip_type(u8, u8) &C.raw_pcb
fn C.raw_remove(&C.raw_pcb)
fn C.raw_recv(&C.raw_pcb, C.raw_recv_fn, voidptr)
fn C.raw_bind(&C.raw_pcb, &C.ip_addr) Err_t
fn C.raw_connect(&C.raw_pcb, &C.ip_addr) Err_t
fn C.raw_disconnect(&C.raw_pcb)
fn C.raw_sendto(&C.raw_pcb, &C.pbuf, &C.ip_addr) Err_t
fn C.pbuf_clone(int, int, &C.pbuf) &C.pbuf
fn C.pbuf_get_at(&C.pbuf, u16) u8

pub const vinix_net_raw = 3

// The shared UDP bridge needs the same exact const-qualified lwIP ABI.
fn udp_received_native(argument voidptr, pcb &C.udp_pcb, p &C.pbuf, source C.vinix_receive_address, port U16_t) {
	unsafe { udp_received(argument, pcb, p, &C.ip_addr(source), u16(port)) }
}

fn install_raw_callback(socket &Vinix_socket) {
	unsafe {
		callback := RawReceive(icmp_received)
		mut native := C.raw_recv_fn{}
		C.memcpy(&native, &callback, sizeof(RawReceive))
		C.raw_recv(socket.raw, native, voidptr(socket))
	}
}

fn icmp_received(argument voidptr, _pcb &C.raw_pcb, p &C.pbuf, source C.vinix_receive_address) u8 {
	unsafe {
		address := &C.ip_addr(source)
		socket := &Vinix_socket(argument)
		if socket == nil || socket.read_shutdown || p == nil { return 0 }
		header := C.ip_data.current_ip_header_tot_len
		if header < 20 || u32(p.tot_len) < u32(header) + 4 { return 0 }
		kind := C.pbuf_get_at(p, header)
		if kind < 32 && socket.icmp_filter & (u32(1) << kind) != 0 { return 0 }
		charge := u32(p.tot_len) + u32(sizeof(Packet)) + 64
		if charge > socket.receive_limit || socket.receive_queued > socket.receive_limit - charge {
			return 0
		}
		// lwIP removes the IP header and may rewrite an echo request after this
		// callback. Keep an independent complete IP packet for each reader.
		copy := C.pbuf_clone(i32(Pbuf_layer.pbuf_raw_tx), i32(Pbuf_type.pbuf_ram), p) @[freed]
		if copy != nil && !queue_packet(socket, copy, address, 0, 0) { C.pbuf_free(copy) }
		// The original stays with lwIP, including its normal ICMP echo handling.
		return 0
	}
}

fn send_icmp(socket &Vinix_socket, data voidptr, length uint, address &C.ip_addr, has_address i32) i32 {
	unsafe {
		if !has_address && !socket.connected { return -89 }
		if length > 65515 || length > socket.send_limit { return -90 }
		destination := if has_address { address } else { &socket_ip_pcb(socket).remote_ip }
		packet := C.pbuf_alloc(i32(Pbuf_layer.pbuf_ip), u16(length), i32(Pbuf_type.pbuf_ram)) @[freed]
		if packet == nil { return -12 }
		if length != 0 && i32(C.pbuf_take(packet, data, u16(length))) != Err_enum_t.err_ok {
			C.pbuf_free(packet)
			return -12
		}
		// Userspace supplies the ICMP header and checksum; lwIP supplies IPv4.
		error_ := C.raw_sendto(socket.raw, packet, destination)
		C.pbuf_free(packet)
		if i32(error_) != Err_enum_t.err_ok { return -linux_error(error_) }
		C.netif_poll_all()
		return i32(length)
	}
}
